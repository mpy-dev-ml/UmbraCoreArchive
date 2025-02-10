import Foundation

/// Errors that can occur during sandbox operations
public enum SandboxError: LocalizedError {
    /// Monitor failed to start
    case monitorStartFailed(String)
    /// Monitor failed to stop
    case monitorStopFailed(String)
    /// Invalid monitor state
    case invalidMonitorState(String)
    /// Event handling failed
    case eventHandlingFailed(String)
    /// Resource access denied
    case resourceAccessDenied(String)
    /// Invalid configuration
    case invalidConfiguration(String)
    /// Operation failed
    case operationFailed(String)
    /// Security violation
    case securityViolation(String)
    /// Resource unavailable
    case resourceUnavailable(String)

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case let .monitorStartFailed(reason):
            "Monitor failed to start: \(reason)"
        case let .monitorStopFailed(reason):
            "Monitor failed to stop: \(reason)"
        case let .invalidMonitorState(state):
            "Invalid monitor state: \(state)"
        case let .eventHandlingFailed(reason):
            "Event handling failed: \(reason)"
        case let .resourceAccessDenied(resource):
            "Resource access denied: \(resource)"
        case let .invalidConfiguration(reason):
            "Invalid configuration: \(reason)"
        case let .operationFailed(reason):
            "Operation failed: \(reason)"
        case let .securityViolation(reason):
            "Security violation: \(reason)"
        case let .resourceUnavailable(resource):
            "Resource unavailable: \(resource)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .monitorStartFailed:
            "Check monitor configuration and try again"
        case .monitorStopFailed:
            "Force stop monitor and clean up resources"
        case .invalidMonitorState:
            "Reset monitor to a valid state"
        case .eventHandlingFailed:
            "Check event handler configuration"
        case .resourceAccessDenied:
            "Request necessary permissions"
        case .invalidConfiguration:
            "Check configuration settings"
        case .operationFailed:
            "Try the operation again"
        case .securityViolation:
            "Review security policies"
        case .resourceUnavailable:
            "Check resource availability"
        }
    }

    public var helpAnchor: String? {
        switch self {
        case .monitorStartFailed:
            "monitor_start"
        case .monitorStopFailed:
            "monitor_stop"
        case .invalidMonitorState:
            "monitor_state"
        case .eventHandlingFailed:
            "event_handling"
        case .resourceAccessDenied:
            "resource_access"
        case .invalidConfiguration:
            "configuration"
        case .operationFailed:
            "operation_troubleshooting"
        case .securityViolation:
            "security_policies"
        case .resourceUnavailable:
            "resource_availability"
        }
    }
}
