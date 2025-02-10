//
// LoggerProtocol.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Protocol for logging services
public protocol LoggerProtocol {
    /// Log message configuration
    public struct LogConfig {
        /// File where the log was called
        public let file: String
        /// Function where the log was called
        public let function: String
        /// Line where the log was called
        public let line: Int
        /// Additional metadata
        public let metadata: [String: String]?
        /// Whether to synchronize log
        public let synchronous: Bool

        public init(
            file: String = #file,
            function: String = #function,
            line: Int = #line,
            metadata: [String: String]? = nil,
            synchronous: Bool = false
        ) {
            self.file = file
            self.function = function
            self.line = line
            self.metadata = metadata
            self.synchronous = synchronous
        }
    }

    /// Log levels
    public enum LogLevel: String, CaseIterable {
        case debug
        case info
        case warning
        case error
        case critical
    }

    /// Log a message
    /// - Parameters:
    ///   - level: Log level
    ///   - message: Message to log
    ///   - config: Log configuration
    func log(
        level: LogLevel,
        message: String,
        config: LogConfig
    )

    /// Log a metric
    /// - Parameters:
    ///   - name: Metric name
    ///   - value: Metric value
    ///   - unit: Unit of measurement
    ///   - config: Log configuration
    func metric(
        _ name: String,
        value: Double,
        unit: String,
        config: LogConfig
    )

    /// Log an event
    /// - Parameters:
    ///   - name: Event name
    ///   - metadata: Event metadata
    ///   - config: Log configuration
    func event(
        _ name: String,
        metadata: [String: Any],
        config: LogConfig
    )
}

/// Default implementations for LoggerProtocol
public extension LoggerProtocol {
    /// Log a debug message
    /// - Parameters:
    ///   - message: Message to log
    ///   - config: Log configuration
    func debug(
        _ message: String,
        config: LogConfig = LogConfig()
    ) {
        log(level: .debug, message: message, config: config)
    }

    /// Log an info message
    /// - Parameters:
    ///   - message: Message to log
    ///   - config: Log configuration
    func info(
        _ message: String,
        config: LogConfig = LogConfig()
    ) {
        log(level: .info, message: message, config: config)
    }

    /// Log a warning message
    /// - Parameters:
    ///   - message: Message to log
    ///   - config: Log configuration
    func warning(
        _ message: String,
        config: LogConfig = LogConfig()
    ) {
        log(level: .warning, message: message, config: config)
    }

    /// Log an error message
    /// - Parameters:
    ///   - message: Message to log
    ///   - config: Log configuration
    func error(
        _ message: String,
        config: LogConfig = LogConfig()
    ) {
        log(level: .error, message: message, config: config)
    }

    /// Log a critical message
    /// - Parameters:
    ///   - message: Message to log
    ///   - config: Log configuration
    func critical(
        _ message: String,
        config: LogConfig = LogConfig()
    ) {
        log(level: .critical, message: message, config: config)
    }

    /// Log a metric
    /// - Parameters:
    ///   - name: Metric name
    ///   - value: Metric value
    ///   - unit: Unit of measurement
    ///   - config: Log configuration
    func metric(
        _ name: String,
        value: Double,
        unit: String,
        config: LogConfig = LogConfig()
    ) {
        metric(name, value: value, unit: unit, config: config)
    }

    /// Log an event
    /// - Parameters:
    ///   - name: Event name
    ///   - metadata: Event metadata
    ///   - config: Log configuration
    func event(
        _ name: String,
        metadata: [String: Any] = [:],
        config: LogConfig = LogConfig()
    ) {
        event(name, metadata: metadata, config: config)
    }
}
