import CryptoKit
import Foundation

/// Wrapper for encryption keys
public struct EncryptionKey {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with symmetric key
    /// - Parameters:
    ///   - symmetricKey: Symmetric key
    ///   - identifier: Key identifier
    ///   - storage: Key storage
    public init(
        symmetricKey: SymmetricKey,
        identifier: String,
        storage: Storage = .memory
    ) {
        self.symmetricKey = symmetricKey
        self.identifier = identifier
        type = .symmetric
        self.storage = storage
        privateKeyData = nil
        publicKeyData = nil
    }

    /// Initialize with key pair
    /// - Parameters:
    ///   - privateKey: Private key data
    ///   - publicKey: Public key data
    ///   - identifier: Key identifier
    ///   - storage: Key storage
    public init(
        privateKey: Data,
        publicKey: Data,
        identifier: String,
        storage: Storage = .memory
    ) {
        privateKeyData = privateKey
        publicKeyData = publicKey
        self.identifier = identifier
        type = .asymmetric
        self.storage = storage
        symmetricKey = nil
    }

    // MARK: Public

    // MARK: - Types

    /// Key type
    public enum KeyType {
        /// Symmetric key
        case symmetric
        /// Asymmetric key
        case asymmetric
        /// Custom key
        case custom(String)
    }

    /// Key storage
    public enum Storage {
        /// Memory storage
        case memory
        /// Keychain storage
        case keychain
        /// Secure Enclave storage
        case secureEnclave
        /// Custom storage
        case custom(String)
    }

    /// Key identifier
    public let identifier: String

    /// Key type
    public let type: KeyType

    /// Key storage
    public let storage: Storage

    // MARK: - Public Methods

    /// Get symmetric key
    /// - Returns: Symmetric key if available
    /// - Throws: Error if key not available
    public func getSymmetricKey() throws -> SymmetricKey {
        guard let key = symmetricKey else {
            throw EncryptionError.invalidKey("Symmetric key not available")
        }

        return key
    }

    /// Get private key data
    /// - Returns: Private key data if available
    /// - Throws: Error if key not available
    public func getPrivateKeyData() throws -> Data {
        guard let data = privateKeyData else {
            throw EncryptionError.invalidKey("Private key not available")
        }

        return data
    }

    /// Get public key data
    /// - Returns: Public key data if available
    /// - Throws: Error if key not available
    public func getPublicKeyData() throws -> Data {
        guard let data = publicKeyData else {
            throw EncryptionError.invalidKey("Public key not available")
        }

        return data
    }

    /// Save key to storage
    /// - Throws: Error if save fails
    public func saveToStorage() throws {
        switch storage {
        case .memory:
            // Already in memory
            break
        case .keychain:
            try saveToKeychain()
        case .secureEnclave:
            try saveToSecureEnclave()
        case let .custom(storageType):
            throw EncryptionError.operationFailed("Unsupported storage: \(storageType)")
        }
    }

    /// Delete key from storage
    /// - Throws: Error if delete fails
    public func deleteFromStorage() throws {
        switch storage {
        case .memory:
            // Nothing to delete
            break
        case .keychain:
            try deleteFromKeychain()
        case .secureEnclave:
            try deleteFromSecureEnclave()
        case let .custom(storageType):
            throw EncryptionError.operationFailed("Unsupported storage: \(storageType)")
        }
    }

    // MARK: Private

    /// Symmetric key
    private let symmetricKey: SymmetricKey?

    /// Private key data
    private let privateKeyData: Data?

    /// Public key data
    private let publicKeyData: Data?

    // MARK: - Private Methods

    /// Save key to keychain
    private func saveToKeychain() throws {
        let query: [String: Any] = try [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: identifier.data(using: .utf8)!,
            kSecValueData as String: getKeyData(),
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw EncryptionError.operationFailed("Failed to save to keychain")
        }
    }

    /// Delete key from keychain
    private func deleteFromKeychain() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: identifier.data(using: .utf8)!,
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else {
            throw EncryptionError.operationFailed("Failed to delete from keychain")
        }
    }

    /// Save key to Secure Enclave
    private func saveToSecureEnclave() throws {
        // Note: This is a placeholder. In a real implementation,
        // you would use proper Secure Enclave APIs.
        throw EncryptionError.operationFailed("Secure Enclave not implemented")
    }

    /// Delete key from Secure Enclave
    private func deleteFromSecureEnclave() throws {
        // Note: This is a placeholder. In a real implementation,
        // you would use proper Secure Enclave APIs.
        throw EncryptionError.operationFailed("Secure Enclave not implemented")
    }

    /// Get key data based on type
    private func getKeyData() throws -> Data {
        switch type {
        case .symmetric:
            return try getSymmetricKey().withUnsafeBytes { Data($0) }
        case .asymmetric:
            return try getPrivateKeyData()
        case let .custom(keyType):
            throw EncryptionError.operationFailed("Unsupported key type: \(keyType)")
        }
    }
}
