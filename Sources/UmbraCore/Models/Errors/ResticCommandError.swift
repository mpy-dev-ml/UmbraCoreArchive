import Foundation

/// Represents errors that can occur during command execution
@objc
public enum ResticCommandError: Int, ResticErrorProtocol, LocalizedError {
    /// Indicates that the command execution failed
    case executionFailed = 1
    /// Indicates that the command timed out
    case timeout = 124
    /// Indicates that the command was interrupted
    case interrupted = 130
    /// Indicates that the command had invalid arguments
    case invalidArguments = 64
    /// Indicates that the command is not supported
    case unsupportedCommand = 127

    // MARK: - ResticErrorProtocol

    public static func from(exitCode: Int32) -> Self? {
        switch exitCode {
        case 1: .executionFailed
        case 124: .timeout
        case 130: .interrupted
        case 64: .invalidArguments
        case 127: .unsupportedCommand
        default: nil
        }
    }

    public var context: [String: Any]? {
        var context: [String: Any] = [:]
        context["category"] = "command"
        return context
    }

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .executionFailed:
            "Command execution failed"

        case .timeout:
            "Command timed out"

        case .interrupted:
            "Command was interrupted"

        case .invalidArguments:
            "Invalid command arguments"

        case .unsupportedCommand:
            "Unsupported command"
        }
    }

    public var failureReason: String? {
        switch self {
        case .executionFailed:
            "The command failed to execute properly"

        case .timeout:
            "The command exceeded its time limit"

        case .interrupted:
            "The command was interrupted by a signal"

        case .invalidArguments:
            "The command received invalid arguments"

        case .unsupportedCommand:
            "The command is not supported by this version"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .executionFailed:
            "Check the command output for details"

        case .timeout:
            "Try increasing the timeout duration"

        case .interrupted:
            "Try running the command again"

        case .invalidArguments:
            "Check the command arguments"

        case .unsupportedCommand:
            "Check the supported commands list"
        }
    }
}
