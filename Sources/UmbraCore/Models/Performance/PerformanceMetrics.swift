import Foundation

// MARK: - MetricUnit

/// Unit of measurement for metrics
public enum MetricUnit: String, Codable {
    /// Bytes
    case bytes
    /// Milliseconds
    case milliseconds
    /// Count
    case count
    /// Percentage
    case percentage
}

// MARK: - OperationStatus

/// Status of an operation
public enum OperationStatus: String, Codable {
    /// Operation succeeded
    case success
    /// Operation failed
    case failure
    /// Operation in progress
    case inProgress
    /// Operation cancelled
    case cancelled
}

// MARK: - MetricMeasurement

/// Represents a single performance metric measurement
public struct MetricMeasurement {
    /// Name of the metric
    public let name: String

    /// Measured value
    public let value: Double

    /// Unit of measurement
    public let unit: MetricUnit

    /// Timestamp of measurement
    public let timestamp: Date

    /// Additional context about the measurement
    public let metadata: [String: String]?
}

// MARK: - MonitoredOperation

/// Represents a monitored operation
public struct MonitoredOperation {
    /// Unique identifier for the operation
    public let id: UUID

    /// Name of the operation
    public let name: String

    /// Start time of the operation
    public let startTime: Date

    /// End time of the operation
    public let endTime: Date?

    /// Status of the operation
    public let status: OperationStatus?

    /// Additional context about the operation
    public let metadata: [String: String]?

    /// Duration in milliseconds
    public var duration: Double? {
        guard let endTime else {
            return nil
        }
        return endTime.timeIntervalSince(startTime) * 1_000
    }
}

// MARK: - PerformanceStatistics

/// Statistical summary of performance metrics
public struct PerformanceStatistics {
    /// Average operation duration in milliseconds
    public let averageOperationDuration: Double

    /// Success rate of operations (percentage)
    public let operationSuccessRate: Double

    /// Peak memory usage in bytes
    public let peakMemoryUsage: UInt64

    /// Average CPU usage percentage
    public let averageCPUUsage: Double

    /// Peak CPU usage percentage
    public let peakCPUUsage: Double

    /// Average backup speed in bytes per second
    public let averageBackupSpeed: Double

    /// Total number of operations
    public let totalOperations: Int

    /// Number of failed operations
    public let failedOperations: Int
}
