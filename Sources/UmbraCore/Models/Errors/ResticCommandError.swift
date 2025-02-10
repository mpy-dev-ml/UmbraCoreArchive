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

    public var errorDescription: String {
        switch self {
        case .executionFailed(let details):
            return "Command execution failed: \(details)"
        case .timeout(let command):
            return "Command timed out: \(command)"
        case .interrupted:
            return "Command was interrupted"
        case .invalidArguments(let details):
            return "Invalid command arguments: \(details)"
        case .unsupportedCommand(let command):
            return "Unsupported command: \(command)"
        }
    }

    public var failureReason: String? {
        switch self {
        case .executionFailed(let details):
            return "The command failed to execute properly: \(details)"
        case .timeout(let command):
            return "The command '\(command)' exceeded its time limit"
        case .interrupted:
            return "The command was interrupted before completion"
        case .invalidArguments(let details):
            return "The provided command arguments are invalid: \(details)"
        case .unsupportedCommand(let command):
            return "The command '\(command)' is not supported"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .executionFailed:
            return "Check system resources and try again"
        case .timeout:
            return "Consider increasing the timeout duration or optimizing the command"
        case .interrupted:
            return "Run the command again when ready"
        case .invalidArguments:
            return "Check the command documentation and correct the arguments"
        case .unsupportedCommand:
            return "Use a supported command or update to a newer version"
        }
    }
}
