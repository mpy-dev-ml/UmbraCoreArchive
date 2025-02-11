import Foundation

/// Represents system-level errors that can occur during restic operations.
public enum ResticSystemError: ResticErrorProtocol {
    case insufficientPermissions(String)
    case insufficientResources(String)
    case fileSystemError(String)
    case networkError(String)
    case systemTimeout(String)

    // MARK: Public

    public var errorDescription: String {
        switch self {
        case let .insufficientPermissions(path):
            "Insufficient permissions for path: \(path)"
        case let .insufficientResources(details):
            "Insufficient system resources: \(details)"
        case let .fileSystemError(path):
            "File system error for path: \(path)"
        case let .networkError(details):
            "Network error: \(details)"
        case let .systemTimeout(operation):
            "System timeout during operation: \(operation)"
        }
    }

    public var failureReason: String {
        switch self {
        case let .insufficientPermissions(path):
            "The current user lacks required permissions for \(path)"
        case let .insufficientResources(details):
            "The system lacks required resources: \(details)"
        case let .fileSystemError(path):
            "A file system error occurred at \(path)"
        case let .networkError(details):
            "A network error occurred: \(details)"
        case let .systemTimeout(operation):
            "The system timed out while performing \(operation)"
        }
    }

    public var recoverySuggestion: String {
        switch self {
        case .insufficientPermissions:
            """
            - Check file permissions
            - Request elevated access
            - Update ACL settings
            """
        case .insufficientResources:
            """
            - Free up system resources
            - Close unused applications
            - Check resource limits
            """
        case .fileSystemError:
            """
            - Check disk health
            - Verify file system
            - Repair if necessary
            """
        case .networkError:
            """
            - Check network connection
            - Verify DNS settings
            - Test connectivity
            """
        case .systemTimeout:
            """
            - Increase timeout value
            - Check system load
            - Retry operation
            """
        }
    }

    public var command: String? {
        switch self {
        case let .insufficientPermissions(path),
             let .insufficientResources(details),
             let .fileSystemError(path),
             let .networkError(details),
             let .systemTimeout(operation):
            Thread.callStackSymbols.first
        }
    }
}
