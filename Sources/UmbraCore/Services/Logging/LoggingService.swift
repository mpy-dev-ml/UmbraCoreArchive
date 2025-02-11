import Foundation
import os.log

// MARK: - LoggingService

/// Service for logging and monitoring
public final class LoggingService: BaseSandboxedService {
    // MARK: - Properties

    let osLogAdapter: OSLogAdapter
    let minimumLevel: LogLevel
    let maxEntries: Int
    var entries: [LogEntry] = []
    let queue = DispatchQueue(
        label: "dev.mpy.umbracore.logging",
        qos: .utility,
        attributes: .concurrent
    )

    // MARK: - Initialization

    /// Initialize with configuration
    /// - Parameter configuration: Service configuration
    public init(configuration: Configuration = Configuration()) {
        osLogAdapter = OSLogAdapter(
            subsystem: configuration.subsystem,
            category: configuration.category
        )
        minimumLevel = configuration.minimumLevel
        maxEntries = configuration.maxEntries
        super.init(logger: DummyLogger())
    }

    // MARK: - Internal Methods

    func shouldLog(_ level: LogLevel) -> Bool {
        level >= minimumLevel
    }

    func processLogMessage(
        level: LogLevel,
        message: String,
        file: String,
        function: String,
        line: Int
    ) {
        let entry = LogEntry(
            level: level,
            message: message,
            file: file,
            function: function,
            line: line
        )

        osLogAdapter.log(message: message, level: level)
        addEntry(entry)
    }

    func addEntry(_ entry: LogEntry) {
        queue.async(flags: .barrier) {
            self.entries.append(entry)
            self.trimEntriesIfNeeded()
        }
    }

    private func trimEntriesIfNeeded() {
        if entries.count > maxEntries {
            let overflow = entries.count - maxEntries
            entries.removeFirst(overflow)
        }
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

    public func event(
        _ name: String,
        metadata: [String: Any],
        file: String,
        function: String,
        line: Int
    ) {
        let entry = createEventEntry(
            name: name,
            metadata: metadata,
            file: file,
            function: function,
            line: line
        )
        addEntry(entry)
    }

    /// Create event log entry
    /// - Parameters:
    ///   - name: Event name
    ///   - metadata: Event metadata
    ///   - file: Source file
    ///   - function: Source function
    ///   - line: Source line
    /// - Returns: Configured log entry
    private func createEventEntry(
        name: String,
        metadata: [String: Any],
        file: String,
        function: String,
        line: Int
    ) -> LogEntry {
        let stringMetadata = convertMetadataToString(metadata)
        return LogEntry(
            level: .info,
            message: "Event - \(name)",
            file: file,
            function: function,
            line: line,
            metadata: stringMetadata
        )
    }

    /// Convert metadata values to strings
    /// - Parameter metadata: Metadata to convert
    /// - Returns: Metadata with string values
    private func convertMetadataToString(_ metadata: [String: Any]) -> [String: String] {
        metadata.mapValues { "\($0)" }
    }

    /// Log a message
    private func log(
        _ level: LogLevel,
        _ message: String,
        file: String,
        function: String,
        line: Int
    ) {
        guard shouldLog(level) else {
            return
        }

        processLogMessage(
            level: level,
            message: message,
            file: file,
            function: function,
            line: line
        )
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

    func event(
        _: String,
        metadata _: [String: Any],
        file _: String,
        function _: String,
        line _: Int
    ) {}
}

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
