import Foundation

public extension ServiceFactory {
    /// Validate service factory configuration
    /// - Returns: true if configuration is valid
    /// - Throws: ServiceFactoryError if validation fails
    static func validateConfiguration() throws -> Bool {
        try queue.sync {
            // Validate development configuration
            if configuration.developmentEnabled {
                guard developmentConfiguration.artificialDelay >= 0 else {
                    throw ServiceFactoryError.invalidConfiguration(
                        "Artificial delay must be non-negative"
                    )
                }
            }

            return true
        }
    }

    /// Validate service creation
    /// - Parameter service: Service to validate
    /// - Returns: true if service is valid
    /// - Throws: ServiceFactoryError if validation fails
    static func validateService(_ service: Any) throws -> Bool {
        try queue.sync {
            // Validate service type
            switch service {
            case let sandboxed as BaseSandboxedService:
                return try sandboxed.validateSandboxCompliance()

            case let logging as LoggingService:
                return logging.logger != nil

            default:
                throw ServiceFactoryError.invalidServiceType(
                    String(describing: type(of: service))
                )
            }
        }
    }
}

// MARK: - ServiceFactoryError

/// Errors that can occur in the service factory
public enum ServiceFactoryError: LocalizedError {
    /// Invalid configuration
    case invalidConfiguration(String)
    /// Invalid service type
    case invalidServiceType(String)
    /// Service creation failed
    case serviceCreationFailed(String)

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case let .invalidConfiguration(reason):
            "Invalid service factory configuration: \(reason)"
        case let .invalidServiceType(type):
            "Invalid service type: \(type)"
        case let .serviceCreationFailed(service):
            "Failed to create service: \(service)"
        }
    }
}
