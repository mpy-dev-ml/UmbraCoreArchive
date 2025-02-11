import Foundation
import os.log

// MARK: - LoggingService+Core

public extension LoggingService {
    // MARK: - LoggerProtocol Implementation

    func log(
        level: LogLevel,
        message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard level >= minimumLevel else { return }

        let entry = LogEntry(
            level: level,
            message: message,
            file: file,
            function: function,
            line: line
        )

        addEntry(entry)
        osLogAdapter.log(message: message, level: level)
    }

    func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.debug, message, file: file, function: function, line: line)
    }

    func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.info, message, file: file, function: function, line: line)
    }

    func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.warning, message, file: file, function: function, line: line)
    }

    func error(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.error, message, file: file, function: function, line: line)
    }

    func critical(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.critical, message, file: file, function: function, line: line)
    }
}
