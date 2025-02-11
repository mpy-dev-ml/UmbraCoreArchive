import Foundation

/// Errors that can occur during service operations
@frozen
@objc
public final class ServiceOperationError: NSObject, ServiceErrorProtocol {
    // MARK: - Error Types

    private enum ErrorType {
        case operationFailed(service: String, operation: String, reason: String)
        case operationTimeout(service: String, operation: String, duration: TimeInterval)
    }

    // MARK: - Properties

    private let errorType: ErrorType

    /// Service name associated with the error
    public var serviceName: String {
        switch errorType {
        case let .operationFailed(service, _, _),
             let .operationTimeout(service, _, _):
            service
        }
    }

    /// Name of the operation that failed or timed out
    public var operationName: String {
        switch errorType {
        case let .operationFailed(_, operation, _),
             let .operationTimeout(_, operation, _):
            operation
        }
    }

    /// Reason for operation failure if applicable
    public var failureReason: String? {
        switch errorType {
        case let .operationFailed(_, _, reason):
            reason
        default:
            nil
        }
    }

    /// Duration before timeout if applicable
    public var timeoutDuration: TimeInterval? {
        switch errorType {
        case let .operationTimeout(_, _, duration):
            duration
        default:
            nil
        }
    }

    // MARK: - ServiceErrorProtocol

    public var errorCode: Int {
        switch errorType {
        case .operationFailed: 1
        case .operationTimeout: 2
        }
    }

    public static var errorDomain: String {
        "dev.mpy.umbracore.service.operation"
    }

    override public var localizedDescription: String {
        switch errorType {
        case let .operationFailed(service, operation, reason):
            "Service '\(service)' operation '\(operation)' failed: \(reason)"
        case let .operationTimeout(service, operation, duration):
            "Service '\(service)' operation '\(operation)' timed out after \(String(format: "%.1f", duration)) seconds"
        }
    }

    override public var recoverySuggestion: String? {
        switch errorType {
        case .operationFailed:
            "Check the failure reason and try the operation again"
        case .operationTimeout:
            "Consider increasing the operation timeout or check for system performance issues"
        }
    }

    // MARK: - Initialization

    public convenience init(service: String, operation: String, reason: String) {
        self.init(type: .operationFailed(service: service, operation: operation, reason: reason))
    }

    public convenience init(service: String, operation: String, duration: TimeInterval) {
        self.init(type: .operationTimeout(service: service, operation: operation, duration: duration))
    }

    private init(type: ErrorType) {
        errorType = type
        super.init()
    }
}
