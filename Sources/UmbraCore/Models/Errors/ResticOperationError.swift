/// Represents errors that can occur during restic operations.
@objc
public enum ResticOperationError: Int, ResticErrorProtocol {
    case operationFailed(operation: String, reason: String)
    case operationCancelled(operation: String)
    case operationTimeout(operation: String, duration: TimeInterval)
    case operationInProgress(operation: String)
    case operationNotFound(operation: String)
    case invalidOperation(operation: String)

    public var errorDescription: String {
        switch self {
        case let .operationFailed(operation, reason):
            return "Operation '\(operation)' failed: \(reason)"
        case let .operationCancelled(operation):
            return "Operation '\(operation)' was cancelled."
        case let .operationTimeout(operation, duration):
            return "Operation '\(operation)' timed out after \(duration) seconds"
        case let .operationInProgress(operation):
            return "Operation '\(operation)' is in progress."
        case let .operationNotFound(operation):
            return "Operation '\(operation)' not found."
        case let .invalidOperation(operation):
            return "Operation '\(operation)' is invalid."
        }
    }

    public var failureReason: String {
        switch self {
        case let .operationFailed(operation, reason):
            return "The operation '\(operation)' encountered an error: \(reason)"
        case let .operationCancelled(operation):
            return "The operation '\(operation)' was cancelled."
        case let .operationTimeout(operation, duration):
            return "The operation '\(operation)' exceeded the time limit of \(duration) seconds"
        case let .operationInProgress(operation):
            return "Another operation '\(operation)' is already running."
        case let .operationNotFound(operation):
            return "The requested operation '\(operation)' could not be found."
        case let .invalidOperation(operation):
            return "The operation '\(operation)' is not valid."
        }
    }

    public var recoverySuggestion: String {
        switch self {
        case .operationFailed:
            return """
            - Check operation parameters
            - Verify prerequisites
            - Review error details
            """
        case .operationCancelled:
            return """
            - Restart the operation if needed
            - Check for blocking processes
            - Verify system state
            """
        case .operationTimeout:
            return """
            - Increase timeout limit
            - Check system load
            - Optimize operation
            """
        case .operationInProgress:
            return """
            - Wait for current operation
            - Check operation status
            - Cancel if necessary
            """
        case .operationNotFound:
            return """
            - Verify operation exists
            - Check configuration
            - Try different operation
            """
        case .invalidOperation:
            return """
            - Check the operation is correctly formatted
            - Verify the operation is supported
            """
        }
    }

    public var command: String? {
        switch self {
        case .operationFailed,
             .operationCancelled,
             .operationTimeout,
             .operationInProgress,
             .operationNotFound,
             .invalidOperation:
            return Thread.callStackSymbols.first
        }
    }

    public static func from(exitCode: Int32) -> ResticOperationError? {
        switch exitCode {
        case 6:
            return .operationFailed(
                operation: "backup",
                reason: "Unknown error"
            )
        case 7:
            return .operationFailed(
                operation: "restore",
                reason: "Unknown error"
            )
        case 8:
            return .operationFailed(
                operation: "check",
                reason: "Unknown error"
            )
        case 9:
            return .operationFailed(
                operation: "prune",
                reason: "Unknown error"
            )
        default: return nil
        }
    }
}

extension ResticOperationError {
    var localizedDescription: String {
        switch self {
        case .invalidOperation(let operation):
            return "The requested operation '\(operation)' is not valid or supported."
        case let .operationFailed(operation, reason):
            return "Operation '\(operation)' failed: \(reason)"
        case let .operationCancelled(operation):
            return "Operation '\(operation)' was cancelled by user or system."
        case let .operationTimeout(operation, duration):
            return "Operation '\(operation)' timed out after \(duration) seconds."
        case let .operationInProgress(operation):
            return "Another operation '\(operation)' is currently in progress."
        case let .operationNotFound(operation):
            return "Operation '\(operation)' not found."
        }
    }

    var recoverySuggestion: String {
        switch self {
        case .invalidOperation:
            return "Check if the operation is supported and try again."
        case .operationFailed:
            return """
            Review error details and try the operation again. If the problem \
            persists, check system logs for more information.
            """
        case .operationCancelled:
            return "Restart the operation if needed."
        case .operationTimeout:
            return """
            Check network connection and system resources, then try again. \
            Consider increasing timeout value.
            """
        case .operationInProgress:
            return "Wait for current operation to complete before retrying."
        case .operationNotFound:
            return """
            Verify operation exists and try again. Check configuration and \
            try a different operation if needed.
            """
        }
    }
}
