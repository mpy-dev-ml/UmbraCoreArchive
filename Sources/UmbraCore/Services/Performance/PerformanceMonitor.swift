@unchecked Sendable
import Foundation

/// Service for monitoring performance metrics
@objc
public class PerformanceMonitor: NSObject {
    // MARK: - Types

    /// Performance metric data structure
    public struct Metric {
        /// Metric identifier
        public let id: String
        /// Start time of the operation
        public let startTime: Date
        /// Duration in seconds
        public let duration: TimeInterval
        /// Additional contextual data
        public let metadata: [String: String]

        /// Initialize with metric values
        public init(
            id: String,
            startTime: Date,
            duration: TimeInterval,
            metadata: [String: String] = [:]
        ) {
            self.id = id
            self.startTime = startTime
            self.duration = duration
            self.metadata = metadata
        }
    }

    /// Performance statistics summary
    public struct Statistics {
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

    private let logger: Logger
    private let queue = DispatchQueue(
        label: "dev.mpy.rBUM.PerformanceMonitor",
        attributes: .concurrent
    )
    private var metrics: [String: [Metric]] = [:]

    // MARK: - Initialization

    /// Initialize performance monitor
    public init(logger: Logger) {
        self.logger = logger
        super.init()
    }

    // MARK: - Public Methods

    /// Track duration of an operation
    public func trackDuration<T>(
        _ id: String,
        metadata: [String: String] = [:],
        operation: () async throws -> T
    ) async rethrows -> T {
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
        queue.sync { [weak self] in
            guard let self,
                  let metrics = metrics[id],
                  !metrics.isEmpty
            else { return nil }

            return calculateAndLogStatistics(id: id, metrics: metrics)
        }
    }

    /// Reset statistics for an operation
    public func resetStatistics(for id: String) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }

            let count = metrics[id]?.count ?? 0
            metrics.removeValue(forKey: id)
            logReset(id: id, count: count)
        }
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

    private func storeMetric(_ metric: Metric) async {
        await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) { [weak self] in
                guard let self else {
                    continuation.resume()
                    return
                }

                var metrics = metrics[metric.id] ?? []
                metrics.append(metric)
                self.metrics[metric.id] = metrics

                logMetric(metric)
                continuation.resume()
            }
        }
    }

    // MARK: - Logging Methods

    private func logMetric(_ metric: Metric) {
        let config = LogConfig(metadata: metric.metadata)
        logger.debug(
            "Recorded metric: \(metric.id)",
            config: config
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
        let config = LogConfig(metadata: metadata)
        logger.debug("Retrieved statistics", config: config)
    }

    private func logReset(id: String, count: Int) {
        let metadata: [String: String] = [
            "id": id,
            "cleared_metrics": String(count)
        ]
        let config = LogConfig(metadata: metadata)
        logger.debug("Reset statistics", config: config)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        String(format: "%.3f", duration)
    }
}

// MARK: - LogConfig

/// Configuration for metric logging
private struct LogConfig {
    let metadata: [String: String]
}
