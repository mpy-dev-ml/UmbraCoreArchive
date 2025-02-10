/// Service for monitoring performance metrics
@objc
public class PerformanceMonitor: NSObject {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize performance monitor
    /// - Parameter logger: Logger for performance events
    public init(logger: Logger) {
        self.logger = logger
        super.init()
    }

    // MARK: Public

    // MARK: - Types

    /// Performance metric
    public struct Metric {
        // MARK: Lifecycle

        /// Initialize with values
        /// - Parameters:
        ///   - id: Metric identifier
        ///   - startTime: Start time
        ///   - duration: Duration in seconds
        ///   - metadata: Additional metadata
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

        // MARK: Public

        /// Metric identifier
        public let id: String
        /// Start time
        public let startTime: Date
        /// Duration in seconds
        public let duration: TimeInterval
        /// Additional metadata
        public let metadata: [String: String]
    }

    /// Performance statistics
    public struct Statistics {
        // MARK: Lifecycle

        /// Initialize with values
        /// - Parameters:
        ///   - totalDuration: Total duration in seconds
        ///   - averageDuration: Average duration in seconds
        ///   - minDuration: Minimum duration in seconds
        ///   - maxDuration: Maximum duration in seconds
        ///   - sampleCount: Number of samples
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

        // MARK: Public

        /// Total duration in seconds
        public let totalDuration: TimeInterval
        /// Average duration in seconds
        public let averageDuration: TimeInterval
        /// Minimum duration in seconds
        public let minDuration: TimeInterval
        /// Maximum duration in seconds
        public let maxDuration: TimeInterval
        /// Number of samples
        public let sampleCount: Int
    }

    // MARK: - Public Methods

    /// Track duration of an operation
    /// - Parameters:
    ///   - id: Operation identifier
    ///   - metadata: Additional metadata
    ///   - operation: Operation to track
    /// - Returns: Operation result
    /// - Throws: Operation error
    public func trackDuration<T>(
        _ id: String,
        metadata: [String: String] = [:],
        operation: () async throws -> T
    ) async rethrows -> T {
        let startTime = Date()
        var finalMetadata = metadata

        do {
            let result = try await operation()
            let duration = Date().timeIntervalSince(startTime)

            finalMetadata["status"] = "success"
            finalMetadata["duration"] = String(format: "%.3f", duration)

            let metric = Metric(
                id: id,
                startTime: startTime,
                duration: duration,
                metadata: finalMetadata
            )
            recordMetric(metric)

            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime)

            finalMetadata["status"] = "error"
            finalMetadata["error"] = String(describing: error)
            finalMetadata["duration"] = String(format: "%.3f", duration)

            let metric = Metric(
                id: id,
                startTime: startTime,
                duration: duration,
                metadata: finalMetadata
            )
            recordMetric(metric)

            throw error
        }
    }

    /// Get statistics for operation
    /// - Parameter id: Operation identifier
    /// - Returns: Performance statistics
    public func getStatistics(
        for id: String
    ) -> Statistics? {
        queue.sync { [weak self] in
            guard let self,
                  let metrics = metrics[id],
                  !metrics.isEmpty
            else {
                return nil
            }

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

            let metadata: [String: String] = [
                "id": id,
                "total": String(format: "%.3f", stats.totalDuration),
                "average": String(format: "%.3f", stats.averageDuration),
                "samples": String(stats.sampleCount),
            ]
            let config = LogConfig(metadata: metadata)
            logger.debug("Retrieved performance statistics", config: config)

            return stats
        }
    }

    /// Reset statistics for operation
    /// - Parameter id: Operation identifier
    public func resetStatistics(
        for id: String
    ) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else {
                return
            }

            let metadata: [String: String] = [
                "id": id,
                "metrics_count": String(
                    metrics[id]?.count ?? 0
                ),
            ]
            let config = LogConfig(metadata: metadata)

            metrics.removeValue(forKey: id)
            logger.debug(
                "Reset performance statistics",
                config: config
            )
        }
    }

    // MARK: Private

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.rBUM.PerformanceMonitor",
        attributes: .concurrent
    )

    /// Active metrics
    private var metrics: [String: [Metric]] = [:]

    /// Logger for performance events
    private let logger: Logger

    // MARK: - Private Methods

    /// Record performance metric
    /// - Parameter metric: Metric to record
    private func recordMetric(_ metric: Metric) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else {
                return
            }

            var metrics = metrics[metric.id] ?? []
            metrics.append(metric)
            self.metrics[metric.id] = metrics

            var metadata = metric.metadata
            metadata["id"] = metric.id
            metadata["duration"] = String(
                format: "%.3f",
                metric.duration
            )

            let config = LogConfig(metadata: metadata)
            logger.debug(
                "Recorded performance metric",
                config: config
            )
        }
    }
}
