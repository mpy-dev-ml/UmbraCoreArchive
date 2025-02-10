import Foundation

/// Errors that can occur during security-scoped bookmark operations
public enum BookmarkError: LocalizedError {
    /// Bookmark not found
    case notFound(String)
    /// Access denied to resource
    case accessDenied(String)
    /// Bookmark is stale
    case staleBookmark(String)
    /// Active access prevents operation
    case activeAccess(String)
    /// Invalid bookmark data
    case invalidData(String)
    /// Storage error
    case storageError(String)
    /// Permission error
    case permissionError(String)
    /// Resource not available
    case resourceUnavailable(String)

    // MARK: Public

    /// Localized description of the error
    public var errorDescription: String? {
        switch self {
        case let .notFound(id):
            "Bookmark not found: \(id)"
        case let .accessDenied(path):
            "Access denied to resource: \(path)"
        case let .staleBookmark(id):
            "Bookmark is stale and needs to be recreated: \(id)"
        case let .activeAccess(id):
            "Cannot perform operation while bookmark is being accessed: \(id)"
        case let .invalidData(reason):
            "Invalid bookmark data: \(reason)"
        case let .storageError(reason):
            "Failed to store bookmark: \(reason)"
        case let .permissionError(reason):
            "Permission error: \(reason)"
        case let .resourceUnavailable(path):
            "Resource not available: \(path)"
        }
    }

    /// Failure reason for the error
    public var failureReason: String? {
        switch self {
        case .notFound:
            "The specified bookmark could not be found in storage"
        case .accessDenied:
            "The system denied access to the security-scoped resource"
        case .staleBookmark:
            "The bookmark data is no longer valid and needs to be recreated"
        case .activeAccess:
            "The bookmark is currently being accessed and cannot be modified"
        case .invalidData:
            "The bookmark data is corrupted or invalid"
        case .storageError:
            "Failed to store or retrieve bookmark data"
        case .permissionError:
            "Insufficient permissions to access the resource"
        case .resourceUnavailable:
            "The resource is not available or does not exist"
        }
    }

    /// Recovery suggestion for the error
    public var recoverySuggestion: String? {
        switch self {
        case .notFound:
            "Create a new bookmark for the resource"
        case .accessDenied:
            "Request user permission to access the resource"
        case .staleBookmark:
            "Create a new bookmark and update any stored references"
        case .activeAccess:
            "Stop accessing the bookmark before performing this operation"
        case .invalidData:
            "Create a new bookmark with valid data"
        case .storageError:
            "Check storage permissions and available space"
        case .permissionError:
            "Request necessary permissions from the user"
        case .resourceUnavailable:
            "Verify the resource exists and is accessible"
        }
    }

    /// Help anchor for documentation
    public var helpAnchor: String {
        switch self {
        case .notFound:
            "bookmark-not-found"
        case .accessDenied:
            "bookmark-access-denied"
        case .staleBookmark:
            "bookmark-stale"
        case .activeAccess:
            "bookmark-active-access"
        case .invalidData:
            "bookmark-invalid-data"
        case .storageError:
            "bookmark-storage-error"
        case .permissionError:
            "bookmark-permission-error"
        case .resourceUnavailable:
            "bookmark-resource-unavailable"
        }
    }
}
