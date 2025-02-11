import Foundation

/// Represents errors that can occur during command execution.
public enum ResticCommandError: ResticErrorProtocol {
    /// Indicates that the command execution failed.
    case executionFailed(String)
    /// Indicates that the command timed out.
    case timeout(String)
    /// Indicates that the command was interrupted.
    case interrupted
    /// Indicates that the command had invalid arguments.
    case invalidArguments(String)
    /// Indicates that the command is not supported.
    case unsupportedCommand(String)

    // MARK: Public

    public var errorDescription: String {
        switch self {
        case let .executionFailed(details):
            "Command execution failed: \(details)"
        case let .timeout(command):
            "Command timed out: \(command)"
        case .interrupted:
            "Command was interrupted"
        case let .invalidArguments(details):
            "Invalid command arguments: \(details)"
        case let .unsupportedCommand(command):
            "Unsupported command: \(command)"
        }
    }

    public var failureReason: String? {
        switch self {
        case let .executionFailed(details):
            "The command failed to execute properly: \(details)"
        case let .timeout(command):
            "The command '\(command)' exceeded its time limit"
        case .interrupted:
            "The command was interrupted before completion"
        case let .invalidArguments(details):
            "The provided command arguments are invalid: \(details)"
        case let .unsupportedCommand(command):
            "The command '\(command)' is not supported"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .executionFailed:
            "Check system resources and try again"
        case .timeout:
            "Consider increasing the timeout duration or optimizing the command"
        case .interrupted:
            "Run the command again when ready"
        case .invalidArguments:
            "Check the command documentation and correct the arguments"
        case .unsupportedCommand:
            "Use a supported command or update to a newer version"
        }
    }
}
