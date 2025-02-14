@preconcurrency import Foundation

/// Errors that can occur during service operations
@objc
public final class ServiceOperationError: NSObject, ServiceErrorProtocol {
    // MARK: - Error Types

    private enum InternalErrorType {
        case operationFailed(service: String, operation: String, reason: String)
        case operationTimeout(service: String, operation: String, duration: TimeInterval)
    }

    // MARK: - Properties

    private let internalErrorType: InternalErrorType

    // MARK: - ServiceErrorProtocol Conformance

    /// The error type associated with this error
    public var errorType: Any {
        internalErrorType
    }

    /// Service name associated with the error
    public var serviceName: String {
        switch internalErrorType {
        case let .operationFailed(service, _, _),
            let .operationTimeout(service, _, _):
            service
        }
    }

    /// A human-readable description of the error
    public var localizedDescription: String {
        switch internalErrorType {
        case let .operationFailed(service, operation, reason):
            "The operation '\(operation)' in service '\(service)' failed: \(reason)"

        case let .operationTimeout(service, operation, duration):
            String(format: "The operation '%@' in service '%@' timed out after %.1f seconds",
                  operation, service, duration)
        }
    }

    /// A suggestion for how to recover from the error
    public var recoverySuggestion: String? {
        switch internalErrorType {
        case .operationFailed:
            "Please try the operation again. If the problem persists, check the logs for more details."

        case .operationTimeout:
            "Please check your network connection and try again. If the problem persists, the service might be experiencing high load."
        }
    }

    /// The reason for the failure, if available
    public var failureReason: String? {
        switch internalErrorType {
        case let .operationFailed(_, _, reason):
            reason

        case let .operationTimeout(_, _, duration):
            "Operation exceeded time limit of \(String(format: "%.1f", duration)) seconds"
        }
    }

    /// Name of the operation that failed or timed out
    public var operationName: String {
        switch internalErrorType {
        case let .operationFailed(_, operation, _),
            let .operationTimeout(_, operation, _):
            operation
        }
    }

    /// Duration before timeout if applicable
    public var timeoutDuration: TimeInterval? {
        switch internalErrorType {
        case let .operationTimeout(_, _, duration):
            duration

        default:
            nil
        }
    }

    /// The error code associated with this error
    public var errorCode: Int {
        switch internalErrorType {
        case .operationFailed: 1
        case .operationTimeout: 2
        }
    }

    /// The error domain associated with this error
    public static var errorDomain: String {
        "dev.mpy.umbracore.service.operation"
    }

    // MARK: - Initialization

    /// Create an error for a failed operation
    /// - Parameters:
    ///   - service: Name of the service
    ///   - operation: Name of the operation
    ///   - reason: Reason for the failure
    public init(service: String, operation: String, reason: String) {
        internalErrorType = .operationFailed(
            service: service,
            operation: operation,
            reason: reason
        )
        super.init()
    }

    /// Create an error for an operation timeout
    /// - Parameters:
    ///   - service: Name of the service
    ///   - operation: Name of the operation
    ///   - duration: Duration before timeout
    public init(service: String, operation: String, timeout duration: TimeInterval) {
        internalErrorType = .operationTimeout(
            service: service,
            operation: operation,
            duration: duration
        )
        super.init()
    }
}
