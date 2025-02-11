import Foundation
import os.log

/// A protocol defining core logging operations for the application.
///
/// `LoggerProtocol` provides a standardised interface for logging at different
/// severity levels, including:
/// - Debug: Detailed information for debugging
/// - Info: General information about system operation
/// - Warning: Potential issues that need attention
/// - Error: Serious problems that need immediate attention
/// - Critical: System-critical issues that require immediate action
///
/// Each logging method captures contextual information:
/// - Source file
/// - Function name
/// - Line number
/// - Custom message
///
/// Example usage:
/// ```swift
/// class SecurityService {
///     private let logger: LoggerProtocol
///
///     init(logger: LoggerProtocol) {
///         self.logger = logger
///     }
///
///     func validateAccess() {
///         logger.info(
///             """
///             Starting access validation for security \
///             service
///             """,
///             file: #file,
///             function: #function,
///             line: #line
///         )
///
///         guard isAccessValid else {
///             logger.error(
///                 """
///                 Access validation failed: invalid \
///                 security token
///                 """,
///                 file: #file,
///                 function: #function,
///                 line: #line
///             )
///             return
///         }
///     }
/// }
/// ```
public protocol LoggerProtocol: Sendable {
    /// Logs a debug message with contextual information.
    ///
    /// Debug logs are used for detailed information that is helpful during
    /// development and troubleshooting. These logs should:
    /// - Be detailed enough to diagnose issues
    /// - Include relevant context
    /// - Be safe to disable in production
    ///
    /// - Parameters:
    ///   - message: The debug message to log
    ///   - file: The source file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line number where the log was called
    func debug(_ message: String, file: String, function: String, line: Int)

    /// Logs an informational message with contextual information.
    ///
    /// Info logs are used for general information about system operation. These logs should:
    /// - Be relevant to system operation
    /// - Be concise and clear
    /// - Not contain sensitive information
    ///
    /// - Parameters:
    ///   - message: The info message to log
    ///   - file: The source file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line number where the log was called
    func info(_ message: String, file: String, function: String, line: Int)

    /// Logs a warning message with contextual information.
    ///
    /// Warning logs are used for potential issues that need attention. These logs should:
    /// - Clearly describe the potential issue
    /// - Include relevant context
    /// - Suggest possible solutions if applicable
    ///
    /// - Parameters:
    ///   - message: The warning message to log
    ///   - file: The source file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line number where the log was called
    func warning(_ message: String, file: String, function: String, line: Int)

    /// Logs an error message with contextual information.
    ///
    /// Error logs are used for serious problems that need immediate attention. These logs should:
    /// - Clearly describe the error
    /// - Include all relevant context
    /// - Include error codes or identifiers if applicable
    ///
    /// - Parameters:
    ///   - message: The error message to log
    ///   - file: The source file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line number where the log was called
    func error(_ message: String, file: String, function: String, line: Int)

    /// Logs a critical message with contextual information.
    ///
    /// Critical logs are used for system-critical issues that require immediate action. These logs should:
    /// - Clearly describe the critical issue
    /// - Include all relevant context
    /// - Include specific actions needed
    /// - Be used sparingly for truly critical issues
    ///
    /// - Parameters:
    ///   - message: The critical message to log
    ///   - file: The source file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line number where the log was called
    func critical(_ message: String, file: String, function: String, line: Int)
}
