/// Errors that can occur during performance monitoring
public enum PerformanceError: LocalizedError {
    /// Invalid metric identifier
    case invalidMetricID(String)
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

    // MARK: Public

    /// Localized description of the error
    public var errorDescription: String? {
        switch self {
        case let .invalidMetricID(id):
            "Invalid metric identifier: \(id)"
        case let .noDataAvailable(id):
            "No data available for metric: \(id)"
        case let .invalidTimeRange(reason):
            "Invalid time range: \(reason)"
        case let .timeout(operation):
            "Operation timed out: \(operation)"
        case let .invalidOperation(reason):
            "Invalid operation: \(reason)"
        case let .memoryLimitExceeded(reason):
            "Memory limit exceeded: \(reason)"
        case let .operationFailed(reason):
            "Operation failed: \(reason)"
        }
    }

    /// Failure reason for the error
    public var failureReason: String? {
        switch self {
        case .invalidMetricID:
            "The specified metric identifier is not valid"
        case .noDataAvailable:
            "No performance data is available for the specified metric"
        case .invalidTimeRange:
            "The specified time range is not valid for this operation"
        case .timeout:
            "The operation exceeded the maximum allowed time"
        case .invalidOperation:
            "The requested operation is not valid in the current state"
        case .memoryLimitExceeded:
            "The operation would exceed the allowed memory limit"
        case .operationFailed:
            "The operation failed to complete successfully"
        }
    }

    /// Recovery suggestion for the error
    public var recoverySuggestion: String? {
        switch self {
        case .invalidMetricID:
            "Check that the metric identifier is correct and try again"
        case .noDataAvailable:
            "Wait for data to be collected or verify the metric is being tracked"
        case .invalidTimeRange:
            "Specify a valid time range and try again"
        case .timeout:
            "Try the operation again or increase the timeout duration"
        case .invalidOperation:
            "Check the operation parameters and try again"
        case .memoryLimitExceeded:
            "Clear old metrics or reduce the time range"
        case .operationFailed:
            "Check the operation status and try again"
        }
    }

    /// Help anchor for documentation
    public var helpAnchor: String {
        switch self {
        case .invalidMetricID:
            "performance-invalid-metric"
        case .noDataAvailable:
            "performance-no-data"
        case .invalidTimeRange:
            "performance-invalid-range"
        case .timeout:
            "performance-timeout"
        case .invalidOperation:
            "performance-invalid-operation"
        case .memoryLimitExceeded:
            "performance-memory-limit"
        case .operationFailed:
            "performance-operation-failed"
        }
    }
}
