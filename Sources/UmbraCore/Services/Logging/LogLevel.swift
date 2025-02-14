import Foundation
import os.log
import Logging

/// Log level enumeration
@frozen public enum UmbraLogLevel: Int, Codable, Sendable {
    case trace
    case debug
    case info
    case notice
    case warning
    case error
    case critical
    case fault
    
    /// Severity level (higher is more severe)
    public var severity: Int {
        rawValue
    }
    
    /// Corresponding OSLogType
    public var osLogType: OSLogType {
        switch self {
        case .trace, .debug:
            return .debug
        case .info:
            return .info
        case .notice:
            return .default
        case .warning:
            return .error
        case .error, .critical, .fault:
            return .fault
        }
    }
    
    /// Convert to swift-log Logger.Level
    public var swiftLogLevel: Logger.Level {
        switch self {
        case .trace:
            return .trace
        case .debug:
            return .debug
        case .info:
            return .info
        case .notice:
            return .notice
        case .warning:
            return .warning
        case .error:
            return .error
        case .critical, .fault:
            return .critical
        }
    }
    
    /// Convert from swift-log Logger.Level
    public static func from(_ level: Logger.Level) -> UmbraLogLevel {
        switch level {
        case .trace:
            return .trace
        case .debug:
            return .debug
        case .info:
            return .info
        case .notice:
            return .notice
        case .warning:
            return .warning
        case .error:
            return .error
        case .critical:
            return .critical
        }
    }
    
    /// Icon representation
    public var icon: String {
        switch self {
        case .trace:
            return "🔍"
        case .debug:
            return "🐛"
        case .info:
            return "ℹ️"
        case .notice:
            return "📝"
        case .warning:
            return "⚠️"
        case .error:
            return "❌"
        case .critical:
            return "🚨"
        case .fault:
            return "💥"
        }
    }
}
