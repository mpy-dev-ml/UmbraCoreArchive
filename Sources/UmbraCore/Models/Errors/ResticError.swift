import Foundation

/// A type that represents a Restic error with exit code and context information
///
/// This protocol defines the properties and methods that a Restic error type must implement.
@objc
public protocol ResticErrorProtocol: LocalizedError {
    /// The exit code associated with the error
    var exitCode: Int32 { get }
    /// The command that was being executed when the error occurred
    var command: String? { get }
    /// Additional context about the error
    var context: [String: Any]? { get }
    /// Creates an error instance from an exit code if applicable
    static func from(exitCode: Int32) -> Self?
}

/// Default implementation for ResticErrorProtocol
public extension ResticErrorProtocol {
    /// The exit code associated with the error
    var exitCode: Int32 {
        // Use raw value if available (for enums)
        if let rawRepresentable = self as? RawRepresentable,
           let intValue = rawRepresentable.rawValue as? Int {
            return Int32(intValue)
        }
        return -1
    }
    /// Additional context about the error
    var context: [String: Any]? {
        nil
    }
}

/// Utility for creating Restic errors from exit codes
public enum ResticError {
    /// Creates a specific Restic error type from an exit code
    ///
    /// This method tries each error type in priority order and returns the first matching error.
    public static func from(exitCode: Int32) -> (any ResticErrorProtocol)? {
        // Try each error type in priority order
        if let error = ResticCommandError.from(exitCode: exitCode) {
            return error
        }
        if let error = ResticRepositoryError.from(exitCode: exitCode) {
            return error
        }
        if let error = ResticOperationError.from(exitCode: exitCode) {
            return error
        }
        if let error = ResticSystemError.from(exitCode: exitCode) {
            return error
        }
        return nil
    }
    /// Creates a descriptive error message from an exit code
    ///
    /// This method returns a human-readable error message based on the exit code.
    public static func description(for exitCode: Int32) -> String {
        if let error = from(exitCode: exitCode) {
            return error.localizedDescription
        }
        return "Unknown error occurred (exit code: \(exitCode))"
    }
}

/// Represents errors that can occur during restic operations.
public enum ResticError: Error {
    case commandError(ResticCommandError)
    case operationError(ResticOperationError)
    case repositoryError(ResticRepositoryError)
    case systemError(ResticSystemError)
}

extension ResticError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .commandError(let error): error.localizedDescription
        case .operationError(let error): error.localizedDescription
        case .repositoryError(let error): error.localizedDescription
        case .systemError(let error): error.localizedDescription
        }
    }
    public var failureReason: String? {
        switch self {
        case .commandError(let error): error.failureReason
        case .operationError(let error): error.failureReason
        case .repositoryError(let error): error.failureReason
        case .systemError(let error): error.failureReason
        }
    }
    public var recoverySuggestion: String? {
        switch self {
        case .commandError(let error): error.recoverySuggestion
        case .operationError(let error): error.recoverySuggestion
        case .repositoryError(let error): error.recoverySuggestion
        case .systemError(let error): error.recoverySuggestion
        }
    }
}

extension ResticError: ResticErrorProtocol {
    public var underlyingError: Error? {
        switch self {
        case .commandError(let error): error
        case .operationError(let error): error
        case .repositoryError(let error): error
        case .systemError(let error): error
        }
    }
    public var isRecoverable: Bool {
        switch self {
        case .commandError(let error as ResticErrorProtocol),
             .operationError(let error as ResticErrorProtocol),
             .repositoryError(let error as ResticErrorProtocol),
             .systemError(let error as ResticErrorProtocol):
            error.isRecoverable
        default: false
        }
    }
    public var requiresUserIntervention: Bool {
        switch self {
        case .commandError(let error as ResticErrorProtocol),
             .operationError(let error as ResticErrorProtocol),
             .repositoryError(let error as ResticErrorProtocol),
             .systemError(let error as ResticErrorProtocol):
            error.requiresUserIntervention
        default: true
        }
    }
    public var shouldRetry: Bool {
        switch self {
        case .commandError(let error as ResticErrorProtocol),
             .operationError(let error as ResticErrorProtocol),
             .repositoryError(let error as ResticErrorProtocol),
             .systemError(let error as ResticErrorProtocol):
            error.shouldRetry
        default: false
        }
    }
}
