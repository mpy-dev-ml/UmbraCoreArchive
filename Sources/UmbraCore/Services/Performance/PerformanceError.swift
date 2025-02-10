/// Errors that can occur during performance monitoring
public enum PerformanceError: LocalizedError {
    /// Invalid metric identifier
    case invalidMetricId(String)
    /// No data available for metric
    case noDataAvailable(String)
    /// Invalid time range
    case invalidTimeRange(String)
    /// Operation timeout
    case timeout(String)
    /// Invalid operation
    case invalidOperation(String)
    /// Memory limit exceeded
    case memoryLimitExceeded(String)
    /// Operation failed
    case operationFailed(String)

    /// Localized description of the error
    public var errorDescription: String? {
        switch self {
        case .invalidMetricId(let id):
            return "Invalid metric identifier: \(id)"
        case .noDataAvailable(let id):
            return "No data available for metric: \(id)"
        case .invalidTimeRange(let reason):
            return "Invalid time range: \(reason)"
        case .timeout(let operation):
            return "Operation timed out: \(operation)"
        case .invalidOperation(let reason):
            return "Invalid operation: \(reason)"
        case .memoryLimitExceeded(let reason):
            return "Memory limit exceeded: \(reason)"
        case .operationFailed(let reason):
            return "Operation failed: \(reason)"
        }
    }

    /// Failure reason for the error
    public var failureReason: String? {
        switch self {
        case .invalidMetricId:
            return "The specified metric identifier is not valid"
        case .noDataAvailable:
            return "No performance data is available for the specified metric"
        case .invalidTimeRange:
            return "The specified time range is not valid for this operation"
        case .timeout:
            return "The operation exceeded the maximum allowed time"
        case .invalidOperation:
            return "The requested operation is not valid in the current state"
        case .memoryLimitExceeded:
            return "The operation would exceed the allowed memory limit"
        case .operationFailed:
            return "The operation failed to complete successfully"
        }
    }

    /// Recovery suggestion for the error
    public var recoverySuggestion: String? {
        switch self {
        case .invalidMetricId:
            return "Check that the metric identifier is correct and try again"
        case .noDataAvailable:
            return "Wait for data to be collected or verify the metric is being tracked"
        case .invalidTimeRange:
            return "Specify a valid time range and try again"
        case .timeout:
            return "Try the operation again or increase the timeout duration"
        case .invalidOperation:
            return "Check the operation parameters and try again"
        case .memoryLimitExceeded:
            return "Clear old metrics or reduce the time range"
        case .operationFailed:
            return "Check the operation status and try again"
        }
    }

    /// Help anchor for documentation
    public var helpAnchor: String {
        switch self {
        case .invalidMetricId:
            return "performance-invalid-metric"
        case .noDataAvailable:
            return "performance-no-data"
        case .invalidTimeRange:
            return "performance-invalid-range"
        case .timeout:
            return "performance-timeout"
        case .invalidOperation:
            return "performance-invalid-operation"
        case .memoryLimitExceeded:
            return "performance-memory-limit"
        case .operationFailed:
            return "performance-operation-failed"
        }
    }
}
