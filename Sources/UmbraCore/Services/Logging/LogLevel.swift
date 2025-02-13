@preconcurrency import Foundation
import os.log

/// Log level for logging operations
public enum LogLevel: Int, Comparable, CustomStringConvertible {
    /// Debug level for detailed information during development
    case debug = 0

    /// Info level for general operational information
    case info = 1

    /// Warning level for potentially problematic situations
    case warning = 2

    /// Error level for errors that need attention
    case error = 3

    /// Critical level for severe errors that may impact system stability
    case critical = 4

    // MARK: - Comparable

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    // MARK: - Description

    /// Human-readable description of the log level
    public var description: String {
        switch self {
        case .debug:
            "Debug"
        case .info:
            "Info"
        case .warning:
            "Warning"
        case .error:
            "Error"
        case .critical:
            "Critical"
        }
    }

    /// OS Log type equivalent
    public var osLogType: OSLogType {
        switch self {
        case .debug:
            .debug
        case .info:
            .info
        case .warning:
            .default
        case .error:
            .error
        case .critical:
            .fault
        }
    }
}
