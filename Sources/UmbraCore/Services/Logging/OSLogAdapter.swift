import Foundation
import os.log

/// Adapter for system logging using os.log
final class OSLogAdapter {
    // MARK: - Properties

    private let osLogger: OSLog

    // MARK: - Initialization

    /// Initialize with configuration
    /// - Parameters:
    ///   - subsystem: Subsystem identifier
    ///   - category: Category identifier
    init(subsystem: String, category: String) {
        osLogger = OSLog(subsystem: subsystem, category: category)
    }

    // MARK: - Public Methods

    /// Log a message with specified level
    /// - Parameters:
    ///   - message: Message to log
    ///   - level: Log level
    func log(message: String, level: LogLevel) {
        let type: OSLogType = switch level {
        case .debug:
            .debug
        case .info:
            .info
        case .warning:
            .default // Use .default for warnings as it's the closest match
        case .error:
            .error
        case .critical:
            .fault
        }

        os_log(
            .init(stringLiteral: message),
            log: osLogger,
            type: type
        )
    }
}
