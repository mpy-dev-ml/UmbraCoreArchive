import Foundation

/// Represents system-level errors that can occur during restic operations.
public enum ResticSystemError: ResticErrorProtocol {
    case insufficientPermissions(String)
    case insufficientResources(String)
    case fileSystemError(String)
    case networkError(String)
    case systemTimeout(String)

    public var errorDescription: String {
        switch self {
        case .insufficientPermissions(let path):
            return "Insufficient permissions for path: \(path)"
        case .insufficientResources(let details):
            return "Insufficient system resources: \(details)"
        case .fileSystemError(let path):
            return "File system error for path: \(path)"
        case .networkError(let details):
            return "Network error: \(details)"
        case .systemTimeout(let operation):
            return "System timeout during operation: \(operation)"
        }
    }

    public var failureReason: String {
        switch self {
        case .insufficientPermissions(let path):
            return "The current user lacks required permissions for \(path)"
        case .insufficientResources(let details):
            return "The system lacks required resources: \(details)"
        case .fileSystemError(let path):
            return "A file system error occurred at \(path)"
        case .networkError(let details):
            return "A network error occurred: \(details)"
        case .systemTimeout(let operation):
            return "The system timed out while performing \(operation)"
        }
    }

    public var recoverySuggestion: String {
        switch self {
        case .insufficientPermissions:
            return """
            - Check file permissions
            - Request elevated access
            - Update ACL settings
            """
        case .insufficientResources:
            return """
            - Free up system resources
            - Close unused applications
            - Check resource limits
            """
        case .fileSystemError:
            return """
            - Check disk health
            - Verify file system
            - Repair if necessary
            """
        case .networkError:
            return """
            - Check network connection
            - Verify DNS settings
            - Test connectivity
            """
        case .systemTimeout:
            return """
            - Increase timeout value
            - Check system load
            - Retry operation
            """
        }
    }

    public var command: String? {
        switch self {
        case .insufficientPermissions(let path),
             .insufficientResources(let details),
             .fileSystemError(let path),
             .networkError(let details),
             .systemTimeout(let operation):
            return Thread.callStackSymbols.first
        }
    }
}
