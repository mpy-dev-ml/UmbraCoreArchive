//
//  MockLogger.swift
//  Core
//
//  First created: 6 February 2025
//  Last updated: 7 February 2025
//

import Foundation
import os.log

/// Mock logger for testing
@objc
public class MockLogger: NSObject, LoggerProtocol {
    // MARK: - Types
    
    /// Logged message
    public struct LoggedMessage: Equatable {
        /// Message text
        public let message: String
        /// Log level
        public let level: Level
        /// Message metadata
        public let metadata: [String: String]
        
        /// Initialize with values
        public init(
            message: String,
            level: Level,
            metadata: [String: String]
        ) {
            self.message = message
            self.level = level
            self.metadata = metadata
        }
    }
    
    /// Log level
    public enum Level: Int {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3
        case critical = 4
    }
    
    // MARK: - Properties
    
    /// Logged messages
    public private(set) var messages: [LoggedMessage] = []
    
    /// Queue for synchronizing access
    private let queue = DispatchQueue(
        label: "dev.mpy.umbra.mock-logger",
        attributes: .concurrent
    )
    
    // MARK: - LoggerProtocol
    
    /// Log debug message
    @objc
    public func debug(
        _ message: String,
        config: LogConfig = LogConfig()
    ) {
        logMessage(
            message,
            level: .debug,
            metadata: config.metadata
        )
    }
    
    /// Log info message
    @objc
    public func info(
        _ message: String,
        config: LogConfig = LogConfig()
    ) {
        logMessage(
            message,
            level: .info,
            metadata: config.metadata
        )
    }
    
    /// Log warning message
    @objc
    public func warning(
        _ message: String,
        config: LogConfig = LogConfig()
    ) {
        logMessage(
            message,
            level: .warning,
            metadata: config.metadata
        )
    }
    
    /// Log error message
    @objc
    public func error(
        _ message: String,
        config: LogConfig = LogConfig()
    ) {
        logMessage(
            message,
            level: .error,
            metadata: config.metadata
        )
    }
    
    /// Log critical message
    @objc
    public func critical(
        _ message: String,
        config: LogConfig = LogConfig()
    ) {
        logMessage(
            message,
            level: .critical,
            metadata: config.metadata
        )
    }
    
    // MARK: - Public Methods
    
    /// Clear logged messages
    public func clear() {
        queue.async(flags: .barrier) {
            self.messages.removeAll()
        }
    }
    
    /// Get messages of level
    public func messages(
        ofLevel level: Level
    ) -> [LoggedMessage] {
        return queue.sync {
            messages.filter { $0.level == level }
        }
    }
    
    /// Get messages containing text
    public func messages(
        containing text: String
    ) -> [LoggedMessage] {
        return queue.sync {
            messages.filter { $0.message.contains(text) }
        }
    }
    
    // MARK: - Private Methods
    
    /// Log message with level and metadata
    private func logMessage(
        _ message: String,
        level: Level,
        metadata: [String: String]
    ) {
        queue.async(flags: .barrier) {
            self.messages.append(
                LoggedMessage(
                    message: message,
                    level: level,
                    metadata: metadata
                )
            )
        }
    }
}
