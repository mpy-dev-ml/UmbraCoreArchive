import Foundation

/// Errors that can occur during service operations
public enum ServiceError: LocalizedError {
    /// Service not found
    case serviceNotFound(String)
    /// Invalid service type
    case invalidServiceType(String)
    /// Service creation failed
    case serviceCreationFailed(String)
    /// Service configuration failed
    case serviceConfigurationFailed(String)
    /// Service initialization failed
    case serviceInitializationFailed(String)
    /// Service registration failed
    case serviceRegistrationFailed(String)
    /// Invalid configuration
    case invalidConfiguration(String)
    /// Operation failed
    case operationFailed(String)

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case let .serviceNotFound(service):
            "Service not found: \(service)"
        case let .invalidServiceType(type):
            "Invalid service type: \(type)"
        case let .serviceCreationFailed(reason):
            "Failed to create service: \(reason)"
        case let .serviceConfigurationFailed(reason):
            "Failed to configure service: \(reason)"
        case let .serviceInitializationFailed(reason):
            "Failed to initialize service: \(reason)"
        case let .serviceRegistrationFailed(reason):
            "Failed to register service: \(reason)"
        case let .invalidConfiguration(reason):
            "Invalid service configuration: \(reason)"
        case let .operationFailed(reason):
            "Service operation failed: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .serviceNotFound:
            "Check service name and registration"
        case .invalidServiceType:
            "Check service type and protocol"
        case .serviceCreationFailed:
            "Check service dependencies"
        case .serviceConfigurationFailed:
            "Check service configuration"
        case .serviceInitializationFailed:
            "Check service initialization"
        case .serviceRegistrationFailed:
            "Check service registration"
        case .invalidConfiguration:
            "Check factory configuration"
        case .operationFailed:
            "Try the operation again"
        }
    }

    public var helpAnchor: String? {
        switch self {
        case .serviceNotFound:
            "service_lookup"
        case .invalidServiceType:
            "service_types"
        case .serviceCreationFailed:
            "service_creation"
        case .serviceConfigurationFailed:
            "service_configuration"
        case .serviceInitializationFailed:
            "service_initialization"
        case .serviceRegistrationFailed:
            "service_registration"
        case .invalidConfiguration:
            "factory_configuration"
        case .operationFailed:
            "service_troubleshooting"
        }
    }
}
