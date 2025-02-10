import Foundation

/// Protocol defining requirements for Restic-specific errors.
public protocol ResticErrorProtocol: LocalizedError {
    /// A localized message describing what error occurred.
    var errorDescription: String { get }
    /// A localized message describing the reason for the failure.
    var failureReason: String { get }
    /// A localized message describing how one might recover from the failure.
    var recoverySuggestion: String { get }
    /// The command that was being executed when the error occurred.
    var command: String? { get }
}
