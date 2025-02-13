@preconcurrency import Foundation

/// Errors that can occur during service state management
@frozen
@objc
public final class ServiceStateError: NSObject, ServiceErrorProtocol {
    // MARK: - Error Types

    private enum ErrorType {
        case invalidState(service: String, current: ServiceState, expected: ServiceState)
        case stateTransitionFailed(service: String, from: ServiceState, target: ServiceState)
        case stateLockTimeout(service: String, state: ServiceState)
    }

    // MARK: - Properties

    private let errorType: ErrorType

    /// Service name associated with the error
    public var serviceName: String {
        switch errorType {
        case let .invalidState(service, _, _),
             let .stateTransitionFailed(service, _, _),
             let .stateLockTimeout(service, _):
            service
        }
    }

    /// Current state when error occurred
    public var currentState: ServiceState? {
        switch errorType {
        case let .invalidState(_, current, _):
            current
        case let .stateTransitionFailed(_, from, _):
            from
        case let .stateLockTimeout(_, state):
            state
        }
    }

    /// Expected or target state when error occurred
    public var targetState: ServiceState? {
        switch errorType {
        case let .invalidState(_, _, expected):
            expected
        case let .stateTransitionFailed(_, _, target):
            target
        case .stateLockTimeout:
            nil
        }
    }

    // MARK: - ServiceErrorProtocol

    public var errorCode: Int {
        switch errorType {
        case .invalidState: 1
        case .stateTransitionFailed: 2
        case .stateLockTimeout: 3
        }
    }

    public static var errorDomain: String {
        "dev.mpy.umbracore.service.state"
    }

    override public var localizedDescription: String {
        switch errorType {
        case let .invalidState(service, current, expected):
            "Service '\(service)' in invalid state: expected '\(expected)', but was '\(current)'"
        case let .stateTransitionFailed(service, from, target):
            "Service '\(service)' failed to transition from '\(from)' to '\(target)'"
        case let .stateLockTimeout(service, state):
            "Service '\(service)' state lock timed out in state '\(state)'"
        }
    }

    override public var recoverySuggestion: String? {
        switch errorType {
        case .invalidState:
            "Ensure service is in the correct state before proceeding"
        case .stateTransitionFailed:
            "Check if the state transition is valid and all prerequisites are met"
        case .stateLockTimeout:
            "Check for deadlocks or increase the lock timeout duration"
        }
    }

    // MARK: - Initialization

    public convenience init(service: String, current: ServiceState, expected: ServiceState) {
        self.init(type: .invalidState(service: service, current: current, expected: expected))
    }

    public convenience init(service: String, from: ServiceState, target: ServiceState) {
        self.init(type: .stateTransitionFailed(service: service, from: from, target: target))
    }

    public convenience init(service: String, state: ServiceState) {
        self.init(type: .stateLockTimeout(service: service, state: state))
    }

    private init(type: ErrorType) {
        errorType = type
        super.init()
    }
}
