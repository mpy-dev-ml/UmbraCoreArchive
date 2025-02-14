@preconcurrency import Foundation

/// Errors that can occur in services
public enum ServiceError: Error, Sendable {
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
}

// MARK: - Service Error Types

/// Supporting types for ServiceError
public extension ServiceError {
    /// Service state information
    struct ServiceState: CustomStringConvertible {
        // MARK: Lifecycle

        /// Creates a new service state
        /// - Parameters:
        ///   - name: Name of the service
        ///   - state: Current state
        public init(
            name: String,
            state: String
        ) {
            self.name = name
            self.state = state
        }

        // MARK: Internal

        /// Name of the service
        public let name: String
        /// Current state
        public let state: String

        public var description: String {
            "\(name): \(state)"
        }
    }
}

// MARK: - ServiceError + LocalizedError

extension ServiceError: LocalizedError {
    /// Formats an error message with service and details
    private func formatError(
        _ message: String,
        service: String,
        details: String
    ) -> String {
        "\(message) - Service: \(service), \(details)"
    }

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
            "Service not initialized: \(name)"

        case let .operationFailed(operation, reason):
            "Operation '\(operation)' failed: \(reason)"

        case let .timeout(operation, duration):
            "Operation '\(operation)' timed out after \(duration) seconds"
        }
    }
}
