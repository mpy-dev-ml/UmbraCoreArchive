import Foundation
import Logging

/// Factory for creating logger instances.
public enum LoggerFactory {
    /// Create a logger based on the configuration.
    /// - Parameter config: The logger configuration
    /// - Returns: A configured logger instance
    public static func createLogger(config: LogConfig = .default) -> UmbraLogger {
        if config.minimumLevel <= .debug {
            return ConsoleLogger(config: config)
        } else {
            return OSLogger(
                config: config,
                subsystem: "com.umbracore.logging",
                category: "default"
            )
        }
    }
    
    /// Create a console logger.
    /// - Parameter config: The logger configuration
    /// - Returns: A configured console logger
    public static func createConsoleLogger(config: LogConfig = .default) -> UmbraLogger {
        ConsoleLogger(config: config)
    }
    
    /// Create an OS logger.
    /// - Parameter config: The logger configuration
    /// - Returns: A configured OS logger
    public static func createOSLogger(config: LogConfig = .default) -> UmbraLogger {
        OSLogger(
            config: config,
            subsystem: "com.umbracore.logging",
            category: "default"
        )
    }
    
    /// Create a dummy logger that does nothing.
    /// - Returns: A dummy logger instance
    public static func createDummyLogger() -> UmbraLogger {
        DummyLogger()
    }
}
