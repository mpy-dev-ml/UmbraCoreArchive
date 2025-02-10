/// Service for monitoring performance metrics
@objc
public class PerformanceMonitor: NSObject {
    // MARK: - Types

    /// Performance metric
    public struct Metric {
        /// Metric identifier
        public let id: String
        /// Start time
        public let startTime: Date
        /// Duration in seconds
        public let duration: TimeInterval
        /// Additional metadata
        public let metadata: [String: String]

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
    }

    /// Performance statistics
    public struct Statistics {
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
    }

    // MARK: - Properties

    /// Queue for synchronizing operations
    private let queue = DispatchQueue(
        label: "dev.mpy.rBUM.PerformanceMonitor",
        attributes: .concurrent
    )

    /// Active metrics
    private var metrics: [String: [Metric]] = [:]

    /// Logger for performance events
    private let logger: Logger

    // MARK: - Initialization

    /// Initialize performance monitor
    /// - Parameter logger: Logger for performance events
    public init(logger: Logger) {
        self.logger = logger
        super.init()
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
        
        do {
            let result = try await operation()
            let duration = Date().timeIntervalSince(startTime)
            
            recordMetric(
                Metric(
                    id: id,
                    startTime: startTime,
                    duration: duration,
                    metadata: metadata
                )
            )
            
            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            recordMetric(
                Metric(
                    id: id,
                    startTime: startTime,
                    duration: duration,
                    metadata: [
                        "error": String(describing: error)
                    ]
                )
            )
            
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
            guard let self = self else { return nil }
            guard let metrics = self.metrics[id] else { return nil }
            
            let durations = metrics.map { $0.duration }
            let total = durations.reduce(0, +)
            let count = durations.count
            
            guard count > 0 else { return nil }
            
            return Statistics(
                totalDuration: total,
                averageDuration: total / Double(count),
                minDuration: durations.min() ?? 0,
                maxDuration: durations.max() ?? 0,
                sampleCount: count
            )
        }
    }

    /// Reset statistics for operation
    /// - Parameter id: Operation identifier
    public func resetStatistics(
        for id: String
    ) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            self.metrics.removeValue(forKey: id)
            
            self.logger.debug(
                "Reset performance statistics",
                config: LogConfig(
                    metadata: [
                        "id": id
                    ]
                )
            )
        }
    }

    // MARK: - Private Methods

    /// Record performance metric
    /// - Parameter metric: Metric to record
    private func recordMetric(_ metric: Metric) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            var metrics = self.metrics[metric.id] ?? []
            metrics.append(metric)
            self.metrics[metric.id] = metrics
            
            self.logger.debug(
                "Recorded performance metric",
                config: LogConfig(
                    metadata: [
                        "id": metric.id,
                        "duration": String(format: "%.3f", metric.duration)
                    ]
                )
            )
        }
    }
}
