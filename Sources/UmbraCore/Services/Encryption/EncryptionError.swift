import Foundation

/// Errors that can occur during encryption operations
public enum EncryptionError: LocalizedError {
    /// Key derivation failed
    case keyDerivationFailed
    /// Secure Enclave key creation failed
    case secureEnclaveKeyCreationFailed
    /// Invalid key size
    case invalidKeySize(Int)
    /// Invalid input data
    case invalidInputData(String)
    /// Encryption failed
    case encryptionFailed(String)
    /// Decryption failed
    case decryptionFailed(String)
    /// Invalid algorithm parameters
    case invalidParameters(String)
    /// Operation not supported
    case operationNotSupported(String)

    // MARK: Public

    /// Localized description of the error
    public var errorDescription: String? {
        switch self {
        case .keyDerivationFailed:
            "Failed to derive encryption key"
        case .secureEnclaveKeyCreationFailed:
            "Failed to create Secure Enclave key"
        case let .invalidKeySize(size):
            "Invalid key size: \(size) bits"
        case let .invalidInputData(reason):
            "Invalid input data: \(reason)"
        case let .encryptionFailed(reason):
            "Encryption failed: \(reason)"
        case let .decryptionFailed(reason):
            "Decryption failed: \(reason)"
        case let .invalidParameters(reason):
            "Invalid parameters: \(reason)"
        case let .operationNotSupported(reason):
            "Operation not supported: \(reason)"
        }
    }

    /// Failure reason for the error
    public var failureReason: String? {
        switch self {
        case .keyDerivationFailed:
            "The key derivation process failed to complete successfully"
        case .secureEnclaveKeyCreationFailed:
            "Failed to create a key in the Secure Enclave"
        case .invalidKeySize:
            "The specified key size is not supported"
        case .invalidInputData:
            "The provided input data is invalid or corrupted"
        case .encryptionFailed:
            "The encryption operation failed to complete"
        case .decryptionFailed:
            "The decryption operation failed to complete"
        case .invalidParameters:
            "The provided parameters are invalid or incompatible"
        case .operationNotSupported:
            "The requested operation is not supported"
        }
    }

    /// Recovery suggestion for the error
    public var recoverySuggestion: String? {
        switch self {
        case .keyDerivationFailed:
            "Try using a different key or key derivation parameters"
        case .secureEnclaveKeyCreationFailed:
            "Check if the Secure Enclave is available and try again"
        case .invalidKeySize:
            "Use a supported key size (e.g., 128, 256 bits)"
        case .invalidInputData:
            "Verify the input data is valid and try again"
        case .encryptionFailed:
            "Check the encryption parameters and try again"
        case .decryptionFailed:
            "Verify the key and encrypted data are correct"
        case .invalidParameters:
            "Check the documentation for supported parameters"
        case .operationNotSupported:
            "Use a supported operation or algorithm"
        }
    }

    /// Help anchor for documentation
    public var helpAnchor: String {
        switch self {
        case .keyDerivationFailed:
            "encryption-key-derivation-failed"
        case .secureEnclaveKeyCreationFailed:
            "encryption-secure-enclave-failed"
        case .invalidKeySize:
            "encryption-invalid-key-size"
        case .invalidInputData:
            "encryption-invalid-input"
        case .encryptionFailed:
            "encryption-failed"
        case .decryptionFailed:
            "encryption-decryption-failed"
        case .invalidParameters:
            "encryption-invalid-parameters"
        case .operationNotSupported:
            "encryption-operation-not-supported"
        }
    }
}
