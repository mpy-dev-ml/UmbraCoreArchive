@preconcurrency import Foundation

// MARK: - LoggingService+EntryManagement

public extension LoggingService {
    // MARK: - Public Methods

    /// Get log entries filtered by criteria
    /// - Parameters:
    ///   - level: Optional minimum log level filter
    ///   - startDate: Optional start date filter
    ///   - endDate: Optional end date filter
    /// - Returns: Array of filtered log entries
    func getEntries(
        level: LogLevel? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> [LogEntry] {
        queue.sync {
            var filteredEntries = entries

            if let level {
                filteredEntries = filteredEntries.filter { $0.level >= level }
            }

            if let startDate {
                filteredEntries = filteredEntries.filter { $0.timestamp >= startDate }
            }

            if let endDate {
                filteredEntries = filteredEntries.filter { $0.timestamp <= endDate }
            }

            return filteredEntries
        }
    }

    /// Clear all log entries
    func clearEntries() {
        queue.sync {
            entries.removeAll()
        }
    }

    /// Get the number of stored entries
    /// - Returns: Current entry count
    func entryCount() -> Int {
        queue.sync {
            entries.count
        }
    }

    // MARK: - Internal Methods

    /// Add a new log entry
    /// - Parameter entry: The entry to add
    internal func addEntry(_ entry: LogEntry) {
        queue.sync {
            entries.append(entry)
            trimEntriesIfNeeded()
        }
    }

    // MARK: - Private Methods

    private func trimEntriesIfNeeded() {
        if entries.count > maxEntries {
            let overflow = entries.count - maxEntries
            entries.removeFirst(overflow)
        }
    }
}
