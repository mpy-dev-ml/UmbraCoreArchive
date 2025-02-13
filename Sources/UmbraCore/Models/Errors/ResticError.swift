@preconcurrency import Foundation

// MARK: - ResticError

/// Represents errors that can occur during Restic operations
@frozen // Mark as frozen for better Swift 6 compatibility
@objc
public final class ResticError: NSObject, ResticErrorProtocol, LocalizedError, Sendable {
    // MARK: - Error Types

    private enum ErrorType {
        case commandError(Error?)
        case operationError(Error?)
        case repositoryError(String)
        case configurationError(String)
        case authenticationError(String)
        case networkError(String)
        case unknown(String)
    }

    // MARK: - Properties

    private let errorType: ErrorType
    private var contextInfo: [String: Any]

    // MARK: - ResticErrorProtocol

    public static func from(exitCode: Int32) -> ResticError? {
        switch exitCode {
        case 1: ResticError(type: .commandError(nil))
        case 2: ResticError(type: .operationError(nil))
        case 3: ResticError(type: .repositoryError("Repository access failed"))
        case 4: ResticError(type: .configurationError("Invalid configuration"))
        case 5: ResticError(type: .authenticationError("Authentication failed"))
        case 6: ResticError(type: .networkError("Network error"))
        default: nil
        }
    }

    public var command: String? {
        context?["command"] as? String
    }

    public var context: [String: Any]? {
        contextInfo
    }

    public var errorCode: Int {
        switch errorType {
        case .commandError: 1
        case .operationError: 2
        case .repositoryError: 3
        case .configurationError: 4
        case .authenticationError: 5
        case .networkError: 6
        case .unknown: 7
        }
    }

    public static var errorDomain: String {
        "dev.mpy.umbracore.restic"
    }

    // MARK: - LocalizedError

    override public var localizedDescription: String {
        switch errorType {
        case let .commandError(error):
            "Command execution failed: \(error?.localizedDescription ?? "Unknown error")"
        case let .operationError(error):
            "Operation failed: \(error?.localizedDescription ?? "Unknown error")"
        case let .repositoryError(message):
            "Repository error: \(message)"
        case let .configurationError(message):
            "Configuration error: \(message)"
        case let .authenticationError(message):
            "Authentication error: \(message)"
        case let .networkError(message):
            "Network error: \(message)"
        case let .unknown(message):
            "Unknown error: \(message)"
        }
    }

    public var errorDescription: String? {
        localizedDescription
    }

    public var failureReason: String? {
        switch errorType {
        case let .commandError(error):
            error?.localizedDescription
        case let .operationError(error):
            error?.localizedDescription
        case let .repositoryError(message),
             let .configurationError(message),
             let .authenticationError(message),
             let .networkError(message),
             let .unknown(message):
            message
        }
    }

    public var recoverySuggestion: String? {
        switch errorType {
        case .commandError:
            "Check the command syntax and try again"
        case .operationError:
            "Verify the operation parameters and retry"
        case .repositoryError:
            "Ensure the repository is accessible and properly configured"
        case .configurationError:
            "Review and correct the configuration settings"
        case .authenticationError:
            "Check your credentials and try again"
        case .networkError:
            "Check your network connection and try again"
        case .unknown:
            "Try the operation again or check the logs for more details"
        }
    }

    // MARK: - Initialization

    public convenience init(command error: Error?) {
        self.init(type: .commandError(error))
    }

    public convenience init(operation error: Error?) {
        self.init(type: .operationError(error))
    }

    public convenience init(repository message: String) {
        self.init(type: .repositoryError(message))
    }

    public convenience init(configuration message: String) {
        self.init(type: .configurationError(message))
    }

    public convenience init(authentication message: String) {
        self.init(type: .authenticationError(message))
    }

    public convenience init(network message: String) {
        self.init(type: .networkError(message))
    }

    public convenience init(unknown message: String) {
        self.init(type: .unknown(message))
    }

    private init(type: ErrorType, context: [String: Any] = [:]) {
        errorType = type
        contextInfo = context
        super.init()
    }

    // MARK: - Context Management

    public func with(context: [String: Any]) -> ResticError {
        ResticError(type: errorType, context: context)
    }

    public func adding(context key: String, value: Any) -> ResticError {
        var newContext = contextInfo
        newContext[key] = value
        return ResticError(type: errorType, context: newContext)
    }
}

// MARK: - ResticErrorProtocol

public extension ResticError {
    var underlyingError: Error? {
        switch errorType {
        case let .commandError(error),
             let .operationError(error):
            error
        default: nil
        }
    }

    var isRecoverable: Bool {
        switch errorType {
        case .commandError,
             .operationError,
             .repositoryError,
             .configurationError,
             .authenticationError,
             .networkError,
             .unknown:
            false
        }
    }

    var requiresUserIntervention: Bool {
        switch errorType {
        case .commandError,
             .operationError,
             .repositoryError,
             .configurationError,
             .authenticationError,
             .networkError,
             .unknown:
            true
        }
    }

    var shouldRetry: Bool {
        switch errorType {
        case .commandError,
             .operationError,
             .repositoryError,
             .configurationError,
             .authenticationError,
             .networkError,
             .unknown:
            false
        }
    }
}
