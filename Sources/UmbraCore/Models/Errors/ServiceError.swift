import Foundation

/// Errors that can occur in services
public enum ServiceError: LocalizedError {
    /// Service not found
    case serviceNotFound(String)
    /// Invalid service type
    case invalidServiceType(expected: String, actual: String)
    /// Service already registered
    case serviceAlreadyRegistered(String)
    /// Service not usable
    case serviceNotUsable(String)
    /// Service not initialized
    case serviceNotInitialized(String)
    /// Operation failed
    case operationFailed(operation: String, reason: String)
    /// Operation timed out
    case timeout(operation: String, duration: TimeInterval)

    public var errorDescription: String? {
        switch self {
        case let .serviceNotFound(name):
            "Service not found: \(name)"

        case let .invalidServiceType(expected, actual):
            "Invalid service type. Expected: \(expected), got: \(actual)"

        case let .serviceAlreadyRegistered(name):
            "Service already registered: \(name)"

        case let .serviceNotUsable(name):
            "Service not usable: \(name)"

        case let .serviceNotInitialized(name):
            "Service not initialised: \(name)"

        case let .operationFailed(operation, reason):
            "Operation '\(operation)' failed: \(reason)"

        case let .timeout(operation, duration):
            "Operation '\(operation)' timed out after \(duration) seconds"
        }
    }

    public var failureReason: String? {
        switch self {
        case let .serviceNotFound(name):
            "The requested service '\(name)' could not be found in the service registry"

        case let .invalidServiceType(expected, actual):
            "The service type '\(actual)' does not match the expected type '\(expected)'"

        case let .serviceAlreadyRegistered(name):
            "A service with name '\(name)' is already registered"

        case let .serviceNotUsable(name):
            "The service '\(name)' is not in a usable state"

        case let .serviceNotInitialized(name):
            "The service '\(name)' has not been properly initialised"

        case let .operationFailed(operation, reason):
            "The operation '\(operation)' failed to complete: \(reason)"

        case let .timeout(operation, duration):
            "The operation '\(operation)' exceeded the time limit of \(duration) seconds"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .serviceNotFound:
            "Check if the service name is correct and the service is properly registered"

        case .invalidServiceType:
            "Ensure you are requesting the correct service type"

        case .serviceAlreadyRegistered:
            "Use a different service name or remove the existing service first"

        case .serviceNotUsable:
            "Check the service status and ensure all dependencies are available"

        case .serviceNotInitialized:
            "Ensure the service is properly initialised before use"

        case .operationFailed:
            "Check the error details and try the operation again"

        case .timeout:
            "Try the operation again or increase the timeout duration"
        }
    }
}
