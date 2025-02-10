import Foundation

/// Errors that can occur during service lifecycle operations
@objc public enum ServiceLifecycleError: Int, ServiceErrorProtocol {
    /// Service not initialised
    case notInitialized(String)

    /// Service already initialised
    case alreadyInitialized(String)

    /// Service initialisation failed
    case initializationFailed(service: String, reason: String)

    // MARK: Public

    // MARK: - ServiceErrorProtocol

    public var serviceName: String {
        switch self {
        case let .notInitialized(service),
             let .alreadyInitialized(service):
            service
        case let .initializationFailed(service, _):
            service
        }
    }

    public var errorDescription: String? {
        switch self {
        case let .notInitialized(service):
            "Service not initialised: \(service)"
        case let .alreadyInitialized(service):
            "Service already initialised: \(service)"
        case let .initializationFailed(service, reason):
            "Failed to initialise service \(service): \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .notInitialized:
            "Initialise the service before using it"
        case .alreadyInitialized:
            "Ensure service is not already initialised before initialising"
        case .initializationFailed:
            "Check service configuration and dependencies"
        }
    }

    public var failureReason: String? {
        switch self {
        case let .initializationFailed(_, reason):
            reason
        default:
            nil
        }
    }
}
