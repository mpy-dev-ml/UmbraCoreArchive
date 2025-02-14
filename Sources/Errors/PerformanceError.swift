import Foundation

/// Errors that can occur during performance monitoring
public enum PerformanceError: Error, CustomStringConvertible, LocalizedError {
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
            String(format: "Invalid metric identifier: %@", id)

        case let .noDataAvailable(id):
            String(format: "No data available for metric: %@", id)

        case let .invalidTimeRange(reason):
            String(format: "Invalid time range: %@", reason)

        case let .timeout(operation):
            String(format: "Operation timed out: %@", operation)

        case let .invalidOperation(reason):
            String(format: "Invalid operation: %@", reason)

        case let .memoryLimitExceeded(reason):
            String(format: "Memory limit exceeded: %@", reason)

        case let .operationFailed(reason):
            String(format: "Operation failed: %@", reason)
        }
    }

    /// Description of the error
    public var description: String {
        errorDescription ?? "Unknown error"
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
            "performance-error-invalid-metric-id"
        case .noDataAvailable:
            "performance-error-no-data-available"
        case .invalidTimeRange:
            "performance-error-invalid-time-range"
        case .timeout:
            "performance-error-timeout"
        case .invalidOperation:
            "performance-error-invalid-operation"
        case .memoryLimitExceeded:
            "performance-error-memory-limit-exceeded"
        case .operationFailed:
            "performance-error-operation-failed"
        }
    }
}
