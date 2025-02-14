import Foundation
import Logging

/// Protocol defining the interface for the logging service.
@preconcurrency
public protocol LoggingServiceProtocol: Sendable {
    // MARK: - Properties
    
    /// The configuration for the logger.
    nonisolated var config: LogConfig { get }
    
    /// Memory usage in bytes.
    nonisolated var memoryUsage: UInt64 { get }
    
    // MARK: - Logging
    
    /// Log a message with the specified level and metadata.
    /// - Parameters:
    ///   - level: Log level
    ///   - message: Message to log
    ///   - metadata: Optional metadata
    ///   - source: Optional source file
    ///   - function: Optional function name
    ///   - line: Optional line number
    func log(
        level: Logger.Level,
        message: String,
        metadata: Logger.Metadata?,
        source: String?,
        function: String?,
        line: UInt?
    ) async
    
    /// Clear all log entries.
    func clearEntries() async
    
    /// Get all log entries.
    /// - Returns: Array of log entries
    nonisolated func getEntries() async -> [LogEntry]
    
    /// Get the current number of entries.
    /// - Returns: Number of entries
    nonisolated func getEntryCount() async -> Int
    
    /// Flush any buffered log entries.
    func flush() async
    
    // MARK: - Configuration
    
    /// Update the logging configuration.
    /// - Parameter config: New configuration
    func updateConfig(_ config: LogConfig) async
}

// MARK: - Default Implementations

extension LoggingServiceProtocol {
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
    public func logAsyncOperation<T>(
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
