import Foundation

/// Service for monitoring system resources
public final class ResourceMonitor: BaseSandboxedService {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with thresholds and logger
    /// - Parameters:
    ///   - thresholds: Resource thresholds
    ///   - maxSnapshots: Maximum number of snapshots to keep
    ///   - logger: Logger for tracking operations
    public init(
        thresholds: ResourceThresholds = ResourceThresholds(),
        maxSnapshots: Int = 1_000,
        logger: LoggerProtocol
    ) {
        self.thresholds = thresholds
        self.maxSnapshots = maxSnapshots
        super.init(logger: logger)
    }

    // MARK: Public

    // MARK: - Types

    /// Resource usage snapshot
    public struct ResourceSnapshot: Codable {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            memoryUsage: UInt64,
            cpuUsage: Double,
            diskUsage: UInt64,
            diskAvailable: UInt64,
            networkThroughput: Double,
            timestamp: Date = Date()
        ) {
            self.memoryUsage = memoryUsage
            self.cpuUsage = cpuUsage
            self.diskUsage = diskUsage
            self.diskAvailable = diskAvailable
            self.networkThroughput = networkThroughput
            self.timestamp = timestamp
        }

        // MARK: Public

        /// Memory usage in bytes
        public let memoryUsage: UInt64
        /// CPU usage percentage (0-100)
        public let cpuUsage: Double
        /// Disk space usage in bytes
        public let diskUsage: UInt64
        /// Available disk space in bytes
        public let diskAvailable: UInt64
        /// Network throughput in bytes/second
        public let networkThroughput: Double
        /// Timestamp of snapshot
        public let timestamp: Date
    }

    /// Resource usage thresholds
    public struct ResourceThresholds {
        // MARK: Lifecycle

        /// Initialize with default values
        public init(
            memoryThreshold: UInt64 = 1_000_000_000, // 1 GB
            cpuThreshold: Double = 80.0, // 80%
            diskThreshold: UInt64 = 1_000_000_000, // 1 GB
            networkThreshold: Double = 1_000_000 // 1 MB/s
        ) {
            self.memoryThreshold = memoryThreshold
            self.cpuThreshold = cpuThreshold
            self.diskThreshold = diskThreshold
            self.networkThreshold = networkThreshold
        }

        // MARK: Public

        /// Memory usage threshold in bytes
        public var memoryThreshold: UInt64
        /// CPU usage threshold percentage (0-100)
        public var cpuThreshold: Double
        /// Disk space threshold in bytes
        public var diskThreshold: UInt64
        /// Network throughput threshold in bytes/second
        public var networkThreshold: Double
    }

    // MARK: - Public Methods

    /// Take a resource snapshot
    /// - Returns: Current resource snapshot
    /// - Throws: ResourceError if snapshot fails
    public func takeSnapshot() async throws -> ResourceSnapshot {
        try validateUsable(for: "takeSnapshot")

        let snapshot = try await captureResourceUsage()

        queue.async(flags: .barrier) {
            self.snapshots.append(snapshot)

            // Trim old snapshots if needed
            if self.snapshots.count > self.maxSnapshots {
                self.snapshots.removeFirst(
                    self.snapshots.count - self.maxSnapshots
                )
            }

            self.checkThresholds(snapshot)
        }

        return snapshot
    }

    /// Get resource snapshots
    /// - Parameters:
    ///   - startDate: Optional start date filter
    ///   - endDate: Optional end date filter
    /// - Returns: Array of snapshots
    public func getSnapshots(
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> [ResourceSnapshot] {
        queue.sync {
            var filtered = snapshots

            if let startDate {
                filtered = filtered.filter { $0.timestamp >= startDate }
            }

            if let endDate {
                filtered = filtered.filter { $0.timestamp <= endDate }
            }

            return filtered
        }
    }

    /// Update resource thresholds
    /// - Parameter thresholds: New thresholds
    public func updateThresholds(_ thresholds: ResourceThresholds) {
        queue.async(flags: .barrier) {
            self.thresholds = thresholds

            self.logger.info(
                """
                Updated resource thresholds:
                Memory: \(thresholds.memoryThreshold) bytes
                CPU: \(thresholds.cpuThreshold)%
                Disk: \(thresholds.diskThreshold) bytes
                Network: \(thresholds.networkThreshold) bytes/s
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Clear all snapshots
    public func clearSnapshots() {
        queue.async(flags: .barrier) {
            self.snapshots.removeAll()

            self.logger.debug(
                "Cleared all resource snapshots",
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    // MARK: Private

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.resources",
        qos: .utility,
        attributes: .concurrent
    )

    /// Resource thresholds
    private var thresholds: ResourceThresholds

    /// Resource snapshots
    private var snapshots: [ResourceSnapshot] = []

    /// Maximum number of snapshots to keep
    private let maxSnapshots: Int

    // MARK: - Private Methods

    /// Capture current resource usage
    private func captureResourceUsage() async throws -> ResourceSnapshot {
        // Implementation would use platform-specific APIs
        // This is a placeholder that returns dummy data
        ResourceSnapshot(
            memoryUsage: 500_000_000,
            cpuUsage: 25.0,
            diskUsage: 10_000_000_000,
            diskAvailable: 100_000_000_000,
            networkThroughput: 100_000
        )
    }

    /// Check resource thresholds
    private func checkThresholds(_ snapshot: ResourceSnapshot) {
        if snapshot.memoryUsage > thresholds.memoryThreshold {
            logger.warning(
                """
                Memory usage exceeded threshold:
                Current: \(snapshot.memoryUsage) bytes
                Threshold: \(thresholds.memoryThreshold) bytes
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }

        if snapshot.cpuUsage > thresholds.cpuThreshold {
            logger.warning(
                """
                CPU usage exceeded threshold:
                Current: \(snapshot.cpuUsage)%
                Threshold: \(thresholds.cpuThreshold)%
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }

        if snapshot.diskAvailable < thresholds.diskThreshold {
            logger.warning(
                """
                Available disk space below threshold:
                Current: \(snapshot.diskAvailable) bytes
                Threshold: \(thresholds.diskThreshold) bytes
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }

        if snapshot.networkThroughput > thresholds.networkThreshold {
            logger.warning(
                """
                Network throughput exceeded threshold:
                Current: \(snapshot.networkThroughput) bytes/s
                Threshold: \(thresholds.networkThreshold) bytes/s
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }
}
