@preconcurrency import Foundation

// MARK: - ServiceErrorProtocol

/// Protocol defining common functionality for service-related errors
@objc
public protocol ServiceErrorProtocol: NSObject {
    /// The service name associated with the error
    var serviceName: String { get }

    /// A human-readable description of what went wrong
    var localizedDescription: String { get }

    /// A suggestion for how to recover from the error
    @objc optional var recoverySuggestion: String? { get }

    /// The reason for the failure, if available
    @objc optional var failureReason: String? { get }

    /// The error code associated with this error
    var errorCode: Int { get }

    /// The error domain for this type of error
    static var errorDomain: String { get }
}

// MARK: - Error Conformance

public extension ServiceErrorProtocol {
    /// Convert to NSError
    var asNSError: NSError {
        let userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: localizedDescription,
            "serviceName": serviceName
        ].merging([
            NSLocalizedRecoverySuggestionKey: recoverySuggestion,
            NSLocalizedFailureReasonKey: failureReason
        ].compactMapValues { $0 }) { current, _ in current }

        return NSError(
            domain: Self.errorDomain,
            code: errorCode,
            userInfo: userInfo
        )
    }
}

// MARK: - Default Implementations

public extension ServiceErrorProtocol {
    static var errorDomain: String {
        "dev.mpy.umbracore.service"
    }

    var failureReason: String? {
        nil
    }

    var recoverySuggestion: String? {
        nil
    }
}
