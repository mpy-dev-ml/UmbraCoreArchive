import Foundation

/// Errors that can occur during service operations
@objc public enum ServiceOperationError: Int, ServiceErrorProtocol {
    /// Operation failed
    case operationFailed(
        service: String,
        operation: String,
        reason: String
    )

    /// Operation timeout
    case operationTimeout(
        service: String,
        operation: String,
        duration: TimeInterval
    )

    // MARK: Public

    // MARK: - ServiceErrorProtocol

    public var serviceName: String {
        switch self {
        case let .operationFailed(service, _, _),
             let .operationTimeout(service, _, _):
            service
        }
    }

    public var errorDescription: String? {
        switch self {
        case let .operationFailed(service, operation, reason):
            "Operation \(operation) failed for service \(service): \(reason)"
        case let .operationTimeout(service, operation, duration):
            "Operation \(operation) timed out after \(duration)s for service \(service)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .operationFailed:
            "Check operation parameters and try again"
        case .operationTimeout:
            "Consider increasing timeout duration or check for performance issues"
        }
    }

    public var failureReason: String? {
        switch self {
        case let .operationFailed(_, _, reason):
            reason
        default:
            nil
        }
    }
}
