@preconcurrency import Foundation

/// Errors that can occur during service dependency management
public final class ServiceDependencyError: NSError {
    // MARK: - Error Types

    /// Types of dependency errors
    public enum ErrorType {
        /// Required dependency is missing
        case missingDependency(service: String, dependency: String)
        /// Dependency is in an invalid state
        case invalidDependencyState(service: String, dependency: String, state: String)
        /// Dependency failed to initialize
        case dependencyInitializationFailed(service: String, dependency: String, reason: String)
        /// Dependency is not compatible
        case incompatibleDependency(service: String, dependency: String, reason: String)
    }

    // MARK: - Properties

    /// The type of error that occurred
    public let errorType: ErrorType

    // MARK: - Initialization

    /// Initialize a service dependency error
    /// - Parameters:
    ///   - type: Type of error that occurred
    ///   - userInfo: Additional error information
    public init(type: ErrorType, userInfo: [String: Any]? = nil) {
        errorType = type
        super.init(domain: String(describing: Self.self), code: 0, userInfo: userInfo)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Error

    override public var localizedDescription: String {
        switch errorType {
        case let .missingDependency(service, dependency):
            "Service '\(service)' is missing required dependency '\(dependency)'"

        case let .invalidDependencyState(service, dependency, state):
            "Service '\(service)' dependency '\(dependency)' is in invalid state: \(state)"

        case let .dependencyInitializationFailed(service, dependency, reason):
            "Service '\(service)' dependency '\(dependency)' failed to initialize: \(reason)"

        case let .incompatibleDependency(service, dependency, reason):
            "Service '\(service)' dependency '\(dependency)' is not compatible: \(reason)"
        }
    }

    override public var localizedRecoverySuggestion: String? {
        switch errorType {
        case .missingDependency:
            "Ensure the required dependency is properly registered with the service provider."

        case .invalidDependencyState:
            "Check the dependency's state and ensure it is properly initialized."

        case .dependencyInitializationFailed:
            "Review the dependency's initialization requirements and error logs."

        case .incompatibleDependency:
            "Verify version compatibility and configuration of the dependency."
        }
    }

    override public var localizedFailureReason: String? {
        switch errorType {
        case .missingDependency:
            "Required dependency not found"

        case let .invalidDependencyState(_, _, state):
            "Invalid state: \(state)"

        case let .dependencyInitializationFailed(_, _, reason):
            "Initialization failed: \(reason)"

        case let .incompatibleDependency(_, _, reason):
            "Incompatible: \(reason)"
        }
    }
}
