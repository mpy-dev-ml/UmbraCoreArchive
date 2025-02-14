/// Errors that can occur during encryption operations
public enum EncryptionError: LocalizedError {
    /// Invalid encryption key
    case invalidKey(String)
    /// Operation failed
    case operationFailed(String)
    /// Invalid data format
    case invalidDataFormat(String)
    /// Encryption failed
    case encryptionFailed(String)
    /// Decryption failed
    case decryptionFailed(String)
    /// Key generation failed
    case keyGenerationFailed(String)
    /// Key storage failed
    case keyStorageFailed(String)

    /// Localized description of the error
    public var errorDescription: String? {
        switch self {
        case .invalidKey(let reason):
            return "Invalid encryption key: \(reason)"
        case .operationFailed(let reason):
            return "Encryption operation failed: \(reason)"
        case .invalidDataFormat(let reason):
            return "Invalid data format: \(reason)"
        case .encryptionFailed(let reason):
            return "Encryption failed: \(reason)"
        case .decryptionFailed(let reason):
            return "Decryption failed: \(reason)"
        case .keyGenerationFailed(let reason):
            return "Key generation failed: \(reason)"
        case .keyStorageFailed(let reason):
            return "Key storage failed: \(reason)"
        }
    }

    /// Failure reason for the error
    public var failureReason: String? {
        switch self {
        case .invalidKey(let reason),
             .operationFailed(let reason),
             .invalidDataFormat(let reason),
             .encryptionFailed(let reason),
             .decryptionFailed(let reason),
             .keyGenerationFailed(let reason),
             .keyStorageFailed(let reason):
            return reason
        }
    }

    /// Recovery suggestion for the error
    public var recoverySuggestion: String? {
        switch self {
        case .invalidKey:
            return "Verify that the encryption key is valid and properly initialized"
        case .operationFailed:
            return "Check the operation parameters and try again"
        case .invalidDataFormat:
            return "Ensure the data is in the correct format for the operation"
        case .encryptionFailed:
            return "Verify the encryption parameters and try again"
        case .decryptionFailed:
            return "Verify the decryption key and try again"
        case .keyGenerationFailed:
            return "Check the key generation parameters and try again"
        case .keyStorageFailed:
            return "Verify the storage location is accessible and try again"
        }
    }
}
