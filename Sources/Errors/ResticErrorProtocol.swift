@preconcurrency import Foundation

// MARK: - ResticErrorProtocol

/// Protocol defining requirements for Restic-specific errors
/// protocol for handling resticErrorProtocol:
@objc
public protocol ResticErrorProtocol: Error {
    /// The exit code associated with the error
    var exitCode: Int32 { get }

    /// The command that failed
    var command: String { get }

    /// The output from the command
    var output: String? { get }

    /// A localized message describing what error occurred
    var localizedDescription: String { get }

    /// A localized message describing the reason for the failure
    var localizedFailureReason: String? { get }

    /// A localized message describing how to recover from the error
    var localizedRecoverySuggestion: String? { get }

    /// The underlying error, if any
    var underlyingError: Error? { get }
}

// MARK: - Default Implementations

public extension ResticErrorProtocol {
    var localizedDescription: String {
        "Restic command '\(command)' failed with exit code \(exitCode)"
    }

    var localizedFailureReason: String? {
        output
    }

    var localizedRecoverySuggestion: String? {
        "Check the command output for details and try again"
    }
}
