@preconcurrency import Foundation

/// Service for tracking persistence metrics
public final class PersistenceMetrics: BaseSandboxedService {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - baseURL: Base directory URL
    ///   - performanceMonitor: Performance monitor
    ///   - logger: Logger for tracking operations
    public init(
        baseURL: URL,
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        self.baseURL = baseURL
        self.performanceMonitor = performanceMonitor
        super.init(logger: logger)
    }

    // MARK: Public

    // MARK: - Types

    /// Storage metrics for persistence operations
    @frozen
    public struct PersistenceOperationMetrics {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            baseMetrics: OperationMetrics,
            storageMetrics: StorageMetrics
        ) {
            self.baseMetrics = baseMetrics
            self.storageMetrics = storageMetrics
        }

        // MARK: Public

        /// Base operation metrics
        public let baseMetrics: OperationMetrics

        /// Storage-specific metrics
        public let storageMetrics: StorageMetrics
    }

    /// Storage metrics
    public struct StorageMetrics {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            totalSize: Int64,
            fileCount: Int,
            averageFileSize: Double,
            directoryUsage: [String: Int64]
        ) {
            self.totalSize = totalSize
            self.fileCount = fileCount
            self.averageFileSize = averageFileSize
            self.directoryUsage = directoryUsage
        }

        // MARK: Public

        /// Total size in bytes
        public let totalSize: Int64

        /// Number of files
        public let fileCount: Int

        /// Average file size
        public let averageFileSize: Double

        /// Space usage by directory
        public let directoryUsage: [String: Int64]
    }

    /// Operation metrics
    public struct OperationMetrics {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            operationCounts: [String: Int],
            averageDurations: [String: TimeInterval],
            errorCounts: [String: Int]
        ) {
            self.operationCounts = operationCounts
            self.averageDurations = averageDurations
            self.errorCounts = errorCounts
        }

        // MARK: Public

        /// Operation counts
        public let operationCounts: [String: Int]

        /// Average operation durations
        public let averageDurations: [String: TimeInterval]

        /// Error counts
        public let errorCounts: [String: Int]
    }

    // MARK: - Public Methods

    /// Get storage metrics
    /// - Returns: Storage metrics
    /// - Throws: Error if metrics collection fails
    public func getStorageMetrics() async throws -> StorageMetrics {
        try validateUsable(for: "getStorageMetrics")

        return try await performanceMonitor.trackDuration("persistence.metrics.storage") {
            var totalSize: Int64 = 0
            var fileCount = 0
            var directoryUsage: [String: Int64] = [:]

            // Get directory contents
            let enumerator = FileManager.default.enumerator(
                at: baseURL,
                includingPropertiesForKeys: [.fileSizeKey],
                options: [.skipsHiddenFiles]
            )

            while let url = enumerator?.nextObject() as? URL {
                let attributes = try url.resourceValues(forKeys: [.fileSizeKey])
                if let size = attributes.fileSize {
                    totalSize += Int64(size)
                    fileCount += 1

                    // Update directory usage
                    let directory = url.deletingLastPathComponent().lastPathComponent
                    directoryUsage[directory, default: 0] += Int64(size)
                }
            }

            let averageFileSize = fileCount > 0
                ? Double(totalSize) / Double(fileCount)
                : 0.0

            // Create metrics
            let metrics = StorageMetrics(
                totalSize: totalSize,
                fileCount: fileCount,
                averageFileSize: averageFileSize,
                directoryUsage: directoryUsage
            )

            // Log metrics
            logger.debug(
                """
                Storage metrics:
                Size: \(totalSize) bytes
                Files: \(fileCount)
                Average: \(averageFileSize) bytes
                """,
                file: #file,
                function: #function,
                line: #line
            )

            return metrics
        }
    }

    /// Get metrics for persistence operations
    /// - Returns: Metrics for persistence operations
    public func getOperationMetrics() -> PersistenceOperationMetrics {
        queue.sync {
            // Calculate average durations
            var averageDurations: [String: TimeInterval] = [:]

            for (operation, durations) in operationDurations {
                let average = durations.reduce(0, +) / Double(durations.count)
                averageDurations[operation] = average
            }

            // Create metrics
            let baseMetrics = OperationMetrics(
                operationCounts: operationCounts,
                averageDurations: averageDurations,
                errorCounts: errorCounts
            )

            let storageMetrics = StorageMetrics(
                totalSize: 0,
                fileCount: 0,
                averageFileSize: 0,
                directoryUsage: [:]
            )

            let metrics = PersistenceOperationMetrics(
                baseMetrics: baseMetrics,
                storageMetrics: storageMetrics
            )

            // Log metrics
            logger.debug(
                """
                Operation metrics:
                Operations: \(operationCounts)
                Durations: \(averageDurations)
                Errors: \(errorCounts)
                """,
                file: #file,
                function: #function,
                line: #line
            )

            return metrics
        }
    }

    /// Track operation
    /// - Parameters:
    ///   - operation: Operation name
    ///   - duration: Operation duration
    public func trackOperation(
        _ operation: String,
        duration: TimeInterval
    ) {
        queue.async(flags: .barrier) {
            self.operationCounts[operation, default: 0] += 1
            self.operationDurations[operation, default: []].append(duration)
        }
    }

    /// Track error
    /// - Parameter operation: Operation name
    public func trackError(
        _ operation: String
    ) {
        queue.async(flags: .barrier) {
            self.errorCounts[operation, default: 0] += 1
        }
    }

    /// Reset metrics
    public func resetMetrics() {
        queue.async(flags: .barrier) {
            self.operationCounts.removeAll()
            self.operationDurations.removeAll()
            self.errorCounts.removeAll()

            self.logger.debug(
                "Reset persistence metrics",
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    // MARK: Private

    /// Base directory URL
    private let baseURL: URL

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.persistence.metrics",
        qos: .utility,
        attributes: .concurrent
    )

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    /// Operation counts
    private var operationCounts: [String: Int] = [:]

    /// Operation durations
    private var operationDurations: [String: [TimeInterval]] = [:]

    /// Error counts
    private var errorCounts: [String: Int] = [:]
}
