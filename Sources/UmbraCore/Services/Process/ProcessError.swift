import Foundation

/// Errors that can occur during process operations
public enum ProcessError: LocalizedError {
    /// Process is already being monitored
    case alreadyMonitoring(Int32)
    /// Process is not being monitored
    case notMonitoring(Int32)
    /// Failed to get process info
    case infoPidFailed(Int32)
    /// Failed to get process name
    case namePidFailed(Int32)
    /// Process terminated
    case terminated(Int32)
    /// Operation timeout
    case timeout(Int32)
    /// Invalid state
    case invalidState(String)
    /// Operation failed
    case operationFailed(String)

    // MARK: Public

    /// Localized description of the error
    public var errorDescription: String? {
        switch self {
        case let .alreadyMonitoring(pid):
            "Process is already being monitored: \(pid)"
        case let .notMonitoring(pid):
            "Process is not being monitored: \(pid)"
        case let .infoPidFailed(pid):
            "Failed to get process info: \(pid)"
        case let .namePidFailed(pid):
            "Failed to get process name: \(pid)"
        case let .terminated(pid):
            "Process terminated: \(pid)"
        case let .timeout(pid):
            "Operation timed out for process: \(pid)"
        case let .invalidState(reason):
            "Invalid process state: \(reason)"
        case let .operationFailed(reason):
            "Process operation failed: \(reason)"
        }
    }

    /// Failure reason for the error
    public var failureReason: String? {
        switch self {
        case .alreadyMonitoring:
            "The process is already being monitored by the system"
        case .notMonitoring:
            "The process is not currently being monitored"
        case .infoPidFailed:
            "Failed to retrieve process information from the system"
        case .namePidFailed:
            "Failed to retrieve process name from the system"
        case .terminated:
            "The process has terminated and is no longer running"
        case .timeout:
            "The operation exceeded the maximum allowed time"
        case .invalidState:
            "The process is in an invalid state for this operation"
        case .operationFailed:
            "The process operation failed to complete successfully"
        }
    }

    /// Recovery suggestion for the error
    public var recoverySuggestion: String? {
        switch self {
        case .alreadyMonitoring:
            "Stop monitoring the process before attempting to monitor it again"
        case .notMonitoring:
            "Start monitoring the process before performing operations"
        case .infoPidFailed:
            "Verify the process exists and you have permission to access it"
        case .namePidFailed:
            "Verify the process exists and you have permission to access it"
        case .terminated:
            "Restart the process if needed"
        case .timeout:
            "Try the operation again or increase the timeout duration"
        case .invalidState:
            "Wait for the process to be in a valid state"
        case .operationFailed:
            "Check the process status and try the operation again"
        }
    }

    /// Help anchor for documentation
    public var helpAnchor: String {
        switch self {
        case .alreadyMonitoring:
            "process-already-monitoring"
        case .notMonitoring:
            "process-not-monitoring"
        case .infoPidFailed:
            "process-info-failed"
        case .namePidFailed:
            "process-name-failed"
        case .terminated:
            "process-terminated"
        case .timeout:
            "process-timeout"
        case .invalidState:
            "process-invalid-state"
        case .operationFailed:
            "process-operation-failed"
        }
    }
}
