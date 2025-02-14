@preconcurrency import Foundation

// MARK: - ServiceErrorProtocol

/// Protocol defining common functionality for service-related errors
public protocol ServiceErrorProtocol: Error {
    /// The service name associated with the error
    var serviceName: String { get }

    /// The error type associated with this error
    var errorType: Any { get }

    /// A human-readable description of the error
    var localizedDescription: String { get }

    /// A suggestion for how to recover from the error
    var recoverySuggestion: String? { get }

    /// The reason for the failure, if available
    var failureReason: String? { get }
}

// MARK: - Error Conformance

public extension ServiceErrorProtocol {
    /// Convert to Error
    var asError: Error {
        let userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: localizedDescription,
            "serviceName": serviceName
        ]
        .merging(
            [
                NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion,
                NSLocalizedFailureReasonErrorKey: failureReason
            ]
            .compactMapValues { $0 }
        ) { current, _ in current }

        return Error(
            domain: "dev.mpy.umbracore.service",
            code: 0,
            userInfo: userInfo
        )
    }
}
