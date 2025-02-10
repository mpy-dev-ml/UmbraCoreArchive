import Foundation
import os.log

// MARK: - LoggingService

/// Service for logging and monitoring
public final class LoggingService: BaseSandboxedService, LoggerProtocol {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with configuration
    /// - Parameters:
    ///   - subsystem: Subsystem identifier
    ///   - category: Category identifier
    ///   - minimumLevel: Minimum log level
    ///   - maxEntries: Maximum number of entries to keep
    public init(
        subsystem: String = "dev.mpy.umbracore",
        category: String = "default",
        minimumLevel: LogLevel = .debug,
        maxEntries: Int = 10000
    ) {
        osLogger = OSLog(subsystem: subsystem, category: category)
        self.minimumLevel = minimumLevel
        self.maxEntries = maxEntries
        super.init(logger: DummyLogger())
    }

    // MARK: Public

    // MARK: - Types

    /// Log level
    public enum LogLevel: Int, Comparable {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3
        case critical = 4

        // MARK: Public

        public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// Log entry
    public struct LogEntry: Codable {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            level: LogLevel,
            message: String,
            file: String,
            function: String,
            line: Int,
            timestamp: Date = Date(),
            metadata: [String: String] = [:]
        ) {
            self.level = level
            self.message = message
            self.file = file
            self.function = function
            self.line = line
            self.timestamp = timestamp
            self.metadata = metadata
        }

        // MARK: Public

        /// Log level
        public let level: LogLevel

        /// Message
        public let message: String

        /// Source file
        public let file: String

        /// Source function
        public let function: String

        /// Source line
        public let line: Int

        /// Timestamp
        public let timestamp: Date

        /// Additional metadata
        public let metadata: [String: String]
    }

    // MARK: - LoggerProtocol Implementation

    public func debug(
        _ message: String,
        file: String,
        function: String,
        line: Int
    ) {
        log(.debug, message, file: file, function: function, line: line)
    }

    public func info(
        _ message: String,
        file: String,
        function: String,
        line: Int
    ) {
        log(.info, message, file: file, function: function, line: line)
    }

    public func warning(
        _ message: String,
        file: String,
        function: String,
        line: Int
    ) {
        log(.warning, message, file: file, function: function, line: line)
    }

    public func error(
        _ message: String,
        file: String,
        function: String,
        line: Int
    ) {
        log(.error, message, file: file, function: function, line: line)
    }

    public func critical(
        _ message: String,
        file: String,
        function: String,
        line: Int
    ) {
        log(.critical, message, file: file, function: function, line: line)
    }

    public func metric(
        _ name: String,
        value: Double,
        unit: String,
        file: String,
        function: String,
        line: Int
    ) {
        let message = "Metric - \(name): \(value) \(unit)"
        log(.info, message, file: file, function: function, line: line)
    }

    public func event(
        _ name: String,
        metadata: [String: Any],
        file: String,
        function: String,
        line: Int
    ) {
        let stringMetadata = metadata.mapValues { "\($0)" }
        let entry = LogEntry(
            level: .info,
            message: "Event - \(name)",
            file: file,
            function: function,
            line: line,
            metadata: stringMetadata
        )

        storeEntry(entry)
    }

    // MARK: - Public Methods

    /// Update minimum log level
    /// - Parameter level: New minimum level
    public func updateMinimumLevel(_ level: LogLevel) {
        queue.async(flags: .barrier) {
            self.minimumLevel = level
        }
    }

    /// Get log entries
    /// - Parameters:
    ///   - level: Optional level filter
    ///   - startDate: Optional start date filter
    ///   - endDate: Optional end date filter
    /// - Returns: Array of log entries
    public func getEntries(
        level: LogLevel? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> [LogEntry] {
        queue.sync {
            var filtered = entries

            if let level {
                filtered = filtered.filter { $0.level >= level }
            }

            if let startDate {
                filtered = filtered.filter { $0.timestamp >= startDate }
            }

            if let endDate {
                filtered = filtered.filter { $0.timestamp <= endDate }
            }

            return filtered
        }
    }

    /// Clear log entries
    public func clearEntries() {
        queue.async(flags: .barrier) {
            self.entries.removeAll()
        }
    }

    // MARK: Private

    /// OS logger
    private let osLogger: OSLog

    /// Minimum log level
    private var minimumLevel: LogLevel

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.logging",
        qos: .utility,
        attributes: .concurrent
    )

    /// Log entries
    private var entries: [LogEntry] = []

    /// Maximum number of entries to keep
    private let maxEntries: Int

    // MARK: - Private Methods

    /// Log a message
    private func log(
        _ level: LogLevel,
        _ message: String,
        file: String,
        function: String,
        line: Int
    ) {
        guard level >= minimumLevel else {
            return
        }

        let entry = LogEntry(
            level: level,
            message: message,
            file: file,
            function: function,
            line: line
        )

        // Log to system
        let type: OSLogType =
            switch level {
            case .debug:
                .debug
            case .info:
                .info
            case .warning:
                .error
            case .error:
                .error
            case .critical:
                .fault
            }

        os_log(
            "%{public}@",
            log: osLogger,
            type: type,
            message
        )

        storeEntry(entry)
    }

    /// Store a log entry
    private func storeEntry(_ entry: LogEntry) {
        queue.async(flags: .barrier) {
            self.entries.append(entry)

            // Trim old entries if needed
            if self.entries.count > self.maxEntries {
                self.entries.removeFirst(
                    self.entries.count - self.maxEntries
                )
            }
        }
    }
}

// MARK: - DummyLogger

/// Dummy logger for initialization
private struct DummyLogger: LoggerProtocol {
    func debug(
        _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    func info(
        _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    func warning(
        _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    func error(
        _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    func critical(
        _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    func metric(
        _: String,
        value _: Double,
        unit _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    func event(
        _: String,
        metadata _: [String: Any],
        file _: String,
        function _: String,
        line _: Int
    ) {}
}

// MARK: - LogEntryConfig

/// Configuration for log entries
public struct LogEntryConfig {
    let message: String
    let level: LogLevel
    let category: String
    let file: String
    let function: String
    let line: Int
    let metadata: [String: Any]?
    
    public init(
        message: String,
        level: LogLevel,
        category: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        metadata: [String: Any]? = nil
    ) {
        self.message = message
        self.level = level
        self.category = category
        self.file = file
        self.function = function
        self.line = line
        self.metadata = metadata
    }
}

// MARK: - LoggingService (New)

/// Service responsible for logging system events and messages
public class LoggingService {
    private let logger: LoggerProtocol
    
    public init(logger: LoggerProtocol) {
        self.logger = logger
    }
    
    /// Log a message with the specified configuration
    public func log(_ config: LogEntryConfig) {
        logger.log(
            message: config.message,
            level: config.level,
            category: config.category,
            file: config.file,
            function: config.function,
            line: config.line,
            metadata: config.metadata
        )
    }
    
    /// Log a debug message
    public func debug(
        _ message: String,
        category: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let config = LogEntryConfig(
            message: message,
            level: .debug,
            category: category,
            file: file,
            function: function,
            line: line
        )
        log(config)
    }
    
    /// Log an info message
    public func info(
        _ message: String,
        category: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let config = LogEntryConfig(
            message: message,
            level: .info,
            category: category,
            file: file,
            function: function,
            line: line
        )
        log(config)
    }
    
    /// Log a warning message
    public func warning(
        _ message: String,
        category: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let config = LogEntryConfig(
            message: message,
            level: .warning,
            category: category,
            file: file,
            function: function,
            line: line
        )
        log(config)
    }
    
    /// Log an error message
    public func error(
        _ message: String,
        category: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        error: Error? = nil
    ) {
        var metadata: [String: Any]?
        if let error = error {
            metadata = ["error": error]
        }
        
        let config = LogEntryConfig(
            message: message,
            level: .error,
            category: category,
            file: file,
            function: function,
            line: line,
            metadata: metadata
        )
        log(config)
    }
}
