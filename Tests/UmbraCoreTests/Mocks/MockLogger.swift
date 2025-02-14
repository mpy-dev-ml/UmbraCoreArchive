//
//  MockLogger.swift
//  Core
//
//  First created: 6 February 2025
//  Last updated: 7 February 2025
//

import Foundation
import Logging
import UmbraLogging

/// Mock logger for testing
public final class MockLogger: UmbraLogger {
    // MARK: - Types
    
    /// Logged message for verification in tests
    public struct LoggedMessage: Equatable {
        /// Initialize with values
        public init(
            message: String,
            level: Logging.Logger.Level,
            metadata: Logging.Logger.Metadata? = nil
        ) {
            self.message = message
            self.level = level
            self.metadata = metadata
        }
        
        /// Message text
        public let message: String
        /// Log level
        public let level: Logging.Logger.Level
        /// Message metadata
        public let metadata: Logging.Logger.Metadata?
    }
    
    // MARK: - Properties
    
    /// Messages that have been logged
    public private(set) var messages: [LoggedMessage] = []
    
    /// The logger configuration
    public let config: LogConfig
    
    // MARK: - Initialization
    
    /// Initialize with configuration
    /// - Parameter config: Logger configuration
    public init(config: LogConfig = .default) {
        self.config = config
    }
    
    // MARK: - UmbraLogger Implementation
    
    public func log(
        level: Logging.Logger.Level,
        message: String,
        metadata: Logging.Logger.Metadata?,
        source: String?,
        function: String?,
        line: UInt?
    ) {
        messages.append(LoggedMessage(
            message: message,
            level: level,
            metadata: metadata
        ))
    }
    
    public func flush() {
        // No-op implementation for testing
    }
    
    // MARK: - Test Helpers
    
    /// Clear all logged messages
    public func clear() {
        messages.removeAll()
    }
    
    /// Get messages at a specific level
    /// - Parameter level: The log level to filter by
    /// - Returns: Array of messages at that level
    public func messages(at level: Logging.Logger.Level) -> [LoggedMessage] {
        messages.filter { $0.level == level }
    }
}
