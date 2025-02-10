import Foundation

/// Errors that can occur during permission operations
public enum PermissionError: LocalizedError {
    /// Permission denied
    case permissionDenied(String)
    /// Permission expired
    case permissionExpired(String)
    /// Permission not found
    case permissionNotFound(String)
    /// Invalid permission
    case invalidPermission(String)
    /// Unsupported permission
    case unsupportedPermission(String)
    /// Permission request failed
    case requestFailed(String)
    /// Permission validation failed
    case validationFailed(String)
    /// Unimplemented permission
    case unimplemented(String)
    /// Operation failed
    case operationFailed(String)

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case let .permissionDenied(permission):
            "Permission denied: \(permission)"
        case let .permissionExpired(permission):
            "Permission expired: \(permission)"
        case let .permissionNotFound(permission):
            "Permission not found: \(permission)"
        case let .invalidPermission(reason):
            "Invalid permission: \(reason)"
        case let .unsupportedPermission(permission):
            "Unsupported permission: \(permission)"
        case let .requestFailed(reason):
            "Permission request failed: \(reason)"
        case let .validationFailed(reason):
            "Permission validation failed: \(reason)"
        case let .unimplemented(permission):
            "Permission not implemented: \(permission)"
        case let .operationFailed(reason):
            "Permission operation failed: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            "Request permission from user"
        case .permissionExpired:
            "Request permission again"
        case .permissionNotFound:
            "Request permission first"
        case .invalidPermission:
            "Check permission configuration"
        case .unsupportedPermission:
            "Use a supported permission type"
        case .requestFailed:
            "Try requesting permission again"
        case .validationFailed:
            "Check permission validity"
        case .unimplemented:
            "Use an implemented permission type"
        case .operationFailed:
            "Try the operation again"
        }
    }

    public var helpAnchor: String? {
        switch self {
        case .permissionDenied:
            "permission_request"
        case .permissionExpired:
            "permission_expiry"
        case .permissionNotFound:
            "permission_lookup"
        case .invalidPermission:
            "permission_configuration"
        case .unsupportedPermission:
            "permission_types"
        case .requestFailed:
            "permission_request_process"
        case .validationFailed:
            "permission_validation"
        case .unimplemented:
            "permission_implementation"
        case .operationFailed:
            "permission_troubleshooting"
        }
    }
}
