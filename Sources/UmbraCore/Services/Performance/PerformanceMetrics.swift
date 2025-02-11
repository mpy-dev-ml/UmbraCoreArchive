import Foundation

/// Service for collecting and analyzing performance metrics
public final class PerformanceMetrics: BaseSandboxedService {
    // MARK: Lifecycle

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

    // MARK: Public

    // MARK: - Types

    /// Metric analysis result
    public struct AnalysisResult {
        // MARK: Lifecycle

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

        // MARK: Public

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

        // MARK: Internal

        /// Get start date for window
        var startDate: Date {
            let now = Date()
            switch self {
            case let .minutes(count):
                return now.addingTimeInterval(-TimeInterval(count * 60))
            case let .hours(count):
                return now.addingTimeInterval(-TimeInterval(count * 3600))
            case let .days(count):
                return now.addingTimeInterval(-TimeInterval(count * 86400))
            case let .range(start, _):
                return start
            }
        }

        /// Get end date for window
        var endDate: Date {
            switch self {
            case .minutes,
                 .hours,
                 .days:
                Date()
            case let .range(_, end):
                end
            }
        }
    }

    // MARK: - Public Methods

    /// Analyse metrics for a specific type and time window
    /// - Parameters:
    ///   - type: Metric type
    ///   - window: Time window
    /// - Returns: Analysis result
    public func analyzeMetrics(
        type: PerformanceMonitor.MetricType,
        window: TimeWindow
    ) -> AnalysisResult {
        // Get metrics for window
        let metrics = getMetricsInWindow(type: type, window: window)

        guard !metrics.isEmpty else {
            return createEmptyAnalysisResult()
        }

        let values = metrics.map(\.value)
        let statistics = calculateBasicStatistics(values)
        let standardDeviation = calculateStandardDeviation(values, average: statistics.average)
        let percentiles = calculatePercentiles(values)

        return createAnalysisResult(
            statistics: statistics,
            standardDeviation: standardDeviation,
            percentiles: percentiles,
            sampleCount: values.count
        )
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
        for (date, values) in buckets where !values.isEmpty {
            trends[date] = values.reduce(0, +) / Double(values.count)
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
        let values = metrics.map(\.value)
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

    // MARK: - Private Analysis Methods

    private func getMetricsInWindow(
        type: PerformanceMonitor.MetricType,
        window: TimeWindow
    ) -> [PerformanceMonitor.Metric] {
        monitor.getMetrics(for: type).filter { metric in
            metric.timestamp >= window.startDate &&
                metric.timestamp <= window.endDate
        }
    }

    private func createEmptyAnalysisResult() -> AnalysisResult {
        AnalysisResult(
            average: 0,
            minimum: 0,
            maximum: 0,
            standardDeviation: 0,
            percentiles: [:],
            sampleCount: 0
        )
    }

    private struct BasicStatistics {
        let average: Double
        let minimum: Double
        let maximum: Double
    }

    private func calculateBasicStatistics(_ values: [Double]) -> BasicStatistics {
        let count = values.count
        let sum = values.reduce(0, +)

        return BasicStatistics(
            average: sum / Double(count),
            minimum: values.min() ?? 0,
            maximum: values.max() ?? 0
        )
    }

    private func calculateStandardDeviation(_ values: [Double], average: Double) -> Double {
        let count = Double(values.count)
        let squaredDifferences = values.map { pow($0 - average, 2) }
        let variance = squaredDifferences.reduce(0, +) / count
        return sqrt(variance)
    }

    private func calculatePercentiles(_ values: [Double]) -> [Double: Double] {
        let sortedValues = values.sorted()
        let count = values.count
        var percentiles: [Double: Double] = [:]

        for percentile in [50.0, 75.0, 90.0, 95.0, 99.0] {
            let index = Int(ceil(Double(count) * percentile / 100.0)) - 1
            percentiles[percentile] = sortedValues[max(0, min(index, count - 1))]
        }

        return percentiles
    }

    private func createAnalysisResult(
        statistics: BasicStatistics,
        standardDeviation: Double,
        percentiles: [Double: Double],
        sampleCount: Int
    ) -> AnalysisResult {
        let result = AnalysisResult(
            average: statistics.average,
            minimum: statistics.minimum,
            maximum: statistics.maximum,
            standardDeviation: standardDeviation,
            percentiles: percentiles,
            sampleCount: sampleCount
        )

        logAnalysisResult(result)
        return result
    }

    private func logAnalysisResult(_ result: AnalysisResult) {
        logger.debug(
            """
            Analysed metrics:
            Average: \(result.average)
            Min: \(result.minimum)
            Max: \(result.maximum)
            StdDev: \(result.standardDeviation)
            Samples: \(result.sampleCount)
            Percentiles:
            \(formatPercentiles(result.percentiles))
            """,
            file: #file,
            function: #function,
            line: #line
        )
    }

    private func formatPercentiles(_ percentiles: [Double: Double]) -> String {
        percentiles
            .sorted { $0.key < $1.key }
            .map { "  \($0.key)th: \($0.value)" }
            .joined(separator: "\n")
    }

    // MARK: Private

    /// Performance monitor
    private let monitor: PerformanceMonitor

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.performance.metrics",
        qos: .utility,
        attributes: .concurrent
    )
}
