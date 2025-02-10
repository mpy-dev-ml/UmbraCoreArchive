import Foundation

/// Type alias for all possible service error types
public typealias ServiceError = ServiceErrorProtocol

/// Extension providing convenience methods for handling service errors
public extension ServiceError {
    /// Checks if the error is related to service initialization
    var isInitializationError: Bool {
        self is ServiceLifecycleError
    }

    /// Checks if the error is related to service state
    var isStateError: Bool {
        self is ServiceStateError
    }

    /// Checks if the error is related to service dependencies
    var isDependencyError: Bool {
        self is ServiceDependencyError
    }

    /// Checks if the error is related to service operations
    var isOperationError: Bool {
        self is ServiceOperationError
    }

    /// Creates a not initialized error
    /// - Parameter service: The name of the service
    /// - Returns: A ServiceLifecycleError
    static func notInitialized(_ service: String) -> ServiceError {
        ServiceLifecycleError.notInitialized(service)
    }

    /// Creates an operation failed error
    /// - Parameters:
    ///   - service: The name of the service
    ///   - operation: The name of the operation
    ///   - reason: The reason for the failure
    /// - Returns: A ServiceOperationError
    static func operationFailed(
        service: String,
        operation: String,
        reason: String
    ) -> ServiceError {
        ServiceOperationError.operationFailed(
            service: service,
            operation: operation,
            reason: reason
        )
    }
}
