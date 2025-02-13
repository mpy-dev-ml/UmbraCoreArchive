@preconcurrency import Foundation

/// Errors that can occur during resource operations
public enum ResourceError: LocalizedError {
    /// Resource not found
    case resourceNotFound(String)
    /// Invalid resource type
    case invalidResourceType(String)
    /// Invalid resource data
    case invalidResourceData(String)
    /// Store failed
    case storeFailed(String)
    /// Load failed
    case loadFailed(String)
    /// Remove failed
    case removeFailed(String)
    /// Invalid identifier
    case invalidIdentifier(String)
    /// Invalid metadata
    case invalidMetadata(String)
    /// Cache error
    case cacheError(String)

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case let .resourceNotFound(identifier):
            "Resource not found: \(identifier)"
        case let .invalidResourceType(type):
            "Invalid resource type: \(type)"
        case let .invalidResourceData(reason):
            "Invalid resource data: \(reason)"
        case let .storeFailed(reason):
            "Failed to store resource: \(reason)"
        case let .loadFailed(reason):
            "Failed to load resource: \(reason)"
        case let .removeFailed(reason):
            "Failed to remove resource: \(reason)"
        case let .invalidIdentifier(reason):
            "Invalid resource identifier: \(reason)"
        case let .invalidMetadata(reason):
            "Invalid resource metadata: \(reason)"
        case let .cacheError(reason):
            "Resource cache error: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .resourceNotFound:
            "Check if the resource exists"
        case .invalidResourceType:
            "Use a valid resource type"
        case .invalidResourceData:
            "Check resource data format"
        case .storeFailed:
            "Check disk space and permissions"
        case .loadFailed:
            "Check if resource exists and is accessible"
        case .removeFailed:
            "Check resource permissions"
        case .invalidIdentifier:
            "Use a valid resource identifier"
        case .invalidMetadata:
            "Check resource metadata format"
        case .cacheError:
            "Try reloading the resource cache"
        }
    }
}
