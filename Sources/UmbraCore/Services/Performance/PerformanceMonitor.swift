@preconcurrency import Foundation

/// Service for monitoring performance metrics
@Observable
public actor PerformanceMonitor: PerformanceMonitorProtocol {
    // MARK: - Types

    /// Performance metric data structure
    public struct Metric: Sendable {
        /// Metric identifier
        public let id: String
        /// Start time of the metric
        public let startTime: Date
        /// Duration in seconds
        public let duration: TimeInterval
        /// Additional metadata
        public let metadata: [String: String]

        /// Initialize a new metric
        public init(
            id: String,
            startTime: Date,
            duration: TimeInterval,
            metadata: [String: String]
        ) {
            self.id = id
            self.startTime = startTime
            self.duration = duration
            self.metadata = metadata
        }
    }

    /// Performance statistics summary
    public struct Statistics: Sendable {
        /// Total duration across all samples
        public let totalDuration: TimeInterval
        /// Average duration per sample
        public let averageDuration: TimeInterval
        /// Shortest recorded duration
        public let minDuration: TimeInterval
        /// Longest recorded duration
        public let maxDuration: TimeInterval
        /// Number of samples analysed
        public let sampleCount: Int

        /// Initialize with calculated statistics
        public init(
            totalDuration: TimeInterval,
            averageDuration: TimeInterval,
            minDuration: TimeInterval,
            maxDuration: TimeInterval,
            sampleCount: Int
        ) {
            self.totalDuration = totalDuration
            self.averageDuration = averageDuration
            self.minDuration = minDuration
            self.maxDuration = maxDuration
            self.sampleCount = sampleCount
        }
    }

    // MARK: - Properties

    private let logger: LoggerProtocol
    private var metrics: [String: [Metric]] = [:]

    // MARK: - Initialization

    /// Initialize with logger
    /// - Parameter logger: Logger for performance metrics
    public init(logger: LoggerProtocol) {
        self.logger = logger
    }

    // MARK: - Public Methods

    /// Track duration of an operation
    public func trackDuration<T>(
        _ id: String,
        metadata: [String: String] = [:],
        operation: () async throws -> T
    ) async throws -> T {
        let startTime = Date()

        do {
            let result = try await operation()
            let duration = Date().timeIntervalSince(startTime)

            await recordSuccess(
                id: id,
                startTime: startTime,
                duration: duration,
                metadata: metadata
            )

            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime)

            await recordError(
                id: id,
                startTime: startTime,
                duration: duration,
                error: error,
                metadata: metadata
            )
            throw error
        }
    }

    /// Get performance statistics for an operation
    public func getStatistics(for id: String) -> Statistics? {
        guard let metrics = metrics[id],
              !metrics.isEmpty
        else { return nil }

        return calculateAndLogStatistics(id: id, metrics: metrics)
    }

    /// Reset statistics for an operation
    public func resetStatistics(for id: String) {
        let count = metrics[id]?.count ?? 0
        metrics.removeValue(forKey: id)
        logReset(id: id, count: count)
    }

    // MARK: - Private Methods

    private func recordSuccess(
        id: String,
        startTime: Date,
        duration: TimeInterval,
        metadata: [String: String]
    ) async {
        var finalMetadata = metadata
        finalMetadata["status"] = "success"
        finalMetadata["duration"] = formatDuration(duration)

        let metric = Metric(
            id: id,
            startTime: startTime,
            duration: duration,
            metadata: finalMetadata
        )

        await storeMetric(metric)
    }

    private func recordError(
        id: String,
        startTime: Date,
        duration: TimeInterval,
        error: Error,
        metadata: [String: String]
    ) async {
        var finalMetadata = metadata
        finalMetadata["status"] = "error"
        finalMetadata["error"] = String(describing: error)
        finalMetadata["duration"] = formatDuration(duration)

        let metric = Metric(
            id: id,
            startTime: startTime,
            duration: duration,
            metadata: finalMetadata
        )

        await storeMetric(metric)
    }

    private func calculateAndLogStatistics(
        id: String,
        metrics: [Metric]
    ) -> Statistics {
        let durations = metrics.map(\.duration)
        let total = durations.reduce(0, +)
        let count = durations.count

        let stats = Statistics(
            totalDuration: total,
            averageDuration: total / Double(count),
            minDuration: durations.min() ?? 0,
            maxDuration: durations.max() ?? 0,
            sampleCount: count
        )

        logStatistics(id: id, stats: stats)
        return stats
    }

    private func storeMetric(_ metric: Metric) {
        var metrics = metrics[metric.id] ?? []
        metrics.append(metric)
        self.metrics[metric.id] = metrics
        logMetric(metric)
    }

    // MARK: - Logging Methods

    private func logMetric(_ metric: Metric) {
        logger.info(
            "Recorded metric: \(metric.id)",
            metadata: metric.metadata
        )
    }

    private func logStatistics(id: String, stats: Statistics) {
        let metadata: [String: String] = [
            "id": id,
            "total": formatDuration(stats.totalDuration),
            "average": formatDuration(stats.averageDuration),
            "min": formatDuration(stats.minDuration),
            "max": formatDuration(stats.maxDuration),
            "samples": String(stats.sampleCount)
        ]
        logger.info("Retrieved statistics", metadata: metadata)
    }

    private func logReset(id: String, count: Int) {
        let metadata: [String: String] = [
            "id": id,
            "cleared_metrics": String(count)
        ]
        logger.info("Reset statistics", metadata: metadata)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = 3
        return formatter.string(from: NSNumber(value: duration)) ?? String(duration)
    }
}
