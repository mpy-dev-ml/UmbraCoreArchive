import Foundation

/// Errors that can occur during persistence operations
public enum PersistenceError: LocalizedError {
    /// Directory not found
    case directoryNotFound
    /// File not found
    case fileNotFound(String)
    /// Save failed
    case saveFailed(String)
    /// Load failed
    case loadFailed(String)
    /// Remove failed
    case removeFailed(String)
    /// Compression failed
    case compressionFailed(String)
    /// Decompression failed
    case decompressionFailed(String)
    /// Encryption failed
    case encryptionFailed(String)
    /// Decryption failed
    case decryptionFailed(String)
    /// Invalid key
    case invalidKey(String)
    /// Invalid data
    case invalidData(String)

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case .directoryNotFound:
            "Storage directory not found"

        case let .fileNotFound(key):
            "File not found for key: \(key)"

        case let .saveFailed(reason):
            "Failed to save data: \(reason)"

        case let .loadFailed(reason):
            "Failed to load data: \(reason)"

        case let .removeFailed(reason):
            "Failed to remove data: \(reason)"

        case let .compressionFailed(reason):
            "Failed to compress data: \(reason)"

        case let .decompressionFailed(reason):
            "Failed to decompress data: \(reason)"

        case let .encryptionFailed(reason):
            "Failed to encrypt data: \(reason)"

        case let .decryptionFailed(reason):
            "Failed to decrypt data: \(reason)"

        case let .invalidKey(reason):
            "Invalid storage key: \(reason)"

        case let .invalidData(reason):
            "Invalid data: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .directoryNotFound:
            "Try reinitialising the persistence service"

        case .fileNotFound:
            "Check if the data was previously saved"

        case .saveFailed:
            "Check disk space and permissions"

        case .loadFailed:
            "Check if the file exists and is accessible"

        case .removeFailed:
            "Check file permissions"
        case .compressionFailed,
             .decompressionFailed:
            "Check data format and try again"
        case .encryptionFailed,
             .decryptionFailed:
            "Check encryption key and try again"

        case .invalidKey:
            "Use a valid storage key"

        case .invalidData:
            "Check data format and try again"
        }
    }
}
