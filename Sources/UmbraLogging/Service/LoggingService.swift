import Foundation
import Logging

/// Main logging service class.
@MainActor
@preconcurrency
public final class LoggingService: LoggingServiceProtocol, UmbraLogger {
    // MARK: - Properties
    
    /// The configuration for the logger.
    internal var _config: LogConfig
    
    /// The configuration for the logger.
    nonisolated public var config: LogConfig {
        @MainActor get { _config }
    }
    
    /// Array of log entries.
    internal var _entries: [LogEntry]
    
    /// Memory usage in bytes.
    nonisolated public var memoryUsage: UInt64 {
        // For now, return a placeholder value since getting memory usage
        // in a concurrency-safe way requires more investigation
        return 0
    }
    
    // MARK: - Initialization
    
    /// Initialize a new logging service.
    /// - Parameter config: The logging configuration
    public init(config: LogConfig = LogConfig()) {
        self._config = config
        self._entries = []
    }
    
    // MARK: - LoggingServiceProtocol Implementation
    
    /// Log a message with the specified level and metadata.
    /// - Parameters:
    ///   - level: Log level
    ///   - message: Message to log
    ///   - metadata: Optional metadata
    ///   - source: Optional source file
    ///   - function: Optional function name
    ///   - line: Optional line number
    public func log(
        level: Logger.Level,
        message: String,
        metadata: Logger.Metadata?,
        source: String?,
        function: String?,
        line: UInt?
    ) async {
        let entry = LogEntry(
            level: level,
            message: message,
            metadata: metadata,
            source: source,
            function: function,
            line: line
        )
        await addEntry(entry)
    }
    
    /// Clear all log entries.
    public func clearEntries() async {
        _entries.removeAll()
    }
    
    /// Get all log entries.
    /// - Returns: Array of log entries
    nonisolated public func getEntries() async -> [LogEntry] {
        await MainActor.run { self._entries }
    }
    
    /// Get the current number of entries.
    /// - Returns: Number of entries
    nonisolated public func getEntryCount() async -> Int {
        await MainActor.run { self._entries.count }
    }
    
    /// Flush any buffered log entries.
    public func flush() async {
        // No buffering implemented yet
    }
    
    // MARK: - Configuration
    
    /// Update the logging configuration.
    /// - Parameter config: New configuration
    public func updateConfig(_ config: LogConfig) async {
        self._config = config
    }
    
    // MARK: - Entry Management
    
    /// Add a log entry.
    /// - Parameter entry: The entry to add
    internal func addEntry(_ entry: LogEntry) async {
        _entries.append(entry)
        await trimEntriesIfNeeded()
    }
    
    /// Trim entries if they exceed the maximum limit.
    internal func trimEntriesIfNeeded() async {
        if _entries.count > _config.maxEntries {
            let overflow = _entries.count - _config.maxEntries
            _entries.removeFirst(overflow)
        }
    }
    
    // MARK: - UmbraLogger Implementation
    
    /// Log a trace message.
    /// - Parameters:
    ///   - message: The message to log
    ///   - metadata: Optional metadata
    ///   - source: The source file
    ///   - function: The function name
    ///   - line: The line number
    public func trace(
        _ message: String,
        metadata: Logger.Metadata? = nil,
        source: String? = nil,
        function: String? = nil,
        line: UInt? = nil
    ) async {
        await log(
            level: .trace,
            message: message,
            metadata: metadata,
            source: source,
            function: function,
            line: line
        )
    }
    
    /// Log a debug message.
    /// - Parameters:
    ///   - message: The message to log
    ///   - metadata: Optional metadata
    ///   - source: The source file
    ///   - function: The function name
    ///   - line: The line number
    public func debug(
        _ message: String,
        metadata: Logger.Metadata? = nil,
        source: String? = nil,
        function: String? = nil,
        line: UInt? = nil
    ) async {
        await log(
            level: .debug,
            message: message,
            metadata: metadata,
            source: source,
            function: function,
            line: line
        )
    }
    
    /// Log an info message.
    /// - Parameters:
    ///   - message: The message to log
    ///   - metadata: Optional metadata
    ///   - source: The source file
    ///   - function: The function name
    ///   - line: The line number
    public func info(
        _ message: String,
        metadata: Logger.Metadata? = nil,
        source: String? = nil,
        function: String? = nil,
        line: UInt? = nil
    ) async {
        await log(
            level: .info,
            message: message,
            metadata: metadata,
            source: source,
            function: function,
            line: line
        )
    }
    
    /// Log a notice message.
    /// - Parameters:
    ///   - message: The message to log
    ///   - metadata: Optional metadata
    ///   - source: The source file
    ///   - function: The function name
    ///   - line: The line number
    public func notice(
        _ message: String,
        metadata: Logger.Metadata? = nil,
        source: String? = nil,
        function: String? = nil,
        line: UInt? = nil
    ) async {
        await log(
            level: .notice,
            message: message,
            metadata: metadata,
            source: source,
            function: function,
            line: line
        )
    }
    
    /// Log a warning message.
    /// - Parameters:
    ///   - message: The message to log
    ///   - metadata: Optional metadata
    ///   - source: The source file
    ///   - function: The function name
    ///   - line: The line number
    public func warning(
        _ message: String,
        metadata: Logger.Metadata? = nil,
        source: String? = nil,
        function: String? = nil,
        line: UInt? = nil
    ) async {
        await log(
            level: .warning,
            message: message,
            metadata: metadata,
            source: source,
            function: function,
            line: line
        )
    }
    
    /// Log an error message.
    /// - Parameters:
    ///   - message: The message to log
    ///   - metadata: Optional metadata
    ///   - source: The source file
    ///   - function: The function name
    ///   - line: The line number
    public func error(
        _ message: String,
        metadata: Logger.Metadata? = nil,
        source: String? = nil,
        function: String? = nil,
        line: UInt? = nil
    ) async {
        await log(
            level: .error,
            message: message,
            metadata: metadata,
            source: source,
            function: function,
            line: line
        )
    }
    
    /// Log a critical message.
    /// - Parameters:
    ///   - message: The message to log
    ///   - metadata: Optional metadata
    ///   - source: The source file
    ///   - function: The function name
    ///   - line: The line number
    public func critical(
        _ message: String,
        metadata: Logger.Metadata? = nil,
        source: String? = nil,
        function: String? = nil,
        line: UInt? = nil
    ) async {
        await log(
            level: .critical,
            message: message,
            metadata: metadata,
            source: source,
            function: function,
            line: line
        )
    }
    
    // MARK: - Metrics
    
    /// Log performance metrics.
    /// - Parameters:
    ///   - metrics: Performance metrics to log
    ///   - message: Optional message
    ///   - level: Log level
    ///   - function: Function name
    public func logMetrics(
        _ metrics: PerformanceMetrics,
        message: String,
        level: Logger.Level = .debug,
        function: String = #function
    ) async {
        var metadata: Logger.Metadata = [:]
        metadata["startTime"] = "\(metrics.startTime)"
        metadata["endTime"] = "\(metrics.endTime)"
        metadata["duration"] = "\(metrics.duration)"
        
        await log(
            level: level,
            message: message,
            metadata: metadata,
            source: nil,
            function: function,
            line: nil
        )
    }
    
    /// Log an async operation with timing information.
    /// - Parameters:
    ///   - operation: The operation to execute and log
    ///   - message: Message to log
    ///   - level: Log level
    ///   - function: Function name
    public func logAsyncOperation<T: Sendable>(
        _ operation: @Sendable () async throws -> T,
        message: String,
        level: Logger.Level = .debug,
        function: String = #function
    ) async throws -> T {
        let startTime = Date()
        let result = try await operation()
        let metrics = PerformanceMetrics(startTime: startTime, endTime: Date())
        await logMetrics(metrics, message: message, level: level, function: function)
        return result
    }
}
