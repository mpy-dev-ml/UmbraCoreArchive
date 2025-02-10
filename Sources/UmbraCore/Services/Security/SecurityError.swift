import Foundation

/// Security-related errors
public enum SecurityError: LocalizedError {
    /// Bookmark creation failed
    case bookmarkCreationFailed(String)
    /// Bookmark resolution failed
    case bookmarkResolutionFailed(String)
    /// Bookmark is stale
    case bookmarkStale
    /// Permission denied
    case permissionDenied(String)
    /// Access validation failed
    case accessValidationFailed(String)
    /// Operation not permitted
    case operationNotPermitted(String)
    /// Keychain error
    case keychainError(String)
    /// Encryption error
    case encryptionError(String)
    /// Decryption error
    case decryptionError(String)
    /// Key management error
    case keyManagementError(String)

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case let .bookmarkCreationFailed(reason):
            "Failed to create bookmark: \(reason)"
        case let .bookmarkResolutionFailed(reason):
            "Failed to resolve bookmark: \(reason)"
        case .bookmarkStale:
            "Bookmark is stale and needs to be recreated"
        case let .permissionDenied(reason):
            "Permission denied: \(reason)"
        case let .accessValidationFailed(reason):
            "Access validation failed: \(reason)"
        case let .operationNotPermitted(reason):
            "Operation not permitted: \(reason)"
        case let .keychainError(reason):
            "Keychain error: \(reason)"
        case let .encryptionError(reason):
            "Encryption error: \(reason)"
        case let .decryptionError(reason):
            "Decryption error: \(reason)"
        case let .keyManagementError(reason):
            "Key management error: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .bookmarkStale:
            "Request permission again to create a new bookmark"
        case .permissionDenied:
            "Try requesting permission again or select a different file"
        case .keychainError:
            "Check keychain access and permissions"
        case .encryptionError,
             .decryptionError:
            "Verify encryption key and try again"
        case .keyManagementError:
            "Check key validity and permissions"
        default:
            nil
        }
    }
}
