@preconcurrency import Foundation

// MARK: - OperationThresholds

/// Represents thresholds for different operation types
public struct OperationThresholds {
    /// Default thresholds for unknown operations
    public static let `default`: OperationThresholds = .init(
        base: PerformanceThresholds(),
        operationSpecific: [
            "backup": PerformanceThresholds(
                maxMemoryUsage: 2 * 1024 * 1024 * 1024, // 2GB
                maxCPUUsage: 90.0,
                minBackupSpeed: 5 * 1024 * 1024, // 5MB/s
                maxOperationDuration: 7_200_000, // 2 hours
                minSuccessRate: 98.0
            ),
            "restore": PerformanceThresholds(
                maxMemoryUsage: 3 * 1024 * 1024 * 1024, // 3GB
                maxCPUUsage: 95.0,
                minBackupSpeed: 10 * 1024 * 1024, // 10MB/s
                maxOperationDuration: 3_600_000, // 1 hour
                minSuccessRate: 99.0
            ),
            "check": PerformanceThresholds(
                maxMemoryUsage: 1024 * 1024 * 1024, // 1GB
                maxCPUUsage: 70.0,
                minBackupSpeed: 0.0,
                maxOperationDuration: 1_800_000, // 30 minutes
                minSuccessRate: 99.9
            )
        ]
    )

    /// Base thresholds for all operations
    public let base: PerformanceThresholds

    /// Operation-specific thresholds
    public let operationSpecific: [String: PerformanceThresholds]

    /// Get thresholds for a specific operation
    /// - Parameter operation: Operation name
    /// - Returns: Thresholds for the operation
    public func thresholdsFor(operation: String) -> PerformanceThresholds {
        operationSpecific[operation] ?? base
    }
}

// MARK: - ExtendedPerformanceMetrics

/// Additional performance metrics for monitoring system behaviour
public struct ExtendedPerformanceMetrics {
    /// Metrics related to Input/Output operations
    public struct IOMetrics {
        /// Number of read operations performed
        public let readOperations: UInt64
        /// Number of write operations performed
        public let writeOperations: UInt64
        /// Total number of bytes read
        public let bytesRead: UInt64
        /// Total number of bytes written
        public let bytesWritten: UInt64

        /// Total number of I/O operations (read + write)
        public var totalOperations: UInt64 { readOperations + writeOperations }
        /// Total number of bytes transferred (read + write)
        public var totalBytesTransferred: UInt64 { bytesRead + bytesWritten }
    }

    /// Metrics related to network activity
    public struct NetworkMetrics {
        /// Total bytes received over the network
        public let bytesReceived: UInt64
        /// Total bytes sent over the network
        public let bytesSent: UInt64
        /// Number of network packets received
        public let packetsReceived: UInt64
        /// Number of network packets sent
        public let packetsSent: UInt64
        /// Count of network errors encountered
        public let errors: UInt64

        /// Total bytes transferred (received + sent)
        public var totalBytesTransferred: UInt64 { bytesReceived + bytesSent }
        /// Total packets transferred (received + sent)
        public var totalPacketsTransferred: UInt64 { packetsReceived + packetsSent }
    }

    /// Metrics related to thread utilisation
    public struct ThreadMetrics {
        /// Total number of threads in the process
        public let totalThreads: Int
        /// Number of currently running threads
        public let runningThreads: Int
        /// Number of threads in waiting state
        public let waitingThreads: Int
        /// Number of threads in blocked state
        public let blockedThreads: Int

        /// Ratio of running threads to total threads
        public var threadUtilisationRatio: Double {
            Double(runningThreads) / Double(totalThreads)
        }
    }

    /// Metrics related to garbage collection performance
    public struct GCMetrics {
        /// Number of garbage collection cycles performed
        public let garbageCollections: UInt64
        /// Total time spent in GC pauses
        public let totalPauseTime: TimeInterval
        /// Average duration of GC pauses
        public let averagePauseTime: TimeInterval
        /// Total size of the heap
        public let heapSize: UInt64
        /// Amount of heap currently in use
        public let heapUsed: UInt64

        /// Ratio of used heap to total heap size
        public var heapUtilisationRatio: Double {
            Double(heapUsed) / Double(heapSize)
        }
    }

    /// I/O performance metrics
    public let ioMetrics: IOMetrics
    /// Network performance metrics
    public let networkMetrics: NetworkMetrics
    /// Thread utilisation metrics
    public let threadMetrics: ThreadMetrics
    /// Garbage collection metrics
    public let garbageCollectionMetrics: GCMetrics
    /// Timestamp when these metrics were collected
    public let metricsCollectionTimestamp: Date

    /// Create metrics snapshot
    /// - Returns: Current metrics
    public static func createMetricsSnapshot() -> ExtendedPerformanceMetrics {
        // In real implementation, this would use system APIs
        // For now, return dummy values
        ExtendedPerformanceMetrics(
            ioMetrics: IOMetrics(
                readOperations: 1000,
                writeOperations: 500,
                bytesRead: 1024 * 1024 * 10,
                bytesWritten: 1024 * 1024 * 5
            ),
            networkMetrics: NetworkMetrics(
                bytesReceived: 1024 * 1024,
                bytesSent: 1024 * 512,
                packetsReceived: 1000,
                packetsSent: 800,
                errors: 0
            ),
            threadMetrics: ThreadMetrics(
                totalThreads: 10,
                runningThreads: 4,
                waitingThreads: 5,
                blockedThreads: 1
            ),
            garbageCollectionMetrics: GCMetrics(
                garbageCollections: 100,
                totalPauseTime: 0.5,
                averagePauseTime: 0.005,
                heapSize: 1024 * 1024 * 100,
                heapUsed: 1024 * 1024 * 60
            ),
            metricsCollectionTimestamp: Date()
        )
    }
}
