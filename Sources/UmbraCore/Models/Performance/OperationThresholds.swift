import Foundation

// MARK: - OperationThresholds

/// Represents thresholds for different operation types
@frozen
public struct OperationThresholds: Codable, Sendable {
    /// Default thresholds
    public static let `default` = OperationThresholds(
        backup: 3600,    // 1 hour
        restore: 7200,   // 2 hours
        verify: 1800,    // 30 minutes
        prune: 900,      // 15 minutes
        check: 600       // 10 minutes
    )
    
    /// Backup operation threshold (seconds)
    public let backup: TimeInterval
    
    /// Restore operation threshold (seconds)
    public let restore: TimeInterval
    
    /// Verify operation threshold (seconds)
    public let verify: TimeInterval
    
    /// Prune operation threshold (seconds)
    public let prune: TimeInterval
    
    /// Check operation threshold (seconds)
    public let check: TimeInterval
    
    /// Initialize with custom thresholds
    /// - Parameters:
    ///   - backup: Backup threshold
    ///   - restore: Restore threshold
    ///   - verify: Verify threshold
    ///   - prune: Prune threshold
    ///   - check: Check threshold
    public init(
        backup: TimeInterval,
        restore: TimeInterval,
        verify: TimeInterval,
        prune: TimeInterval,
        check: TimeInterval
    ) {
        self.backup = backup
        self.restore = restore
        self.verify = verify
        self.prune = prune
        self.check = check
    }
    
    /// Get threshold for operation type
    /// - Parameter type: Operation type
    /// - Returns: Threshold in seconds
    public func threshold(for type: OperationType) -> TimeInterval {
        switch type {
        case .backup:
            return backup
        case .restore:
            return restore
        case .verify:
            return verify
        case .prune:
            return prune
        case .check:
            return check
        }
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
    public static func createMetricsSnapshot() -> Self {
        // In real implementation, this would use system APIs
        // For now, return dummy values
        Self(
            ioMetrics: IOMetrics(
                readOperations: 1_000,
                writeOperations: 500,
                bytesRead: 1_024 * 1_024 * 10,
                bytesWritten: 1_024 * 1_024 * 5
            ),
            networkMetrics: NetworkMetrics(
                bytesReceived: 1_024 * 1_024,
                bytesSent: 1_024 * 512,
                packetsReceived: 1_000,
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
                heapSize: 1_024 * 1_024 * 100,
                heapUsed: 1_024 * 1_024 * 60
            ),
            metricsCollectionTimestamp: Date()
        )
    }
}
