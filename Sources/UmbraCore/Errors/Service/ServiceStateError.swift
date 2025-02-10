import Foundation

/// Errors that can occur during service state management
@objc public enum ServiceStateError: Int, ServiceErrorProtocol {
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
        to: ServiceState
    )

    /// State lock timeout
    case stateLockTimeout(service: String, state: ServiceState)

    // MARK: Public

    // MARK: - ServiceErrorProtocol

    public var serviceName: String {
        switch self {
        case let .invalidState(service, _, _),
             let .stateTransitionFailed(service, _, _),
             let .stateLockTimeout(service, _):
            service
        }
    }

    public var errorDescription: String? {
        switch self {
        case let .invalidState(service, current, expected):
            "Invalid state for service \(service): expected \(expected), but was \(current)"
        case let .stateTransitionFailed(service, from, to):
            "Failed to transition service \(service) from \(from) to \(to)"
        case let .stateLockTimeout(service, state):
            "Timeout waiting for service \(service) state lock in state \(state)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidState:
            "Ensure service is in the correct state before performing operation"
        case .stateTransitionFailed:
            "Check service dependencies and configuration"
        case .stateLockTimeout:
            "Try operation again or check for deadlocks"
        }
    }
}
