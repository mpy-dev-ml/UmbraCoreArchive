import Foundation

/// Errors that can occur during service lifecycle operations
@frozen
@objc
public final class ServiceLifecycleError: NSObject, ServiceErrorProtocol {
    // MARK: - Error Types

    private enum ErrorType {
        case notInitialized(service: String)
        case alreadyInitialized(service: String)
        case initializationFailed(service: String, reason: String)
    }

    // MARK: - Properties

    private let errorType: ErrorType

    /// Service name associated with the error
    public var serviceName: String {
        switch errorType {
        case let .notInitialized(service),
             let .alreadyInitialized(service),
             let .initializationFailed(service, _):
            service
        }
    }

    /// Reason for initialization failure if applicable
    public var failureReason: String? {
        switch errorType {
        case let .initializationFailed(_, reason):
            reason
        default:
            nil
        }
    }

    // MARK: - ServiceErrorProtocol

    public var errorCode: Int {
        switch errorType {
        case .notInitialized: 1
        case .alreadyInitialized: 2
        case .initializationFailed: 3
        }
    }

    public static var errorDomain: String {
        "dev.mpy.umbracore.service.lifecycle"
    }

    override public var localizedDescription: String {
        switch errorType {
        case let .notInitialized(service):
            "Service '\(service)' not initialised"
        case let .alreadyInitialized(service):
            "Service '\(service)' already initialised"
        case let .initializationFailed(service, reason):
            "Service '\(service)' initialisation failed: \(reason)"
        }
    }

    override public var recoverySuggestion: String? {
        switch errorType {
        case .notInitialized:
            "Initialize the service before attempting to use it"
        case .alreadyInitialized:
            "Ensure service is properly shut down before reinitializing"
        case .initializationFailed:
            "Check the failure reason and ensure all prerequisites are met"
        }
    }

    // MARK: - Initialization

    public convenience init(uninitializedService service: String) {
        self.init(type: .notInitialized(service: service))
    }

    public convenience init(initializedService service: String) {
        self.init(type: .alreadyInitialized(service: service))
    }

    public convenience init(service: String, reason: String) {
        self.init(type: .initializationFailed(service: service, reason: reason))
    }

    private init(type: ErrorType) {
        errorType = type
        super.init()
    }
}
