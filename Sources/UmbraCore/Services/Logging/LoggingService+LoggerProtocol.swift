@preconcurrency import Foundation

// MARK: - LoggingService+LoggerProtocol

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

    func event(
        _ name: String,
        metadata: [String: Any],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let entry = LogEntry(
            level: .info,
            message: "Event - \(name)",
            file: file,
            function: function,
            line: line,
            metadata: metadata.mapValues { "\($0)" }
        )
        addEntry(entry)
    }
}
