//
// PerformanceMetrics.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Service for collecting and analyzing performance metrics
public final class PerformanceMetrics: BaseSandboxedService {
    // MARK: - Types

    /// Metric analysis result
    public struct AnalysisResult {
        /// Average value
        public let average: Double

        /// Minimum value
        public let minimum: Double

        /// Maximum value
        public let maximum: Double

        /// Standard deviation
        public let standardDeviation: Double

        /// Percentile values
        public let percentiles: [Double: Double]

        /// Sample count
        public let sampleCount: Int

        /// Initialize with values
        public init(
            average: Double,
            minimum: Double,
            maximum: Double,
            standardDeviation: Double,
            percentiles: [Double: Double],
            sampleCount: Int
        ) {
            self.average = average
            self.minimum = minimum
            self.maximum = maximum
            self.standardDeviation = standardDeviation
            self.percentiles = percentiles
            self.sampleCount = sampleCount
        }
    }

    /// Time window for analysis
    public enum TimeWindow {
        /// Last N minutes
        case minutes(Int)
        /// Last N hours
        case hours(Int)
        /// Last N days
        case days(Int)
        /// Custom range
        case range(Date, Date)

        /// Get start date for window
        var startDate: Date {
            let now = Date()
            switch self {
            case .minutes(let count):
                return now.addingTimeInterval(-TimeInterval(count * 60))
            case .hours(let count):
                return now.addingTimeInterval(-TimeInterval(count * 3600))
            case .days(let count):
                return now.addingTimeInterval(-TimeInterval(count * 86400))
            case .range(let start, _):
                return start
            }
        }

        /// Get end date for window
        var endDate: Date {
            switch self {
            case .minutes, .hours, .days:
                return Date()
            case .range(_, let end):
                return end
            }
        }
    }

    // MARK: - Properties

    /// Performance monitor
    private let monitor: PerformanceMonitor

    /// Queue for synchronizing operations
    private let queue = DispatchQueue(
        label: "dev.mpy.umbracore.performance.metrics",
        qos: .utility,
        attributes: .concurrent
    )

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - monitor: Performance monitor
    ///   - logger: Logger for tracking operations
    public init(
        monitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        self.monitor = monitor
        super.init(logger: logger)
    }

    // MARK: - Public Methods

    /// Analyze metrics for type and window
    /// - Parameters:
    ///   - type: Metric type
    ///   - window: Time window
    /// - Returns: Analysis result
    public func analyzeMetrics(
        type: PerformanceMonitor.MetricType,
        window: TimeWindow
    ) -> AnalysisResult {
        // Get metrics for window
        let metrics = monitor.getMetrics(for: type).filter { metric in
            metric.timestamp >= window.startDate &&
            metric.timestamp <= window.endDate
        }

        guard !metrics.isEmpty else {
            return AnalysisResult(
                average: 0,
                minimum: 0,
                maximum: 0,
                standardDeviation: 0,
                percentiles: [:],
                sampleCount: 0
            )
        }

        // Calculate statistics
        let values = metrics.map { $0.value }
        let count = values.count
        let sum = values.reduce(0, +)
        let average = sum / Double(count)
        let minimum = values.min() ?? 0
        let maximum = values.max() ?? 0

        // Calculate standard deviation
        let squaredDifferences = values.map { pow($0 - average, 2) }
        let variance = squaredDifferences.reduce(0, +) / Double(count)
        let standardDeviation = sqrt(variance)

        // Calculate percentiles
        let sortedValues = values.sorted()
        var percentiles: [Double: Double] = [:]

        for percentile in [50.0, 75.0, 90.0, 95.0, 99.0] {
            let index = Int(ceil(Double(count) * percentile / 100.0)) - 1
            percentiles[percentile] = sortedValues[max(0, min(index, count - 1))]
        }

        // Create result
        let result = AnalysisResult(
            average: average,
            minimum: minimum,
            maximum: maximum,
            standardDeviation: standardDeviation,
            percentiles: percentiles,
            sampleCount: count
        )

        // Log analysis
        logger.debug(
            """
            Analyzed metrics:
            Type: \(type.rawValue)
            Window: \(window)
            Average: \(average)
            Min/Max: \(minimum)/\(maximum)
            StdDev: \(standardDeviation)
            Samples: \(count)
            """,
            file: #file,
            function: #function,
            line: #line
        )

        return result
    }

    /// Get operation trends
    /// - Parameters:
    ///   - type: Metric type
    ///   - window: Time window
    ///   - interval: Interval for buckets
    /// - Returns: Dictionary of timestamps and values
    public func getOperationTrends(
        type: PerformanceMonitor.MetricType,
        window: TimeWindow,
        interval: TimeInterval
    ) -> [Date: Double] {
        // Get metrics for window
        let metrics = monitor.getMetrics(for: type).filter { metric in
            metric.timestamp >= window.startDate &&
            metric.timestamp <= window.endDate
        }

        var trends: [Date: Double] = [:]
        var buckets: [Date: [Double]] = [:]

        // Create buckets
        var currentDate = window.startDate
        while currentDate <= window.endDate {
            buckets[currentDate] = []
            currentDate = currentDate.addingTimeInterval(interval)
        }

        // Fill buckets
        for metric in metrics {
            let bucketDate = Date(
                timeIntervalSinceReferenceDate: floor(
                    metric.timestamp.timeIntervalSinceReferenceDate / interval
                ) * interval
            )
            buckets[bucketDate]?.append(metric.value)
        }

        // Calculate averages
        for (date, values) in buckets {
            if !values.isEmpty {
                trends[date] = values.reduce(0, +) / Double(values.count)
            }
        }

        // Log trends
        logger.debug(
            """
            Operation trends:
            Type: \(type.rawValue)
            Window: \(window)
            Interval: \(interval)s
            Points: \(trends.count)
            """,
            file: #file,
            function: #function,
            line: #line
        )

        return trends
    }

    /// Get operation anomalies
    /// - Parameters:
    ///   - type: Metric type
    ///   - window: Time window
    ///   - threshold: Standard deviations from mean
    /// - Returns: Array of anomalous metrics
    public func getOperationAnomalies(
        type: PerformanceMonitor.MetricType,
        window: TimeWindow,
        threshold: Double = 2.0
    ) -> [PerformanceMonitor.Metric] {
        // Get metrics for window
        let metrics = monitor.getMetrics(for: type).filter { metric in
            metric.timestamp >= window.startDate &&
            metric.timestamp <= window.endDate
        }

        guard metrics.count > 1 else {
            return []
        }

        // Calculate statistics
        let values = metrics.map { $0.value }
        let average = values.reduce(0, +) / Double(values.count)
        let squaredDifferences = values.map { pow($0 - average, 2) }
        let variance = squaredDifferences.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)

        // Find anomalies
        let anomalies = metrics.filter { metric in
            abs(metric.value - average) > threshold * standardDeviation
        }

        // Log anomalies
        logger.debug(
            """
            Operation anomalies:
            Type: \(type.rawValue)
            Window: \(window)
            Threshold: \(threshold)σ
            Count: \(anomalies.count)
            """,
            file: #file,
            function: #function,
            line: #line
        )

        return anomalies
    }
}
