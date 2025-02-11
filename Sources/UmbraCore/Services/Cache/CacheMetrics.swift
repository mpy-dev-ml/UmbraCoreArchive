import Foundation

/// Service for tracking cache metrics
public final class CacheMetrics: BaseSandboxedService {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - directoryURL: Cache directory URL
    ///   - performanceMonitor: Performance monitor
    ///   - logger: Logger for tracking operations
    public init(
        directoryURL: URL,
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        self.directoryURL = directoryURL
        self.performanceMonitor = performanceMonitor
        super.init(logger: logger)
    }

    // MARK: Public

    // MARK: - Types

    /// Cache metrics
    public struct Metrics {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            totalSize: Int64,
            entryCount: Int,
            hitRate: Double,
            missRate: Double,
            averageEntrySize: Double,
            averageEntryAge: TimeInterval
        ) {
            self.totalSize = totalSize
            self.entryCount = entryCount
            self.hitRate = hitRate
            self.missRate = missRate
            self.averageEntrySize = averageEntrySize
            self.averageEntryAge = averageEntryAge
        }

        // MARK: Public

        /// Total cache size in bytes
        public let totalSize: Int64

        /// Number of entries
        public let entryCount: Int

        /// Hit rate
        public let hitRate: Double

        /// Miss rate
        public let missRate: Double

        /// Average entry size
        public let averageEntrySize: Double

        /// Average entry age
        public let averageEntryAge: TimeInterval
    }

    // MARK: - Public Methods

    /// Track cache hit
    public func trackHit() {
        queue.async(flags: .barrier) {
            self.hitCount += 1
        }
    }

    /// Track cache miss
    public func trackMiss() {
        queue.async(flags: .barrier) {
            self.missCount += 1
        }
    }

    /// Get current metrics
    /// - Returns: Cache metrics
    /// - Throws: Error if operation fails
    public func getMetrics() async throws -> Metrics {
        try validateUsable(for: "getMetrics")

        return try await performanceMonitor.trackDuration("cache.metrics") {
            let contents = try getCacheContents()
            let (totalSize, totalAge) = try calculateTotalSizeAndAge(for: contents)
            let metrics = try createMetrics(
                contents: contents,
                totalSize: totalSize,
                totalAge: totalAge
            )

            await logMetrics(metrics)
            await trackPerformanceMetrics(metrics)

            return metrics
        }
    }

    /// Reset metrics
    public func resetMetrics() {
        queue.async(flags: .barrier) {
            self.hitCount = 0
            self.missCount = 0
        }

        logger.debug(
            "Reset cache metrics",
            file: #file,
            function: #function,
            line: #line
        )
    }

    // MARK: Private

    /// Cache directory URL
    private let directoryURL: URL

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.cache.metrics",
        qos: .utility,
        attributes: .concurrent
    )

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    /// Hit count
    private var hitCount: Int = 0

    /// Miss count
    private var missCount: Int = 0

    // MARK: - Private Methods

    /// Get contents of cache directory
    /// - Returns: Array of URLs for cache entries
    /// - Throws: FileManager errors
    private func getCacheContents() throws -> [URL] {
        try FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.fileSizeKey, .creationDateKey]
        )
    }

    /// Calculate total size and age for cache entries
    /// - Parameter contents: Array of cache entry URLs
    /// - Returns: Tuple of total size and age
    /// - Throws: FileManager errors
    private func calculateTotalSizeAndAge(
        for contents: [URL]
    ) throws -> (size: Int64, age: TimeInterval) {
        var totalSize: Int64 = 0
        var totalAge: TimeInterval = 0

        for url in contents {
            let attributes = try FileManager.default.attributesOfItem(
                atPath: url.path
            )

            let size = attributes[.size] as? Int64 ?? 0
            totalSize += size

            if let creationDate = attributes[.creationDate] as? Date {
                totalAge += Date().timeIntervalSince(creationDate)
            }
        }

        return (totalSize, totalAge)
    }

    /// Create metrics from cache data
    /// - Parameters:
    ///   - contents: Array of cache entry URLs
    ///   - totalSize: Total size of cache entries
    ///   - totalAge: Total age of cache entries
    /// - Returns: Calculated metrics
    private func createMetrics(
        contents: [URL],
        totalSize: Int64,
        totalAge: TimeInterval
    ) -> Metrics {
        let entryCount = contents.count
        let totalRequests = hitCount + missCount

        let hitRate = totalRequests > 0
            ? Double(hitCount) / Double(totalRequests)
            : 0.0

        let missRate = totalRequests > 0
            ? Double(missCount) / Double(totalRequests)
            : 0.0

        let averageEntrySize = entryCount > 0
            ? Double(totalSize) / Double(entryCount)
            : 0.0

        let averageEntryAge = entryCount > 0
            ? totalAge / Double(entryCount)
            : 0.0

        return Metrics(
            totalSize: totalSize,
            entryCount: entryCount,
            hitRate: hitRate,
            missRate: missRate,
            averageEntrySize: averageEntrySize,
            averageEntryAge: averageEntryAge
        )
    }

    /// Log metrics to logger
    /// - Parameter metrics: Metrics to log
    private func logMetrics(_ metrics: Metrics) {
        logger.debug(
            """
            Cache metrics:
            Size: \(metrics.totalSize) bytes
            Entries: \(metrics.entryCount)
            Hit Rate: \(metrics.hitRate * 100)%
            Miss Rate: \(metrics.missRate * 100)%
            Avg Size: \(metrics.averageEntrySize) bytes
            Avg Age: \(metrics.averageEntryAge)s
            """,
            file: #file,
            function: #function,
            line: #line
        )
    }

    /// Track performance metrics
    /// - Parameter metrics: Metrics to track
    private func trackPerformanceMetrics(_ metrics: Metrics) async {
        try? await performanceMonitor.trackMetric(
            "cache.size",
            value: Double(metrics.totalSize)
        )
        try? await performanceMonitor.trackMetric(
            "cache.entries",
            value: Double(metrics.entryCount)
        )
        try? await performanceMonitor.trackMetric(
            "cache.hit_rate",
            value: metrics.hitRate
        )
        try? await performanceMonitor.trackMetric(
            "cache.miss_rate",
            value: metrics.missRate
        )
    }
}
