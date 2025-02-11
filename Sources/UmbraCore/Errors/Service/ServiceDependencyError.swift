import Foundation

/// Errors that can occur during service dependency management
@frozen
@objc
public final class ServiceDependencyError: NSObject, ServiceErrorProtocol {
    // MARK: - Error Types

    private enum ErrorType {
        case dependencyUnavailable(service: String, dependency: String)
        case dependencyMisconfigured(service: String, dependency: String, reason: String)
        case dependencyTimeout(service: String, dependency: String)
    }

    // MARK: - Properties

    private let errorType: ErrorType

    /// Service name associated with the error
    public var serviceName: String {
        switch errorType {
        case let .dependencyUnavailable(service, _),
             let .dependencyMisconfigured(service, _, _),
             let .dependencyTimeout(service, _):
            service
        }
    }

    /// Name of the dependency involved in the error
    public var dependencyName: String {
        switch errorType {
        case let .dependencyUnavailable(_, dependency),
             let .dependencyMisconfigured(_, dependency, _),
             let .dependencyTimeout(_, dependency):
            dependency
        }
    }

    /// Reason for misconfiguration if applicable
    public var misconfigurationReason: String? {
        switch errorType {
        case let .dependencyMisconfigured(_, _, reason):
            reason
        default:
            nil
        }
    }

    // MARK: - ServiceErrorProtocol

    public var errorCode: Int {
        switch errorType {
        case .dependencyUnavailable: 1
        case .dependencyMisconfigured: 2
        case .dependencyTimeout: 3
        }
    }

    public static var errorDomain: String {
        "dev.mpy.umbracore.service.dependency"
    }

    override public var localizedDescription: String {
        switch errorType {
        case let .dependencyUnavailable(service, dependency):
            "Required dependency '\(dependency)' unavailable for service '\(service)'"
        case let .dependencyMisconfigured(service, dependency, reason):
            "Dependency '\(dependency)' misconfigured for service '\(service)': \(reason)"
        case let .dependencyTimeout(service, dependency):
            "Dependency '\(dependency)' timed out for service '\(service)'"
        }
    }

    // MARK: - Initialization

    public convenience init(service: String, dependency: String, reason: String? = nil) {
        if let reason {
            self.init(type: .dependencyMisconfigured(service: service, dependency: dependency, reason: reason))
        } else {
            self.init(type: .dependencyUnavailable(service: service, dependency: dependency))
        }
    }

    public convenience init(timeoutService service: String, dependency: String) {
        self.init(type: .dependencyTimeout(service: service, dependency: dependency))
    }

    private init(type: ErrorType) {
        errorType = type
        super.init()
    }
}
