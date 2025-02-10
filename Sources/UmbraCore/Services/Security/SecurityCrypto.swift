import CryptoKit
import Foundation

/// Service for cryptographic operations
public final class SecurityCrypto: BaseSandboxedService {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - performanceMonitor: Performance monitor
    ///   - logger: Logger for tracking operations
    public init(
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        self.performanceMonitor = performanceMonitor
        super.init(logger: logger)
    }

    // MARK: Public

    // MARK: - Types

    /// Encryption key
    public struct EncryptionKey {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            data: SymmetricKey,
            identifier: String,
            creationDate: Date = Date()
        ) {
            self.data = data
            self.identifier = identifier
            self.creationDate = creationDate
        }

        // MARK: Public

        /// Key data
        public let data: SymmetricKey

        /// Key identifier
        public let identifier: String

        /// Creation date
        public let creationDate: Date
    }

    /// Encrypted data
    public struct EncryptedData {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            ciphertext: Data,
            nonce: AES.GCM.Nonce,
            tag: Data,
            keyIdentifier: String
        ) {
            self.ciphertext = ciphertext
            self.nonce = nonce
            self.tag = tag
            self.keyIdentifier = keyIdentifier
        }

        // MARK: Public

        /// Ciphertext
        public let ciphertext: Data

        /// Nonce
        public let nonce: AES.GCM.Nonce

        /// Authentication tag
        public let tag: Data

        /// Key identifier
        public let keyIdentifier: String
    }

    // MARK: - Public Methods

    /// Generate encryption key
    /// - Parameter identifier: Key identifier
    /// - Returns: Encryption key
    public func generateKey(
        identifier: String
    ) -> EncryptionKey {
        // Generate key
        let key = SymmetricKey(size: .bits256)

        // Create encryption key
        let encryptionKey = EncryptionKey(
            data: key,
            identifier: identifier
        )

        // Store key
        queue.async(flags: .barrier) {
            self.activeKeys[identifier] = encryptionKey
        }

        // Log operation
        logger.debug(
            """
            Generated encryption key:
            Identifier: \(identifier)
            """,
            file: #file,
            function: #function,
            line: #line
        )

        return encryptionKey
    }

    /// Encrypt data
    /// - Parameters:
    ///   - data: Data to encrypt
    ///   - key: Encryption key
    /// - Returns: Encrypted data
    /// - Throws: Error if encryption fails
    public func encrypt(
        _ data: Data,
        using key: EncryptionKey
    ) async throws -> EncryptedData {
        try validateUsable(for: "encrypt")

        return try await performanceMonitor.trackDuration("crypto.encrypt") {
            // Generate nonce
            let nonce = try AES.GCM.Nonce()

            // Create sealed box
            let sealedBox = try AES.GCM.seal(
                data,
                using: key.data,
                nonce: nonce
            )

            // Create encrypted data
            let encryptedData = EncryptedData(
                ciphertext: sealedBox.ciphertext,
                nonce: sealedBox.nonce,
                tag: sealedBox.tag,
                keyIdentifier: key.identifier
            )

            // Log operation
            logger.debug(
                """
                Encrypted data:
                Size: \(data.count) bytes
                Key: \(key.identifier)
                """,
                file: #file,
                function: #function,
                line: #line
            )

            return encryptedData
        }
    }

    /// Decrypt data
    /// - Parameters:
    ///   - encryptedData: Data to decrypt
    ///   - key: Encryption key
    /// - Returns: Decrypted data
    /// - Throws: Error if decryption fails
    public func decrypt(
        _ encryptedData: EncryptedData,
        using key: EncryptionKey
    ) async throws -> Data {
        try validateUsable(for: "decrypt")

        return try await performanceMonitor.trackDuration("crypto.decrypt") {
            // Create sealed box
            let sealedBox = try AES.GCM.SealedBox(
                nonce: encryptedData.nonce,
                ciphertext: encryptedData.ciphertext,
                tag: encryptedData.tag
            )

            // Decrypt data
            let decryptedData = try AES.GCM.open(
                sealedBox,
                using: key.data
            )

            // Log operation
            logger.debug(
                """
                Decrypted data:
                Size: \(decryptedData.count) bytes
                Key: \(key.identifier)
                """,
                file: #file,
                function: #function,
                line: #line
            )

            return decryptedData
        }
    }

    /// Get active key
    /// - Parameter identifier: Key identifier
    /// - Returns: Encryption key if found
    public func getKey(
        identifier: String
    ) -> EncryptionKey? {
        queue.sync { activeKeys[identifier] }
    }

    /// Remove key
    /// - Parameter identifier: Key identifier
    public func removeKey(
        identifier: String
    ) {
        queue.async(flags: .barrier) {
            self.activeKeys.removeValue(forKey: identifier)
        }

        // Log operation
        logger.debug(
            """
            Removed encryption key:
            Identifier: \(identifier)
            """,
            file: #file,
            function: #function,
            line: #line
        )
    }

    /// Remove all keys
    public func removeAllKeys() {
        queue.async(flags: .barrier) {
            self.activeKeys.removeAll()
        }

        // Log operation
        logger.debug(
            "Removed all encryption keys",
            file: #file,
            function: #function,
            line: #line
        )
    }

    // MARK: Private

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.security.crypto",
        qos: .userInitiated,
        attributes: .concurrent
    )

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    /// Active encryption keys
    private var activeKeys: [String: EncryptionKey] = [:]
}
