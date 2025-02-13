import CryptoKit
@preconcurrency import Foundation
import Security

/// Service for encrypting and decrypting data
@objc
public class EncryptionService: NSObject {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with dependencies
    @objc
    public init(
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        self.performanceMonitor = performanceMonitor
        self.logger = logger
        super.init()
    }

    // MARK: Public

    // MARK: - Types

    /// Encryption options
    public struct Options {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            keySize: Int = 256,
            useSecureEnclave: Bool = true,
            salt: Data? = nil,
            initializationVector: Data? = nil
        ) {
            self.keySize = keySize
            self.useSecureEnclave = useSecureEnclave
            self.salt = salt
            self.initializationVector = initializationVector
        }

        // MARK: Public

        /// Key size in bits
        public let keySize: Int
        /// Use Secure Enclave if available
        public let useSecureEnclave: Bool
        /// Salt for key derivation
        public let salt: Data?
        /// Initialization vector for encryption
        public let initializationVector: Data?
    }

    /// Encryption result
    public struct EncryptionResult {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            data: Data,
            initializationVector: Data,
            salt: Data
        ) {
            self.data = data
            self.initializationVector = initializationVector
            self.salt = salt
        }

        // MARK: Public

        /// Encrypted data
        public let data: Data
        /// Initialization vector used for encryption
        public let initializationVector: Data
        /// Salt used for key derivation
        public let salt: Data
    }

    // MARK: - Public Methods

    /// Encrypt data with key
    @objc
    public func encrypt(
        _ data: Data,
        withKey key: Data,
        options: Options = Options()
    ) throws -> EncryptionResult {
        try performanceMonitor.trackDuration(
            "encryption.encrypt"
        ) {
            // Generate salt and IV if not provided
            let salt = options.salt ?? generateRandomBytes(32)
            let initializationVector = options.initializationVector ?? generateRandomBytes(16)

            // Derive key using PBKDF2
            let derivedKey = try deriveKey(
                fromKey: key,
                salt: salt,
                keySize: options.keySize
            )

            // Create symmetric key
            let symmetricKey = try createSymmetricKey(
                fromData: derivedKey,
                useSecureEnclave: options.useSecureEnclave
            )

            // Encrypt data
            let encryptedData = try AES.GCM.seal(
                data,
                using: symmetricKey,
                nonce: AES.GCM.Nonce(data: initializationVector)
            ).combined ?? Data()

            self.logEncryption(dataSize: data.count)

            return EncryptionResult(
                data: encryptedData,
                initializationVector: initializationVector,
                salt: salt
            )
        }
    }

    /// Decrypt data with key
    @objc
    public func decrypt(
        _ encryptedData: Data,
        withKey key: Data,
        initializationVector _: Data,
        salt: Data,
        options: Options = Options()
    ) throws -> Data {
        try performanceMonitor.trackDuration(
            "encryption.decrypt"
        ) {
            // Derive key using PBKDF2
            let derivedKey = try deriveKey(
                fromKey: key,
                salt: salt,
                keySize: options.keySize
            )

            // Create symmetric key
            let symmetricKey = try createSymmetricKey(
                fromData: derivedKey,
                useSecureEnclave: options.useSecureEnclave
            )

            // Create sealed box
            let sealedBox = try AES.GCM.SealedBox(
                combined: encryptedData
            )

            // Decrypt data
            let decryptedData = try AES.GCM.open(
                sealedBox,
                using: symmetricKey,
                authenticating: Data()
            )

            self.logDecryption(dataSize: decryptedData.count)

            return decryptedData
        }
    }

    // MARK: Private

    /// Logger for tracking operations
    private let logger: LoggerProtocol

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbra.encryption-service",
        qos: .userInitiated
    )

    // MARK: - Private Methods

    /// Generate random bytes
    private func generateRandomBytes(
        _ count: Int
    ) -> Data {
        var bytes = [UInt8](
            repeating: 0,
            count: count
        )

        _ = SecRandomCopyBytes(
            kSecRandomDefault,
            count,
            &bytes
        )

        return Data(bytes)
    }

    /// Derive key using PBKDF2
    private func deriveKey(
        fromKey key: Data,
        salt: Data,
        keySize: Int
    ) throws -> Data {
        var derivedKeyData = Data(
            count: keySize / 8
        )

        let derivationStatus = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            key.withUnsafeBytes { keyBytes in
                salt.withUnsafeBytes { saltBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        keyBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        key.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256),
                        10000,
                        derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        keySize / 8
                    )
                }
            }
        }

        guard derivationStatus == kCCSuccess else {
            throw EncryptionError.keyDerivationFailed
        }

        return derivedKeyData
    }

    /// Create symmetric key
    private func createSymmetricKey(
        fromData data: Data,
        useSecureEnclave: Bool
    ) throws -> SymmetricKey {
        if useSecureEnclave,
           let key = try? createSecureEnclaveKey(fromData: data)
        {
            return key
        }

        return SymmetricKey(data: data)
    }

    /// Create Secure Enclave key
    private func createSecureEnclaveKey(
        fromData data: Data
    ) throws -> SymmetricKey {
        let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.privateKeyUsage],
            nil
        )

        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateRandomKey(
            [
                kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                kSecAttrKeySizeInBits: 256,
                kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
                kSecPrivateKeyAttrs: [
                    kSecAttrIsPermanent: true,
                    kSecAttrAccessControl: access as Any
                ]
            ] as CFDictionary,
            &error
        ) else {
            throw EncryptionError.secureEnclaveKeyCreationFailed
        }

        return SymmetricKey(data: data)
    }

    /// Log encryption operation
    private func logEncryption(
        dataSize: Int
    ) {
        logger.debug(
            "Encrypted data",
            config: LogConfig(
                metadata: [
                    "size": String(dataSize)
                ]
            )
        )
    }

    /// Log decryption operation
    private func logDecryption(
        dataSize: Int
    ) {
        logger.debug(
            "Decrypted data",
            config: LogConfig(
                metadata: [
                    "size": String(dataSize)
                ]
            )
        )
    }
}
