import Foundation

/// Errors that can occur during service dependency management
@objc public enum ServiceDependencyError: Int, ServiceErrorProtocol {
    /// Required dependency unavailable
    case dependencyUnavailable(service: String, dependency: String)

    /// Dependency misconfigured
    case dependencyMisconfigured(
        service: String,
        dependency: String,
        reason: String
    )

    /// Dependency timeout
    case dependencyTimeout(service: String, dependency: String)

    // MARK: Public

    // MARK: - ServiceErrorProtocol

    public var serviceName: String {
        switch self {
        case let .dependencyUnavailable(service, _),
             let .dependencyMisconfigured(service, _, _),
             let .dependencyTimeout(service, _):
            service
        }
    }

    public var errorDescription: String? {
        switch self {
        case let .dependencyUnavailable(service, dependency):
            "Required dependency \(dependency) unavailable for service \(service)"
        case let .dependencyMisconfigured(service, dependency, reason):
            "Dependency \(dependency) misconfigured for service \(service): \(reason)"
        case let .dependencyTimeout(service, dependency):
            "Timeout waiting for dependency \(dependency) in service \(service)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .dependencyUnavailable:
            "Ensure all required dependencies are available"
        case .dependencyMisconfigured:
            "Check dependency configuration"
        case .dependencyTimeout:
            "Check dependency status and try again"
        }
    }

    public var failureReason: String? {
        switch self {
        case let .dependencyMisconfigured(_, _, reason):
            reason
        default:
            nil
        }
    }
}
