import Foundation

/// Performance metric type
@frozen public enum PerformanceMetricType: String, Codable, Sendable {
    case memory
    case cpu
    case disk
    case network
    case battery
    case logging
    case maintenance
    case other
}

/// Performance metric unit
@frozen public enum PerformanceMetricUnit: String, Codable, Sendable {
    case bytes
    case percentage
    case milliseconds
    case count
    case error
    case other
}

/// Performance metric data
public struct PerformanceMetric: Codable, Sendable {
    /// Metric type
    public let type: PerformanceMetricType
    
    /// Metric value
    public let value: Double
    
    /// Metric unit
    public let unit: PerformanceMetricUnit
    
    /// Timestamp
    public let timestamp: Date
    
    /// Initialize a new performance metric
    /// - Parameters:
    ///   - type: Metric type
    ///   - value: Metric value
    ///   - unit: Metric unit
    ///   - timestamp: Timestamp
    public init(
        type: PerformanceMetricType,
        value: Double,
        unit: PerformanceMetricUnit,
        timestamp: Date = Date()
    ) {
        self.type = type
        self.value = value
        self.unit = unit
        self.timestamp = timestamp
    }
}

/// Service for monitoring performance metrics
@MainActor
public final class PerformanceMonitor: @unchecked Sendable {
    // MARK: - Properties
    
    /// Maximum number of metrics to keep
    private(set) var maxMetrics: Int
    
    /// Performance metrics
    private(set) var metrics: [PerformanceMetric]
    
    // MARK: - Initialization
    
    /// Initialize performance monitor
    /// - Parameter maxMetrics: Maximum number of metrics to keep
    public init(maxMetrics: Int = 1000) {
        self.maxMetrics = maxMetrics
        self.metrics = []
    }
    
    // MARK: - Metric Management
    
    /// Track a performance metric
    /// - Parameters:
    ///   - type: Metric type
    ///   - value: Metric value
    ///   - unit: Metric unit
    public func trackMetric(
        type: PerformanceMetricType,
        value: Double,
        unit: PerformanceMetricUnit
    ) {
        let metric = PerformanceMetric(
            type: type,
            value: value,
            unit: unit
        )
        
        metrics.append(metric)
        if metrics.count > maxMetrics {
            metrics.removeFirst(metrics.count - maxMetrics)
        }
    }
    
    /// Get metrics filtered by type and date range
    /// - Parameters:
    ///   - type: Metric type
    ///   - startDate: Start date
    ///   - endDate: End date
    /// - Returns: Filtered metrics
    public func getMetrics(
        type: PerformanceMetricType? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> [PerformanceMetric] {
        var filtered = metrics
        
        if let type = type {
            filtered = filtered.filter { $0.type == type }
        }
        
        if let startDate = startDate {
            filtered = filtered.filter { $0.timestamp >= startDate }
        }
        
        if let endDate = endDate {
            filtered = filtered.filter { $0.timestamp <= endDate }
        }
        
        return filtered
    }
    
    /// Clear all metrics
    public func clearMetrics() {
        metrics.removeAll()
    }
    
    /// Get metric count
    /// - Returns: Number of metrics
    public func metricCount() -> Int {
        metrics.count
    }
    
    /// Update maximum metrics
    /// - Parameter count: New maximum
    public func updateMaxMetrics(_ count: Int) {
        maxMetrics = count
        if metrics.count > maxMetrics {
            metrics.removeFirst(metrics.count - maxMetrics)
        }
    }
}
