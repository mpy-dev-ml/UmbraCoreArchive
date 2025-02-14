import Foundation
import Logging

/// Mock logger for testing and initialization purposes.
/// This logger implements the UmbraLogger protocol but performs no actual logging,
/// making it useful for testing scenarios where you want to verify logging behavior
/// without actually writing logs.
public final class MockLogger: UmbraLogger {
    /// The logger configuration
    public let config: LogConfig
    
    /// Initialize with configuration
    /// - Parameter config: Logger configuration
    public init(config: LogConfig = .default) {
        self.config = config
    }
    
    public func log(
        level: Logging.Logger.Level,
        message: String,
        metadata: Logging.Logger.Metadata?,
        source: String?,
        function: String?,
        line: UInt?
    ) {
        // No-op implementation for testing
    }
    
    public func flush() {
        // No-op implementation for testing
    }
}
