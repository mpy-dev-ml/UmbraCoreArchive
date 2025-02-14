@preconcurrency import Foundation

// MARK: - MetricContext

/// Context for logging metrics
public struct MetricContext {
    // MARK: Lifecycle

    /// Initialize with values
    public init(
        name: String,
        value: Double,
        unit: String,
        metadata: [String: String] = [:]
    ) {
        self.name = name
        self.value = value
        self.unit = unit
        self.metadata = metadata
    }

    // MARK: Public

    /// Metric name
    public let name: String

    /// Metric value
    public let value: Double

    /// Metric unit
    public let unit: String

    /// Additional metadata
    public let metadata: [String: String]
}
