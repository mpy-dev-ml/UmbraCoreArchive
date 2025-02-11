import Foundation

/// An enumeration of errors that can occur during security-related operations.
///
/// `SecurityError` provides detailed error information for various security
/// operations, including:
/// - Permission management
/// - Bookmark operations
/// - Sandbox compliance
/// - Resource access
/// - XPC communication
///
/// Each error case includes a descriptive message to help with:
/// - Debugging issues
/// - User feedback
/// - Error logging
/// - Recovery handling
///
/// The enum conforms to:
/// - `LocalizedError` for user-friendly error messages
/// - `Equatable` for error comparison and testing
/// - `Sendable` for concurrent operations
///
/// Example usage:
/// ```swift
/// // Handling security errors with switch
/// do {
///     try await securityService.requestPermission(for: fileURL)
/// } catch let error as SecurityError {
///     switch error {
///     case .permissionDenied(let message):
///         logger.error("Permission denied: \(message)")
///         showPermissionAlert()
///
///     case .sandboxViolation(let message):
///         logger.error("Sandbox violation: \(message)")
///         handleSandboxViolation()
///
///     case .bookmarkStale:
///         logger.error("Stale bookmark")
///         refreshBookmark()
///
///     default:
///         logger.error("Security error: \(error.localizedDescription)")
///         showErrorAlert(error)
///     }
/// }
/// ```
@frozen
public enum SecurityError: LocalizedError, Equatable, Sendable {
    /// Permission was denied by the system's security mechanism
    case permissionDenied(String)

    /// Bookmark creation failed
    case bookmarkCreationFailed(String)

    /// Bookmark resolution failed
    case bookmarkResolutionFailed(String)

    /// Bookmark is stale and needs to be recreated
    case bookmarkStale

    /// Sandbox violation occurred
    case sandboxViolation(String)

    /// Access was denied
    case accessDenied(String)

    /// Resource is unavailable
    case resourceUnavailable(String)

    /// Operation is not permitted
    case operationNotPermitted(String)

    /// Access validation failed
    case accessValidationFailed(String)

    /// XPC connection failed
    case xpcConnectionFailed(String)

    /// XPC service error occurred
    case xpcServiceError(String)

    /// XPC permission was denied
    case xpcPermissionDenied(String)

    /// XPC validation failed
    case xpcValidationFailed(String)

    /// Keychain operation failed
    case keychainError(String)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case let .permissionDenied(message):
            "Permission denied: \(message)"
        case let .bookmarkCreationFailed(message):
            "Failed to create bookmark: \(message)"
        case let .bookmarkResolutionFailed(message):
            "Failed to resolve bookmark: \(message)"
        case .bookmarkStale:
            "Bookmark is stale and needs to be recreated"
        case let .sandboxViolation(message):
            "Sandbox violation: \(message)"
        case let .accessDenied(message):
            "Access denied: \(message)"
        case let .resourceUnavailable(message):
            "Resource unavailable: \(message)"
        case let .operationNotPermitted(message):
            "Operation not permitted: \(message)"
        case let .accessValidationFailed(message):
            "Access validation failed: \(message)"
        case let .xpcConnectionFailed(message):
            "XPC connection failed: \(message)"
        case let .xpcServiceError(message):
            "XPC service error: \(message)"
        case let .xpcPermissionDenied(message):
            "XPC permission denied: \(message)"
        case let .xpcValidationFailed(message):
            "XPC validation failed: \(message)"
        case let .keychainError(message):
            "Keychain error: \(message)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .bookmarkStale:
            "Request permission again to create a new bookmark"
        case .permissionDenied:
            "Try requesting permission again or select a different file"
        case .sandboxViolation:
            "Ensure the operation complies with sandbox restrictions"
        case .accessDenied:
            "Check file permissions and try again"
        case .resourceUnavailable:
            "Wait and try again, or check if the resource exists"
        case .xpcConnectionFailed:
            "Try restarting the application"
        case .xpcServiceError:
            "Check if the service is running and try again"
        case .keychainError:
            "Check keychain access and try again"
        default:
            nil
        }
    }

    public var failureReason: String? {
        switch self {
        case .bookmarkStale:
            "The security-scoped bookmark is no longer valid"
        case .sandboxViolation:
            "The operation violates sandbox restrictions"
        case .xpcConnectionFailed:
            "Could not establish XPC connection"
        case .xpcServiceError:
            "XPC service encountered an error"
        case .keychainError:
            "Keychain operation failed"
        default:
            nil
        }
    }
}
