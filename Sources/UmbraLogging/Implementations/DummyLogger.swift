import Foundation
import Logging

/// A dummy logger that does nothing with log messages.
public final class DummyLogger: UmbraLogger {
    /// The logger configuration.
    public let config: LogConfig
    
    /// Initialize a new dummy logger.
    public init(config: LogConfig = .default) {
        self.config = config
    }
    
    /// No-op log method.
    public func log(
        level: Logging.Logger.Level,
        message: String,
        metadata: Logger.Metadata? = nil,
        source: String? = nil,
        function: String? = nil,
        line: UInt? = nil
    ) {
        // Do nothing
    }
    
    /// No-op flush method.
    public func flush() {
        // Do nothing
    }
    
    /// No-op metadata method.
    public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get { nil }
        set { }
    }
    
    /// No-op metadata method.
    public var metadata: Logger.Metadata {
        get { [:] }
        set { }
    }
    
    /// No-op log level.
    public var logLevel: Logger.Level {
        get { .critical }
        set { }
    }
}
