import Foundation

/// Errors that can occur during service lifecycle and operations
@objc
public enum ServiceError: Int, LocalizedError {
    // MARK: - Lifecycle Cases

    /// Service not initialised
    case notInitialized(String)

    /// Service already initialised
    case alreadyInitialized(String)

    /// Service initialisation failed
    case initializationFailed(service: String, reason: String)

    // MARK: - State Cases

    /// Invalid service state
    case invalidState(
        service: String,
        current: ServiceState,
        expected: ServiceState
    )

    /// State transition failed
    case stateTransitionFailed(
        service: String,
        from: ServiceState,
        target: ServiceState
    )

    /// State lock timeout
    case stateLockTimeout(service: String, state: ServiceState)

    // MARK: - Dependency Cases

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

    // MARK: - Operation Cases

    /// Operation failed
    case operationFailed(
        service: String,
        operation: String,
        reason: String
    )

    /// Operation timeout
    case operationTimeout(
        service: String,
        operation: String,
        duration: TimeInterval
    )

    /// Operation cancelled
    case operationCancelled(service: String, operation: String)

    // MARK: - Resource Cases

    /// Resource unavailable
    case resourceUnavailable(service: String, resource: String)

    /// Resource exhausted
    case resourceExhausted(service: String, resource: String)

    /// Resource limit exceeded
    case resourceLimitExceeded(
        service: String,
        resource: String,
        usage: ResourceUsage
    )

    // MARK: - Retry Cases

    /// Retry failed
    case retryFailed(
        service: String,
        operation: String,
        attempts: Int,
        error: Error
    )

    /// Retry limit exceeded
    case retryLimitExceeded(
        service: String,
        operation: String,
        limit: Int
    )

    // MARK: - Security Cases

    /// Authentication failed
    case authenticationFailed(service: String, reason: String)

    /// Authorization failed
    case authorizationFailed(service: String, resource: String)

    /// Security violation
    case securityViolation(service: String, violation: String)
}
