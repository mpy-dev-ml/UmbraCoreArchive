import Foundation

/// Errors that can occur during system operations
public enum SystemError: LocalizedError {
    /// Monitor failed to start
    case monitorStartFailed(String)
    /// Monitor failed to stop
    case monitorStopFailed(String)
    /// Invalid monitor state
    case invalidMonitorState(String)
    /// Resource access denied
    case resourceAccessDenied(String)
    /// Unsupported resource
    case unsupportedResource(String)
    /// Resource unavailable
    case resourceUnavailable(String)
    /// Invalid configuration
    case invalidConfiguration(String)
    /// Operation failed
    case operationFailed(String)
    /// Unimplemented feature
    case unimplemented(String)

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case let .monitorStartFailed(reason):
            "Monitor failed to start: \(reason)"
        case let .monitorStopFailed(reason):
            "Monitor failed to stop: \(reason)"
        case let .invalidMonitorState(state):
            "Invalid monitor state: \(state)"
        case let .resourceAccessDenied(resource):
            "Resource access denied: \(resource)"
        case let .unsupportedResource(resource):
            "Unsupported resource: \(resource)"
        case let .resourceUnavailable(resource):
            "Resource unavailable: \(resource)"
        case let .invalidConfiguration(reason):
            "Invalid configuration: \(reason)"
        case let .operationFailed(reason):
            "Operation failed: \(reason)"
        case let .unimplemented(feature):
            "Feature not implemented: \(feature)"
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
        case .resourceAccessDenied:
            "Request necessary permissions"
        case .unsupportedResource:
            "Use a supported resource type"
        case .resourceUnavailable:
            "Check resource availability"
        case .invalidConfiguration:
            "Check configuration settings"
        case .operationFailed:
            "Try the operation again"
        case .unimplemented:
            "Use an implemented feature"
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
        case .resourceAccessDenied:
            "resource_access"
        case .unsupportedResource:
            "resource_types"
        case .resourceUnavailable:
            "resource_availability"
        case .invalidConfiguration:
            "configuration"
        case .operationFailed:
            "operation_troubleshooting"
        case .unimplemented:
            "implementation_status"
        }
    }
}
