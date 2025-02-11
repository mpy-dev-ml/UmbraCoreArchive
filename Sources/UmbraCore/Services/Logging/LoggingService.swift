import Foundation
import os.log

// MARK: - LogLevel

/// Log levels for the application
public enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - LoggingService

/// Service for logging and monitoring
public final class LoggingService: BaseSandboxedService, LoggerProtocol {
    // MARK: - Properties

    private let osLogAdapter: OSLogAdapter
    private let minimumLevel: LogLevel
    private let maxEntries: Int
    private var entries: [LogEntry] = []
    private let queue = DispatchQueue(
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

    // MARK: - LoggerProtocol

    public func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .debug, message: message, file: file, function: function, line: line)
    }

    public func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }

    public func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .warning, message: message, file: file, function: function, line: line)
    }

    public func error(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .error, message: message, file: file, function: function, line: line)
    }

    public func critical(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .critical, message: message, file: file, function: function, line: line)
    }

    // MARK: - Private Methods

    private func log(
        level: LogLevel,
        message: String,
        file: String,
        function: String,
        line: Int
    ) {
        guard level >= minimumLevel else { return }

        let entry = LogEntry(
            level: level,
            message: message,
            file: file,
            function: function,
            line: line
        )

        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            entries.append(entry)
            if entries.count > maxEntries {
                entries.removeFirst()
            }
        }

        osLogAdapter.log(message: message, level: level)
    }
}

// MARK: - DummyLogger

/// A dummy logger used during initialization to avoid circular dependencies
private struct DummyLogger: LoggerProtocol {
    func debug(_: String, file _: String, function _: String, line _: Int) {}
    func info(_: String, file _: String, function _: String, line _: Int) {}
    func warning(_: String, file _: String, function _: String, line _: Int) {}
    func error(_: String, file _: String, function _: String, line _: Int) {}
    func critical(_: String, file _: String, function _: String, line _: Int) {}
}

// MARK: - LogEntry

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
