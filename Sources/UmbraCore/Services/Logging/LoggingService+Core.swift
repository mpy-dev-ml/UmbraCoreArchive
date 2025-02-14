import Foundation
import os.log
import Logging

// MARK: - LoggingService+Core

extension LoggingService: LoggerProtocol {
    func log(
        _ message: String,
        level: UmbraLogLevel,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard level.severity >= currentLevel.severity else { return }

        let entry = LogEntry(
            level: level,
            message: message,
            file: file,
            function: function,
            line: line,
            timestamp: Date()
        )

        Task { @MainActor in
            entries.append(entry)
            if entries.count > maxEntries {
                entries.removeFirst(entries.count - maxEntries)
            }
        }

        // Log to system logger
        os_log(
            "%{public}@",
            log: osLogger,
            type: level.osLogType,
            message
        )
    }

    func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, file: file, function: function, line: line)
    }

    func notice(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .notice, file: file, function: function, line: line)
    }

    func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, file: file, function: function, line: line)
    }

    func error(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, file: file, function: function, line: line)
    }

    func critical(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .critical, file: file, function: function, line: line)
    }

    func fault(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .fault, file: file, function: function, line: line)
    }
}

// MARK: - UmbraLogLevel + OSLogType

extension UmbraLogLevel {
    var osLogType: OSLogType {
        switch self {
        case .trace, .debug:
            return .debug
        case .info:
            return .info
        case .notice:
            return .default
        case .warning:
            return .error
        case .error, .critical, .fault:
            return .fault
        }
    }
}
