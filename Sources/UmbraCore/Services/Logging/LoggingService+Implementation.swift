import Foundation
import os.log
import Logging

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
            message,
            level: level,
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

    // MARK: - Internal Methods
    
    internal func processLogMessage(
        _ message: String,
        level: UmbraLogLevel,
        file: String,
        function: String,
        line: Int
    ) {
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
        
        // Track performance metrics
        if level >= .warning {
            Task {
                await performanceMonitor.trackMetric(
                    type: .logging,
                    value: 1.0,
                    unit: "error"
                )
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func shouldLog(_ level: UmbraLogLevel) -> Bool {
        level.severity >= currentLevel.severity
    }
}
