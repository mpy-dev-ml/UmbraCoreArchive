@preconcurrency import Foundation

// MARK: - LoggingService+Filtering

public extension LoggingService {
    /// Get filtered log entries
    /// - Parameters:
    ///   - level: Minimum log level
    ///   - startDate: Start date for filtering
    ///   - endDate: End date for filtering
    /// - Returns: Filtered log entries
    func getEntries(
        level: LogLevel = .debug,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> [LogEntry] {
        queue.sync {
            entries
                .filter { entry in
                    applyFilters(
                        entry,
                        level: level,
                        startDate: startDate,
                        endDate: endDate
                    )
                }
        }
    }

    /// Apply filters to log entry
    /// - Parameters:
    ///   - entry: Entry to filter
    ///   - level: Minimum log level
    ///   - startDate: Start date for filtering
    ///   - endDate: End date for filtering
    /// - Returns: Whether entry matches filters
    private func applyFilters(
        _ entry: LogEntry,
        level: LogLevel,
        startDate: Date?,
        endDate: Date?
    ) -> Bool {
        // Check log level
        guard entry.level >= level else {
            return false
        }

        // Check date range
        if let startDate {
            guard entry.timestamp >= startDate else {
                return false
            }
        }

        if let endDate {
            guard entry.timestamp <= endDate else {
                return false
            }
        }

        return true
    }
}
