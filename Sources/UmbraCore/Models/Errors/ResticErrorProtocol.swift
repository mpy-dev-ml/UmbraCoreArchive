@preconcurrency import Foundation

// MARK: - ResticErrorProtocol

/// Protocol defining requirements for Restic-specific errors
@objc
public protocol ResticErrorProtocol: Error {
    /// The exit code associated with the error
    var exitCode: Int32 { get }

    /// The command that was being executed when the error occurred
    @objc optional var command: String? { get }

    /// Additional context about the error
    @objc optional var context: [String: Any]? { get }

    /// Creates an error instance from an exit code if applicable
    static func from(exitCode: Int32) -> Self?
}

// MARK: - Default Implementations

public extension ResticErrorProtocol {
    var exitCode: Int32 {
        // Use raw value if available (for enums)
        if let rawRepresentable = self as? RawRepresentable,
           let intValue = rawRepresentable.rawValue as? Int
        {
            return Int32(intValue)
        }
        return 1 // Default error code
    }

    var command: String? { nil }
    var context: [String: Any]? { nil }
}

// MARK: - LocalizedError Conformance

public extension ResticErrorProtocol where Self: LocalizedError {
    var errorDescription: String? {
        let commandInfo = command.map { " while executing '\($0)'" } ?? ""
        return "\(String(describing: self))\(commandInfo) (exit code: \(exitCode))"
    }

    var failureReason: String? {
        context?["reason"] as? String
    }

    var recoverySuggestion: String? {
        context?["suggestion"] as? String
    }
}
