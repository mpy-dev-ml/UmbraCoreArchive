import Foundation
import os.log
import Logging

/// Adapter for converting between Logging.Logger.Level and OSLogType.
public struct OSLogAdapter {
    /// The OS logger instance.
    private let osLogger: OSLog
    
    /// Initialize a new OS log adapter.
    /// - Parameters:
    ///   - subsystem: The subsystem identifier (e.g., "com.company.app")
    ///   - category: The logging category (e.g., "networking")
    public init(subsystem: String, category: String) {
        self.osLogger = OSLog(subsystem: subsystem, category: category)
    }
    
    /// Log a message at the specified level.
    /// - Parameters:
    ///   - message: Message to log
    ///   - level: Log level
    func log(message: String, level: Logging.Logger.Level) {
        let type: OSLogType =
            switch level {
            case .trace:
                .debug
            case .debug:
                .debug
            case .info:
                .info
            case .notice:
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
            log: osLogger,
            type: type,
            message
        )
    }
}
