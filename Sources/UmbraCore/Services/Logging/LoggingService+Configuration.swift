import Foundation

// MARK: - LoggingService+Configuration

public extension LoggingService {
    // MARK: - Types

    /// Configuration for the logging service
    struct Configuration {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            subsystem: String = "dev.mpy.umbracore",
            category: String = "default",
            minimumLevel: LogLevel = .debug,
            maxEntries: Int = 10000
        ) {
            self.subsystem = subsystem
            self.category = category
            self.minimumLevel = minimumLevel
            self.maxEntries = maxEntries
        }

        // MARK: Public

        /// Subsystem identifier
        public let subsystem: String

        /// Category identifier
        public let category: String

        /// Minimum log level
        public let minimumLevel: LogLevel

        /// Maximum number of entries to keep
        public let maxEntries: Int
    }
}
