import Foundation

// MARK: - ResticOperationError

/// Represents errors that can occur during restic operations.
@objc
public enum ResticOperationError: ResticErrorProtocol {
    case operationFailed(operation: String, reason: String)
    case operationCancelled(operation: String)
    case operationTimeout(operation: String, duration: TimeInterval)
    case operationInProgress(operation: String)
    case operationNotFound(operation: String)
    case invalidOperation(operation: String)

    // MARK: Public

    public var errorDescription: String {
        switch self {
        case let .operationFailed(operation, reason):
            "Operation '\(operation)' failed: \(reason)"
        case let .operationCancelled(operation):
            "Operation '\(operation)' was cancelled."
        case let .operationTimeout(operation, duration):
            "Operation '\(operation)' timed out after \(duration) seconds"
        case let .operationInProgress(operation):
            "Operation '\(operation)' is in progress."
        case let .operationNotFound(operation):
            "Operation '\(operation)' not found."
        case let .invalidOperation(operation):
            "Operation '\(operation)' is invalid."
        }
    }

    public var failureReason: String {
        switch self {
        case let .operationFailed(operation, reason):
            "The operation '\(operation)' encountered an error: \(reason)"
        case let .operationCancelled(operation):
            "The operation '\(operation)' was cancelled."
        case let .operationTimeout(operation, duration):
            "The operation '\(operation)' exceeded the time limit of \(duration) seconds"
        case let .operationInProgress(operation):
            "Another operation '\(operation)' is already running."
        case let .operationNotFound(operation):
            "The requested operation '\(operation)' could not be found."
        case let .invalidOperation(operation):
            "The operation '\(operation)' is not valid."
        }
    }

    public var recoverySuggestion: String {
        switch self {
        case .operationFailed:
            """
            - Check operation parameters
            - Verify prerequisites
            - Review error details
            """
        case .operationCancelled:
            """
            - Restart the operation if needed
            - Check for blocking processes
            - Verify system state
            """
        case .operationTimeout:
            """
            - Increase timeout limit
            - Check system load
            - Optimize operation
            """
        case .operationInProgress:
            """
            - Wait for current operation
            - Check operation status
            - Cancel if necessary
            """
        case .operationNotFound:
            """
            - Verify operation exists
            - Check configuration
            - Try different operation
            """
        case .invalidOperation:
            """
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
            Thread.callStackSymbols.first
        }
    }

    public var exitCode: Int32 {
        switch self {
        case .operationFailed: 1
        case .operationCancelled: 130
        case .operationTimeout: 124
        case .operationInProgress: 75
        case .operationNotFound: 69
        case .invalidOperation: 64
        }
    }

    public static func from(exitCode: Int32) -> ResticOperationError? {
        switch exitCode {
        case 1:
            .operationFailed(
                operation: "backup",
                reason: "Unknown error"
            )
        case 130:
            .operationCancelled(
                operation: "restore"
            )
        case 124:
            .operationTimeout(
                operation: "check",
                duration: 0
            )
        case 75:
            .operationInProgress(
                operation: "prune"
            )
        case 69:
            .operationNotFound(
                operation: "backup"
            )
        case 64:
            .invalidOperation(
                operation: "restore"
            )
        default: nil
        }
    }
}

extension ResticOperationError {
    var localizedDescription: String {
        switch self {
        case let .invalidOperation(operation):
            "The requested operation '\(operation)' is not valid or supported."
        case let .operationFailed(operation, reason):
            "Operation '\(operation)' failed: \(reason)"
        case let .operationCancelled(operation):
            "Operation '\(operation)' was cancelled by user or system."
        case let .operationTimeout(operation, duration):
            "Operation '\(operation)' timed out after \(duration) seconds."
        case let .operationInProgress(operation):
            "Another operation '\(operation)' is currently in progress."
        case let .operationNotFound(operation):
            "Operation '\(operation)' not found."
        }
    }

    var recoverySuggestion: String {
        switch self {
        case .invalidOperation:
            "Check if the operation is supported and try again."
        case .operationFailed:
            """
            Review error details and try the operation again. If the problem \
            persists, check system logs for more information.
            """
        case .operationCancelled:
            "Restart the operation if needed."
        case .operationTimeout:
            """
            Check network connection and system resources, then try again. \
            Consider increasing timeout value.
            """
        case .operationInProgress:
            "Wait for current operation to complete before retrying."
        case .operationNotFound:
            """
            Verify operation exists and try again. Check configuration and \
            try a different operation if needed.
            """
        }
    }
}
