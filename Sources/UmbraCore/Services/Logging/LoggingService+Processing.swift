import Foundation
import os.log

// MARK: - LoggingService+Processing

public extension LoggingService {
    /// Process and store a log message
    /// - Parameters:
    ///   - level: Log level
    ///   - message: Message to log
    ///   - file: Source file
    ///   - line: Source line
    ///   - function: Source function
    func log(
        level: LogLevel,
        message: String,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) {
        guard isUsable, level >= minimumLevel else { return }

        let entry = createLogEntry(
            level: level,
            message: message,
            file: file,
            line: line,
            function: function
        )

        addEntry(entry)

        let type: OSLogType = switch level {
        case .debug:
            .debug

        case .info:
            .info

        case .warning:
            .error

        case .error, .critical:
            .fault
        }

        os_log(
            .init(stringLiteral: "%{public}@"),
            log: osLogger,
            type: type,
            message
        )
    }

    /// Create a log entry
    /// - Parameters:
    ///   - level: Log level
    ///   - message: Message to log
    ///   - file: Source file
    ///   - line: Source line
    ///   - function: Source function
    /// - Returns: Created log entry
    private func createLogEntry(
        level: LogLevel,
        message: String,
        file: String,
        line: Int,
        function: String
    ) -> LogEntry {
        LogEntry(
            timestamp: Date(),
            level: level,
            message: message,
            file: file,
            line: line,
            function: function
        )
    }

    /// Add an entry to the log store
    /// - Parameter entry: Entry to add
    private func addEntry(_ entry: LogEntry) {
        queue.sync {
            entries.append(entry)
            if entries.count > maxEntries {
                entries.removeFirst()
            }
        }
    }
}
