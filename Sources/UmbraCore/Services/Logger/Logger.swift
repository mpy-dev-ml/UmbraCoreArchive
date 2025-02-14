@preconcurrency import Foundation
import os.log

// MARK: - Logger

/// Main logger implementation
public class Logger: Sendable, LoggerProtocol {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with configuration
    public init(
        minimumLevel: Level = .info,
        destination: LogDestination = .osLog
    ) {
        self.minimumLevel = minimumLevel
        self.destination = destination
    }

    // MARK: Public

    // MARK: - Types

    /// Log level
    public enum Level: Int, Sendable, Comparable {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3
        case critical = 4

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        // MARK: Internal

        /// Convert to string
        var description: String {
            switch self {
            case .debug: "DEBUG"
            case .info: "INFO"
            case .warning: "WARNING"
            case .error: "ERROR"
            case .critical: "CRITICAL"
            }
        }
    }

    // MARK: - LoggerProtocol

    /// Log debug message
    public func log(
        level: Level,
        message: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: UInt
    ) {
        guard level.rawValue >= minimumLevel.rawValue else {
            return
        }

        queue.async {
            self.writeLog(
                message: message,
                level: level,
                config: LogConfig(metadata: metadata)
            )
        }
    }

    // MARK: Private

    /// Minimum log level
    private let minimumLevel: Level

    /// Log destination
    private let destination: LogDestination

    /// Queue for synchronizing logging
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbra.logger",
        qos: .utility
    )

    // MARK: - Private Methods

    /// Log message with level
    private func writeLog(
        message: String,
        level: Level,
        config: LogConfig
    ) {
        let formattedMessage = formatMessage(
            message,
            level: level,
            config: config
        )

        switch destination {
        case .osLog:
            writeToOSLog(formattedMessage, level: level)

        case let .file(url):
            writeToFile(formattedMessage, at: url)

        case let .custom(handler):
            handler(formattedMessage, level)
        }
    }

    /// Format log message
    private func formatMessage(
        _ message: String,
        level: Level,
        config: LogConfig
    ) -> String {
        let timestamp = DateFormatter.logTimestamp.string(from: Date())
        let metadata = formatMetadata(config.metadata)

        return """
        [\(timestamp)] [\(level.description)] \
        \(message)\(metadata)
        """
    }

    /// Format metadata dictionary
    private func formatMetadata(
        _ metadata: [String: String]?
    ) -> String {
        guard let metadata = metadata, !metadata.isEmpty else {
            return ""
        }

        let metadataString =
            metadata
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: " ")

        return " [\(metadataString)]"
    }

    /// Write to OS Log
    private func writeToOSLog(
        _ message: String,
        level: Level
    ) {
        let type: OSLogType =
            switch level {
            case .debug:
                .debug

            case .info:
                .info

            case .warning:
                .default

            case .error:
                .error

            case .critical:
                .fault
            }

        os_log(
            "%{public}@",
            type: type,
            message
        )
    }

    /// Write to file
    private func writeToFile(
        _ message: String,
        at url: URL
    ) {
        do {
            let data = message.appending("\n").data(using: .utf8) ?? Data()

            if FileManager.default.fileExists(atPath: url.path) {
                let handle = try FileHandle(forWritingTo: url)
                handle.seekToEndOfFile()
                handle.write(data)
                try handle.close()
            } else {
                try data.write(to: url, options: .atomic)
            }
        } catch {
            os_log(
                "Failed to write log: %{public}@",
                type: .error,
                error.localizedDescription
            )
        }
    }
}

// MARK: - LogDestination

/// Log destination
public enum LogDestination {
    /// OS Log
    case osLog
    /// File at URL
    case file(URL)
    /// Custom handler
    case custom((String, Logger.Level) -> Void)
}

// MARK: - LogConfig

public struct LogConfig {
    public let metadata: [String: String]?

    public init(metadata: [String: String]? = nil) {
        self.metadata = metadata
    }
}

// MARK: - DateFormatter Extension

private extension DateFormatter {
    /// Formatter for log timestamps
    static let logTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
