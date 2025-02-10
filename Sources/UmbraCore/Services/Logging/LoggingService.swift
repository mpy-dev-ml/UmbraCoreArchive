//
// LoggingService.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation
import os.log

/// Service for logging and monitoring
public final class LoggingService: BaseSandboxedService, LoggerProtocol {
    // MARK: - Types

    /// Log level
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

    /// Log entry
    public struct LogEntry: Codable {
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
    }

    // MARK: - Properties

    /// OS logger
    private let osLogger: OSLog

    /// Minimum log level
    private var minimumLevel: LogLevel

    /// Queue for synchronizing operations
    private let queue = DispatchQueue(
        label: "dev.mpy.umbracore.logging",
        qos: .utility,
        attributes: .concurrent
    )

    /// Log entries
    private var entries: [LogEntry] = []

    /// Maximum number of entries to keep
    private let maxEntries: Int

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
        self.osLogger = OSLog(subsystem: subsystem, category: category)
        self.minimumLevel = minimumLevel
        self.maxEntries = maxEntries
        super.init(logger: DummyLogger())
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

            if let level = level {
                filtered = filtered.filter { $0.level >= level }
            }

            if let startDate = startDate {
                filtered = filtered.filter { $0.timestamp >= startDate }
            }

            if let endDate = endDate {
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

    // MARK: - Private Methods

    /// Log a message
    private func log(
        _ level: LogLevel,
        _ message: String,
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

        // Log to system
        let type: OSLogType
        switch level {
        case .debug:
            type = .debug
        case .info:
            type = .info
        case .warning:
            type = .error
        case .error:
            type = .error
        case .critical:
            type = .fault
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

/// Dummy logger for initialization
private struct DummyLogger: LoggerProtocol {
    func debug(
        _ message: String,
        file: String,
        function: String,
        line: Int
    ) {}

    func info(
        _ message: String,
        file: String,
        function: String,
        line: Int
    ) {}

    func warning(
        _ message: String,
        file: String,
        function: String,
        line: Int
    ) {}

    func error(
        _ message: String,
        file: String,
        function: String,
        line: Int
    ) {}

    func critical(
        _ message: String,
        file: String,
        function: String,
        line: Int
    ) {}

    func metric(
        _ name: String,
        value: Double,
        unit: String,
        file: String,
        function: String,
        line: Int
    ) {}

    func event(
        _ name: String,
        metadata: [String: Any],
        file: String,
        function: String,
        line: Int
    ) {}
}
