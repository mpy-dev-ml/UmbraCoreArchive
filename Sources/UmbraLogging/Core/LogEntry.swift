import Foundation
import Logging

/// Represents a log entry in the UmbraCore logging system.
public struct LogEntry: Sendable {
    /// The timestamp when the log entry was created.
    public let timestamp: Date

    /// The log level of the entry.
    public let level: Logger.Level

    /// The message content of the log entry.
    public let message: String

    /// Additional metadata associated with the log entry.
    public let metadata: Logger.Metadata?

    /// The source file where the log was created.
    public let source: String?

    /// The function where the log was created.
    public let function: String?

    /// The line number where the log was created.
    public let line: UInt?

    /// Creates a new log entry.
    /// - Parameters:
    ///   - level: The severity level of the log entry.
    ///   - message: The message content.
    ///   - metadata: Optional metadata associated with the entry.
    ///   - source: The source file where the log was created.
    ///   - function: The function where the log was created.
    ///   - line: The line number where the log was created.
    public init(
        level: Logger.Level,
        message: String,
        metadata: Logger.Metadata? = nil,
        source: String? = nil,
        function: String? = nil,
        line: UInt? = nil
    ) {
        self.timestamp = Date()
        self.level = level
        self.message = message
        self.metadata = metadata
        self.source = source
        self.function = function
        self.line = line
    }
}
