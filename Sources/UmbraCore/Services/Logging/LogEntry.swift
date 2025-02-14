import Foundation

/// Log entry structure
public struct LogEntry: Codable, Sendable {
    // MARK: - Properties
    
    /// Log level
    public let level: UmbraLogLevel
    
    /// Log message
    public let message: String
    
    /// Source file
    public let file: String
    
    /// Source function
    public let function: String
    
    /// Source line
    public let line: Int
    
    /// Timestamp
    public let timestamp: Date
    
    // MARK: - Initialization
    
    /// Initialize a new log entry
    /// - Parameters:
    ///   - level: Log level
    ///   - message: Log message
    ///   - file: Source file
    ///   - function: Source function
    ///   - line: Source line
    ///   - timestamp: Log timestamp
    public init(
        level: UmbraLogLevel,
        message: String,
        file: String,
        function: String,
        line: Int,
        timestamp: Date = Date()
    ) {
        self.level = level
        self.message = message
        self.file = file
        self.function = function
        self.line = line
        self.timestamp = timestamp
    }
}
