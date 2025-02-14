import Foundation

/// Errors that can occur during service lifecycle management
@objc
public enum ServiceLifecycleError: Int, ServiceErrorProtocol {
    /// Service failed to start
    case startFailed
    /// Service failed to stop
    case stopFailed
    /// Service failed to restart
    case restartFailed
    /// Service in invalid state
    case invalidState
    /// Service operation timeout
    case operationTimeout
    
    /// Service name associated with the error
    public var serviceName: String {
        "LifecycleService"
    }
    
    /// Localized description of the error
    public var localizedDescription: String {
        switch self {
        case .startFailed:
            return "Failed to start service"
        case .stopFailed:
            return "Failed to stop service"
        case .restartFailed:
            return "Failed to restart service"
        case .invalidState:
            return "Service is in an invalid state"
        case .operationTimeout:
            return "Service operation timed out"
        }
    }
    
    /// Reason for the failure
    public var failureReason: String? {
        switch self {
        case .startFailed:
            return "The service could not be started due to initialization failure"
        case .stopFailed:
            return "The service could not be stopped gracefully"
        case .restartFailed:
            return "The service could not be restarted properly"
        case .invalidState:
            return "The service is in an unexpected or invalid state"
        case .operationTimeout:
            return "The operation exceeded the maximum allowed time"
        }
    }
    
    /// Suggestion for recovering from the error
    public var recoverySuggestion: String? {
        switch self {
        case .startFailed:
            return "Check service configuration and dependencies"
        case .stopFailed:
            return "Force stop the service or wait for pending operations"
        case .restartFailed:
            return "Try stopping the service completely before starting again"
        case .invalidState:
            return "Reset the service to its initial state"
        case .operationTimeout:
            return "Increase the operation timeout or check for deadlocks"
        }
    }
}
