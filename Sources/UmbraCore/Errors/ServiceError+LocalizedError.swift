import Foundation

// MARK: - ServiceError + LocalizedError

public extension ServiceError {
    /// Formats an error message with service and details
    private func formatError(
        _ message: String,
        service: String,
        details: String
    ) -> String {
        "\(message) - Service: \(service), \(details)"
    }

    var errorDescription: String? {
        switch self {
        case let .notInitialized(service):
            "Service not initialised: \(service)"

        case let .alreadyInitialized(service):
            "Service already initialised: \(service)"

        case let .initializationFailed(service, reason):
            formatError(
                "Failed to initialise service",
                service: service,
                details: reason
            )

        case let .invalidState(service, current, expected):
            formatError(
                "Invalid service state",
                service: service,
                details: "Current: \(current), Expected: \(expected)"
            )

        case let .stateTransitionFailed(service, from, target):
            formatError(
                "State transition failed",
                service: service,
                details: "From: \(from), To: \(target)"
            )

        case let .stateLockTimeout(service, state):
            formatError(
                "State lock timeout",
                service: service,
                details: "State: \(state)"
            )

        case let .dependencyUnavailable(service, dependency):
            formatError(
                "Dependency unavailable",
                service: service,
                details: "Dependency: \(dependency)"
            )

        case let .dependencyMisconfigured(service, dependency, reason):
            formatError(
                "Dependency misconfigured",
                service: service,
                details: "\(dependency): \(reason)"
            )

        case let .dependencyTimeout(service, dependency):
            formatError(
                "Dependency timeout",
                service: service,
                details: "Dependency: \(dependency)"
            )

        case let .operationFailed(service, operation, reason):
            formatError(
                "Operation failed",
                service: service,
                details: "\(operation): \(reason)"
            )

        case let .operationTimeout(service, operation, duration):
            formatError(
                "Operation timeout",
                service: service,
                details: "\(operation) after \(duration)s"
            )

        case let .operationCancelled(service, operation):
            formatError(
                "Operation cancelled",
                service: service,
                details: "Operation: \(operation)"
            )

        case let .resourceUnavailable(service, resource):
            formatError(
                "Resource unavailable",
                service: service,
                details: "Resource: \(resource)"
            )

        case let .resourceExhausted(service, resource):
            formatError(
                "Resource exhausted",
                service: service,
                details: "Resource: \(resource)"
            )

        case let .resourceLimitExceeded(service, resource, usage):
            formatError(
                "Resource limit exceeded",
                service: service,
                details: "\(resource): \(usage)"
            )

        case let .retryFailed(service, operation, attempts, error):
            formatError(
                "Retry failed",
                service: service,
                details: """
                Operation: \(operation), \
                Attempts: \(attempts), \
                Error: \(error)
                """
            )

        case let .retryLimitExceeded(service, operation, limit):
            formatError(
                "Retry limit exceeded",
                service: service,
                details: """
                Operation: \(operation), \
                Limit: \(limit)
                """
            )

        case let .authenticationFailed(service, reason):
            formatError(
                "Authentication failed",
                service: service,
                details: reason
            )

        case let .authorizationFailed(service, resource):
            formatError(
                "Authorisation failed",
                service: service,
                details: "Resource: \(resource)"
            )

        case let .securityViolation(service, violation):
            formatError(
                "Security violation",
                service: service,
                details: violation
            )
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notInitialized:
            "Initialise the service before using it"

        case .alreadyInitialized:
            "Ensure service is not already initialised"

        case .initializationFailed:
            "Check the service configuration and try again"

        case .invalidState:
            "Reset service to a valid state"

        case .stateTransitionFailed:
            """
            Check if the state transition is valid \
            and retry
            """

        case .stateLockTimeout:
            """
            Consider increasing the timeout duration \
            or check for deadlocks
            """

        case .dependencyUnavailable:
            """
            Ensure all required dependencies are \
            available and running
            """

        case .dependencyMisconfigured:
            """
            Check the dependency configuration \
            and correct any issues
            """

        case .dependencyTimeout:
            """
            Check dependency health and consider \
            increasing timeout
            """

        case .operationFailed:
            "Check operation parameters and try again"

        case .operationTimeout:
            """
            Consider increasing the operation timeout \
            or optimising the operation
            """

        case .operationCancelled:
            "Operation can be retried if needed"

        case .resourceUnavailable:
            """
            Check resource availability and \
            system status
            """

        case .resourceExhausted:
            """
            Wait for resources to become available \
            or free up resources
            """

        case .resourceLimitExceeded:
            """
            Increase resource limits or reduce \
            resource usage
            """

        case .retryFailed:
            """
            Check the underlying error and \
            resolve before retrying
            """

        case .retryLimitExceeded:
            """
            Consider increasing retry limit or \
            implementing fallback
            """

        case .authenticationFailed:
            "Check credentials and try again"

        case .authorizationFailed:
            "Verify permissions and access rights"

        case .securityViolation:
            """
            Review security logs and ensure \
            compliance with security policy
            """
        }
    }
}
