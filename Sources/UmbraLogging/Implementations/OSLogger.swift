import Foundation
import Logging
import os

/// A logger implementation that uses the Apple unified logging system (os.log).
public final class OSLogger: UmbraLogger {
    // MARK: - Properties
    
    /// The logger configuration
    public let config: LogConfig
    
    /// The subsystem identifier for logging
    private let subsystem: String
    
    /// The category for logging
    private let category: String
    
    /// The OS logger instance
    private let osLogger: os.Logger
    
    // MARK: - Initialization
    
    /// Initialize with configuration and logging identifiers.
    /// - Parameters:
    ///   - config: The logger configuration.
    ///   - subsystem: The subsystem identifier (e.g., "com.company.app").
    ///   - category: The logging category (e.g., "networking").
    public init(
        config: LogConfig = .default,
        subsystem: String,
        category: String
    ) {
        self.config = config
        self.subsystem = subsystem
        self.category = category
        self.osLogger = os.Logger(subsystem: subsystem, category: category)
    }
    
    // MARK: - UmbraLogger
    
    private func osLogType(for level: Logging.Logger.Level) -> OSLogType {
        switch level {
        case .trace, .debug:
            return .debug
        case .info, .notice:
            return .info
        case .warning:
            return .default
        case .error:
            return .error
        case .critical:
            return .fault
        }
    }
    
    public func log(
        level: Logging.Logger.Level,
        message: String,
        metadata: Logging.Logger.Metadata?,
        source: String?,
        function: String?,
        line: UInt?
    ) {
        var logMessage = message
        
        // Add source location if configured
        if config.includeSourceLocation, let source = source {
            logMessage = "[\(source)] " + logMessage
        }
        
        // Add function name if configured
        if config.includeFunctionNames, let function = function {
            logMessage = "[\(function)] " + logMessage
        }
        
        // Add line number if configured
        if config.includeLineNumbers, let line = line {
            logMessage = "[Line \(line)] " + logMessage
        }
        
        // Add metadata if present
        if let metadata = metadata {
            let metadataString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
            logMessage += " [\(metadataString)]"
        }
        
        // Log using os_log
        osLogger.log(level: osLogType(for: level), "\(logMessage)")
    }
    
    public func flush() {
        // No explicit flush needed for os_log
    }
}
