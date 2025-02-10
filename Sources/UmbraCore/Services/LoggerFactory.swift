//
// LoggerFactory.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation
import os.log

/// Factory for creating loggers
@objc
public class LoggerFactory: NSObject {
    // MARK: - Types

    /// Logger configuration
    public struct Configuration {
        /// Minimum log level
        public let minimumLevel: Logger.Level

        /// Log destination
        public let destination: LogDestination

        /// Initialize with values
        public init(
            minimumLevel: Logger.Level = .info,
            destination: LogDestination = .osLog
        ) {
            self.minimumLevel = minimumLevel
            self.destination = destination
        }
    }

    // MARK: - Properties

    /// Shared instance
    public static let shared = LoggerFactory()

    /// Default configuration
    private let defaultConfig = Configuration()

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    /// Cache of created loggers
    private var loggers: [String: LoggerProtocol] = [:]

    /// Queue for synchronizing access
    private let queue = DispatchQueue(
        label: "dev.mpy.umbra.logger-factory",
        attributes: .concurrent
    )

    // MARK: - Initialization

    /// Initialize with dependencies
    @objc
    public init(performanceMonitor: PerformanceMonitor = PerformanceMonitor()) {
        self.performanceMonitor = performanceMonitor
        super.init()
    }

    // MARK: - Public Methods

    /// Get logger for category
    @objc
    public func getLogger(
        forCategory category: String,
        configuration: Configuration? = nil
    ) -> LoggerProtocol {
        return queue.sync {
            if let logger = loggers[category] {
                return logger
            }

            let config = configuration ?? defaultConfig
            let logger = createLogger(
                forCategory: category,
                configuration: config
            )

            loggers[category] = logger
            return logger
        }
    }

    /// Reset all loggers
    @objc
    public func resetLoggers() {
        queue.async(flags: .barrier) {
            self.loggers.removeAll()
        }
    }

    // MARK: - Private Methods

    /// Create logger for category
    private func createLogger(
        forCategory category: String,
        configuration: Configuration
    ) -> LoggerProtocol {
        return Logger(
            minimumLevel: configuration.minimumLevel,
            destination: configuration.destination
        )
    }
}
