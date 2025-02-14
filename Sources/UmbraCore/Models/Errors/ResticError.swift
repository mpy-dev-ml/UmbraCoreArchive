import Foundation

/// Represents errors that can occur during Restic operations
public enum ResticError: ResticErrorProtocol, LocalizedError {
    case commandNotFound(path: String)
    case invalidArguments(command: String, details: String)
    case invalidEnvironment(details: String)
    case invalidState(details: String)
    case operationFailed(command: String, details: String)
    case permissionDenied(path: String)
    case resourceBusy(path: String)
    case systemError(details: String)
    case timeout(command: String, duration: TimeInterval)

    // MARK: - ResticErrorProtocol

    public var command: String? {
        switch self {
        case .commandNotFound(let path):
            path

        case .invalidArguments(let command, _):
            command

        case .operationFailed(let command, _):
            command

        case .timeout(let command, _):
            command

        case .invalidEnvironment, .invalidState, .permissionDenied, .resourceBusy, .systemError:
            nil
        }
    }

    public var contextInfo: [String: String] {
        switch self {
        case .commandNotFound(let path):
            ["path": path]

        case let .invalidArguments(command, details):
            [
                "command": command,
                "details": details
            ]

        case .invalidEnvironment(let details):
            ["details": details]

        case .invalidState(let details):
            ["details": details]

        case let .operationFailed(command, details):
            [
                "command": command,
                "details": details
            ]

        case .permissionDenied(let path):
            ["path": path]

        case .resourceBusy(let path):
            ["path": path]

        case .systemError(let details):
            ["details": details]

        case let .timeout(command, duration):
            [
                "command": command,
                "duration": "\(duration)"
            ]
        }
    }

    public var exitCode: Int32 {
        switch self {
        case .commandNotFound: 127
        case .invalidArguments: 2
        case .invalidEnvironment: 3
        case .invalidState: 4
        case .operationFailed: 5
        case .permissionDenied: 13
        case .resourceBusy: 16
        case .systemError: 1
        case .timeout: 124
        }
    }

    public var errorType: ResticErrorType {
        switch self {
        case .commandNotFound, .invalidArguments:
            .configuration

        case .invalidEnvironment:
            .system

        case .invalidState:
            .validation

        case .operationFailed:
            .operation

        case .permissionDenied:
            .permission

        case .resourceBusy:
            .resource

        case .systemError:
            .system

        case .timeout:
            .system
        }
    }

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .commandNotFound(let path):
            "Restic command not found at \(path)"

        case let .invalidArguments(command, details):
            "Invalid arguments for command '\(command)': \(details)"

        case .invalidEnvironment(let details):
            "Invalid environment configuration: \(details)"

        case .invalidState(let details):
            "Invalid state: \(details)"

        case let .operationFailed(command, details):
            "Operation '\(command)' failed: \(details)"

        case .permissionDenied(let path):
            "Permission denied: \(path)"

        case .resourceBusy(let path):
            "Resource busy: \(path)"

        case .systemError(let details):
            "System error: \(details)"

        case let .timeout(command, duration):
            "Command '\(command)' timed out after \(duration) seconds"
        }
    }

    public var failureReason: String? {
        switch self {
        case .commandNotFound:
            "The Restic command could not be found in the system path"

        case .invalidArguments:
            "The provided command arguments are invalid or incomplete"

        case .invalidEnvironment:
            "The environment is not properly configured"

        case .invalidState:
            "The system is in an invalid state for this operation"

        case .operationFailed:
            "The requested operation could not be completed"

        case .permissionDenied:
            "Insufficient permissions to perform the operation"

        case .resourceBusy:
            "The requested resource is currently in use"

        case .systemError:
            "A system-level error occurred"

        case .timeout:
            "The operation took too long to complete"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .commandNotFound:
            "Install Restic or verify the installation path"

        case .invalidArguments:
            "Check the command syntax and try again"

        case .invalidEnvironment:
            "Check environment variables and configuration"

        case .invalidState:
            "Try restarting the application"

        case .operationFailed:
            "Check the error details and try again"

        case .permissionDenied:
            "Check file permissions and user access rights"

        case .resourceBusy:
            "Wait for the resource to become available"

        case .systemError:
            "Check system logs for more details"

        case .timeout:
            "Consider increasing the timeout duration"
        }
    }
}
