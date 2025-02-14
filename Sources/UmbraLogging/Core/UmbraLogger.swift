import Foundation
import Logging

/// Protocol defining the interface for logging.
@preconcurrency
public protocol UmbraLogger: Sendable {
    /// Log a message with the specified level.
    /// - Parameters:
    ///   - level: The log level.
    ///   - message: The message to log.
    ///   - metadata: Optional metadata.
    ///   - source: The source file where the log was created.
    ///   - function: The function where the log was created.
    ///   - line: The line number where the log was created.
    func log(
        level: Logging.Logger.Level,
        message: String,
        metadata: Logging.Logger.Metadata?,
        source: String?,
        function: String?,
        line: UInt?
    ) async
    
    /// Flush any buffered log entries.
    func flush() async
}

// MARK: - Default Implementations

public extension UmbraLogger {
    /// Log a message at the trace level.
    func trace(
        _ message: String,
        metadata: Logging.Logger.Metadata? = nil,
        source: String? = #file,
        function: String? = #function,
        line: UInt? = #line
    ) async {
        await log(level: .trace, message: message, metadata: metadata, source: source, function: function, line: line)
    }
    
    /// Log a message at the debug level.
    func debug(
        _ message: String,
        metadata: Logging.Logger.Metadata? = nil,
        source: String? = #file,
        function: String? = #function,
        line: UInt? = #line
    ) async {
        await log(level: .debug, message: message, metadata: metadata, source: source, function: function, line: line)
    }
    
    /// Log a message at the info level.
    func info(
        _ message: String,
        metadata: Logging.Logger.Metadata? = nil,
        source: String? = #file,
        function: String? = #function,
        line: UInt? = #line
    ) async {
        await log(level: .info, message: message, metadata: metadata, source: source, function: function, line: line)
    }
    
    /// Log a message at the notice level.
    func notice(
        _ message: String,
        metadata: Logging.Logger.Metadata? = nil,
        source: String? = #file,
        function: String? = #function,
        line: UInt? = #line
    ) async {
        await log(level: .notice, message: message, metadata: metadata, source: source, function: function, line: line)
    }
    
    /// Log a message at the warning level.
    func warning(
        _ message: String,
        metadata: Logging.Logger.Metadata? = nil,
        source: String? = #file,
        function: String? = #function,
        line: UInt? = #line
    ) async {
        await log(level: .warning, message: message, metadata: metadata, source: source, function: function, line: line)
    }
    
    /// Log a message at the error level.
    func error(
        _ message: String,
        metadata: Logging.Logger.Metadata? = nil,
        source: String? = #file,
        function: String? = #function,
        line: UInt? = #line
    ) async {
        await log(level: .error, message: message, metadata: metadata, source: source, function: function, line: line)
    }
    
    /// Log a message at the critical level.
    func critical(
        _ message: String,
        metadata: Logging.Logger.Metadata? = nil,
        source: String? = #file,
        function: String? = #function,
        line: UInt? = #line
    ) async {
        await log(level: .critical, message: message, metadata: metadata, source: source, function: function, line: line)
    }
    
    /// Default implementation of flush - does nothing.
    func flush() async {
        // Default implementation does nothing
    }
}
