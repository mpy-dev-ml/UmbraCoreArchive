import Foundation

/// Log entry structure
public struct LogEntry: Codable {
    // MARK: - Properties

    /// Timestamp of the log entry
    public let timestamp: Date

    /// Log level
    public let level: LogLevel

    /// Log message
    public let message: String

    /// Source file
    public let file: String

    /// Source line
    public let line: Int

    /// Source function
    public let function: String

    // MARK: - Initialization

    /// Initialize a log entry
    /// - Parameters:
    ///   - timestamp: Entry timestamp
    ///   - level: Log level
    ///   - message: Log message
    ///   - file: Source file
    ///   - line: Source line
    ///   - function: Source function
    public init(
        timestamp: Date = Date(),
        level: LogLevel,
        message: String,
        file: String,
        line: Int,
        function: String
    ) {
        self.timestamp = timestamp
        self.level = level
        self.message = message
        self.file = file
        self.line = line
        self.function = function
    }
}
