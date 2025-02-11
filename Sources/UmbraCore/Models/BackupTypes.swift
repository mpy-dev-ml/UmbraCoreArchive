import Foundation

// MARK: - Types

/// Represents filter criteria for snapshot operations in a backup repository.
/// Used to filter snapshots based on hostname and tags.
public struct SnapshotFilter: Sendable {
    // MARK: - Properties

    /// The hostname to filter snapshots by
    /// If nil, snapshots from all hosts are included
    public let hostname: String?

    /// The tags to filter snapshots by
    /// If nil, no tag filtering is applied
    /// If provided, only snapshots containing all specified tags are included
    public let tags: [String]?

    // MARK: - Initialisation

    /// Creates a new snapshot filter with optional criteria
    /// - Parameters:
    ///   - hostname: Optional hostname to filter by
    ///   - tags: Optional array of tags to filter by
    public init(
        hostname: String? = nil,
        tags: [String]? = nil
    ) {
        self.hostname = hostname
        self.tags = tags
    }
}

// MARK: - Backup Types

/// Namespace for backup-related types
public enum Backup {
    /// Represents the current progress of a backup operation
    /// Provides detailed information about files processed and estimated completion
    public struct Progress: Sendable {
        // MARK: - Properties

        /// Total number of files to process
        public let totalFiles: Int

        /// Number of files processed so far
        public let processedFiles: Int

        /// Current processing speed in bytes per second
        public let speed: Int64

        /// Total number of bytes processed
        public let processedBytes: Int64

        /// Estimated time remaining in seconds
        public let estimatedTimeRemaining: TimeInterval?

        // MARK: - Computed Properties

        /// Percentage of files processed (0-100)
        public var progressPercentage: Double {
            guard totalFiles > 0 else { return 0 }
            return Double(processedFiles) / Double(totalFiles) * 100
        }

        /// Formatted speed string (e.g., "1.2 MB/s")
        public var formattedSpeed: String {
            ByteCountFormatter.string(
                fromByteCount: speed,
                countStyle: .binary
            ) + "/s"
        }

        // MARK: - Initialisation

        /// Creates a new backup progress instance
        /// - Parameters:
        ///   - totalFiles: Total files to process
        ///   - processedFiles: Files processed so far
        ///   - speed: Current speed in bytes/second
        ///   - processedBytes: Total bytes processed
        ///   - estimatedTimeRemaining: Estimated seconds remaining
        public init(
            totalFiles: Int,
            processedFiles: Int,
            speed: Int64,
            processedBytes: Int64,
            estimatedTimeRemaining: TimeInterval? = nil
        ) {
            self.totalFiles = totalFiles
            self.processedFiles = processedFiles
            self.speed = speed
            self.processedBytes = processedBytes
            self.estimatedTimeRemaining = estimatedTimeRemaining
        }
    }
}
