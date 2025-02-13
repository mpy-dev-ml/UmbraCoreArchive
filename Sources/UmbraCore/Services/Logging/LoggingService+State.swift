@preconcurrency import Foundation

// MARK: - LoggingService+State

public extension LoggingService {
    // MARK: - Public Methods

    /// Update the minimum log level
    /// - Parameter level: New minimum log level
    func updateMinimumLevel(_ level: LogLevel) {
        queue.async(flags: .barrier) {
            self.minimumLevel = level
        }
    }

    /// Get the current minimum log level
    /// - Returns: Current minimum log level
    func getMinimumLevel() -> LogLevel {
        queue.sync {
            minimumLevel
        }
    }

    /// Get the maximum number of entries allowed
    /// - Returns: Maximum number of entries
    func getMaxEntries() -> Int {
        queue.sync {
            maxEntries
        }
    }

    /// Get all current log entries
    /// - Returns: Array of log entries
    func getAllEntries() -> [LogEntry] {
        queue.sync {
            entries
        }
    }

    /// Clear all log entries
    func clearEntries() {
        queue.async(flags: .barrier) {
            entries.removeAll()
        }
    }
}
