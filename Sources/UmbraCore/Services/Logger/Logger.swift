//
// Logger.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation
import os.log

/// Main logger implementation
@objc
public class Logger: NSObject, LoggerProtocol {
    // MARK: - Types

    /// Log level
    public enum Level: Int {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3
        case critical = 4

        /// Convert to string
        var description: String {
            switch self {
            case .debug: return "DEBUG"
            case .info: return "INFO"
            case .warning: return "WARNING"
            case .error: return "ERROR"
            case .critical: return "CRITICAL"
            }
        }
    }

    // MARK: - Properties

    /// Minimum log level
    private let minimumLevel: Level

    /// Log destination
    private let destination: LogDestination

    /// Queue for synchronizing logging
    private let queue = DispatchQueue(
        label: "dev.mpy.umbra.logger",
        qos: .utility
    )

    // MARK: - Initialization

    /// Initialize with configuration
    @objc
    public init(
        minimumLevel: Level = .info,
        destination: LogDestination = .osLog
    ) {
        self.minimumLevel = minimumLevel
        self.destination = destination
        super.init()
    }

    // MARK: - LoggerProtocol

    /// Log debug message
    @objc
    public func debug(
        _ message: String,
        config: LogConfig = LogConfig()
    ) {
        log(
            message,
            level: .debug,
            config: config
        )
    }

    /// Log info message
    @objc
    public func info(
        _ message: String,
        config: LogConfig = LogConfig()
    ) {
        log(
            message,
            level: .info,
            config: config
        )
    }

    /// Log warning message
    @objc
    public func warning(
        _ message: String,
        config: LogConfig = LogConfig()
    ) {
        log(
            message,
            level: .warning,
            config: config
        )
    }

    /// Log error message
    @objc
    public func error(
        _ message: String,
        config: LogConfig = LogConfig()
    ) {
        log(
            message,
            level: .error,
            config: config
        )
    }

    /// Log critical message
    @objc
    public func critical(
        _ message: String,
        config: LogConfig = LogConfig()
    ) {
        log(
            message,
            level: .critical,
            config: config
        )
    }

    // MARK: - Private Methods

    /// Log message with level
    private func log(
        _ message: String,
        level: Level,
        config: LogConfig
    ) {
        guard level.rawValue >= minimumLevel.rawValue else {
            return
        }

        queue.async {
            self.writeLog(
                message: message,
                level: level,
                config: config
            )
        }
    }

    /// Write log to destination
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
        case .file(let url):
            writeToFile(formattedMessage, at: url)
        case .custom(let handler):
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
        _ metadata: [String: String]
    ) -> String {
        guard !metadata.isEmpty else {
            return ""
        }

        let metadataString = metadata
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")

        return " [\(metadataString)]"
    }

    /// Write to OS Log
    private func writeToOSLog(
        _ message: String,
        level: Level
    ) {
        let type: OSLogType
        switch level {
        case .debug:
            type = .debug
        case .info:
            type = .info
        case .warning:
            type = .default
        case .error:
            type = .error
        case .critical:
            type = .fault
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

// MARK: - Log Destination

/// Log destination
public enum LogDestination {
    /// OS Log
    case osLog
    /// File at URL
    case file(URL)
    /// Custom handler
    case custom((String, Logger.Level) -> Void)
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
