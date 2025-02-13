@preconcurrency import Foundation
import os.log

// MARK: - LoggingService+Implementation

public extension LoggingService {
    // MARK: - LoggerProtocol Implementation

    func log(
        level: LogLevel,
        message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard shouldLog(level) else { return }
        processLogMessage(
            level: level,
            message: message,
            file: file,
            function: function,
            line: line
        )
    }

    func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .debug, message: message, file: file, function: function, line: line)
    }

    func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }

    func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .warning, message: message, file: file, function: function, line: line)
    }

    func error(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .error, message: message, file: file, function: function, line: line)
    }

    func critical(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .critical, message: message, file: file, function: function, line: line)
    }

    // MARK: - Private Methods

    internal func shouldLog(_ level: LogLevel) -> Bool {
        level >= minimumLevel
    }

    internal func processLogMessage(
        level: LogLevel,
        message: String,
        file: String,
        function: String,
        line: Int
    ) {
        let entry = LogEntry(
            level: level,
            message: message,
            file: file,
            function: function,
            line: line
        )

        osLogAdapter.log(message: message, level: level)
        addEntry(entry)
    }
}
