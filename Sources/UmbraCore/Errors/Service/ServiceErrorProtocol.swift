import Foundation

// MARK: - ServiceErrorProtocol

/// Protocol defining common functionality for service-related errors
@objc public protocol ServiceErrorProtocol: LocalizedError {
    /// The service name associated with the error
    var serviceName: String { get }

    /// A human-readable description of what went wrong
    var errorDescription: String? { get }

    /// A suggestion for how to recover from the error
    var recoverySuggestion: String? { get }

    /// The reason for the failure, if available
    var failureReason: String? { get }
}

// MARK: - Default Implementations

public extension ServiceErrorProtocol {
    var failureReason: String? {
        // Default implementation returns nil
        nil
    }
}
