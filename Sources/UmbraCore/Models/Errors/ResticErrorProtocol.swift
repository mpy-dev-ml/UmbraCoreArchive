import Foundation

/// Protocol defining requirements for Restic-specific errors
public protocol ResticErrorProtocol: LocalizedError, CustomStringConvertible {
    /// The command that was being executed when the error occurred
    var command: String? { get }

    /// Additional context about the error
    var contextInfo: [String: String] { get }

    /// The exit code of the command, if applicable
    var exitCode: Int32 { get }

    /// The underlying error type
    var errorType: ResticErrorType { get }

    /// Whether the error is recoverable
    var isRecoverable: Bool { get }

    /// Stack trace at the time of error
    var stackTrace: [String] { get }
}

/// Types of Restic errors
public enum ResticErrorType: String, Codable {
    case configuration = "Configuration Error"
    case permission = "Permission Error"
    case resource = "Resource Error"
    case system = "System Error"
    case network = "Network Error"
    case validation = "Validation Error"
    case operation = "Operation Error"
    case unknown = "Unknown Error"
}

// MARK: - Default Implementations

public extension ResticErrorProtocol {
    var isRecoverable: Bool {
        switch errorType {
        case .configuration, .permission, .validation:
            true

        case .resource, .system, .network, .operation, .unknown:
            false
        }
    }
    
    var stackTrace: [String] {
        Thread.callStackSymbols
    }
    
    var description: String {
        var desc = "[\(errorType.rawValue)] \(localizedDescription)"
        if let cmd = command {
            desc += "\nCommand: \(cmd)"
        }
        if !contextInfo.isEmpty {
            desc += "\nContext: \(contextInfo)"
        }
        return desc
    }
}
