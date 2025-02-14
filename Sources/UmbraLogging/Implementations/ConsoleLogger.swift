import Foundation
import Logging

/// Simple console logger for bootstrapping
@objc
public final class ConsoleLogger: NSObject, UmbraLogger {
    // MARK: - Properties
    
    public let config: LogConfig
    
    // MARK: - Initialization
    
    public init(config: LogConfig = .default) {
        self.config = config
        super.init()
    }
    
    // MARK: - UmbraLogger
    
    public func log(
        level: Logger.Level,
        message: String,
        metadata: Logger.Metadata?,
        source: String?,
        function: String?,
        line: UInt?
    ) {
        let timestamp = DateFormatter.localizedString(
            from: Date(),
            dateStyle: .none,
            timeStyle: .medium
        )
        
        var components = [
            timestamp,
            "[\(level)]",
            message,
        ]
        
        if let metadata {
            let metadataString = metadata
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: " ")
            components.append("{\(metadataString)}")
        }
        
        if config.includeSourceLocation, let source {
            components.append("source=\(source)")
        }
        
        if config.includeFunctionNames, let function {
            components.append("function=\(function)")
        }
        
        if config.includeLineNumbers, let line {
            components.append("line=\(line)")
        }
        
        let logMessage = components.joined(separator: " ")
        print(logMessage)
    }
    
    public func flush() {
        // No buffering in console logger
    }
}
