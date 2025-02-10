import Foundation

/// Errors that can occur during notification operations
public enum NotificationError: LocalizedError {
    /// Authorization denied
    case authorizationDenied
    /// Invalid category
    case invalidCategory(String)
    /// Invalid action
    case invalidAction(String)
    /// Invalid schedule
    case invalidSchedule(String)
    /// Schedule failed
    case scheduleFailed(String)
    /// Delegate error
    case delegateError(String)
    /// Invalid configuration
    case invalidConfiguration(String)
    /// Operation failed
    case operationFailed(String)

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            "Notification authorization denied"
        case let .invalidCategory(reason):
            "Invalid notification category: \(reason)"
        case let .invalidAction(reason):
            "Invalid notification action: \(reason)"
        case let .invalidSchedule(reason):
            "Invalid notification schedule: \(reason)"
        case let .scheduleFailed(reason):
            "Failed to schedule notification: \(reason)"
        case let .delegateError(reason):
            "Notification delegate error: \(reason)"
        case let .invalidConfiguration(reason):
            "Invalid notification configuration: \(reason)"
        case let .operationFailed(reason):
            "Notification operation failed: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .authorizationDenied:
            "Enable notifications in System Settings"
        case .invalidCategory:
            "Check category identifier and actions"
        case .invalidAction:
            "Check action identifier and options"
        case .invalidSchedule:
            "Check schedule pattern and timing"
        case .scheduleFailed:
            "Try rescheduling the notification"
        case .delegateError:
            "Check delegate configuration"
        case .invalidConfiguration:
            "Check notification configuration"
        case .operationFailed:
            "Try the operation again"
        }
    }

    public var helpAnchor: String? {
        switch self {
        case .authorizationDenied:
            "notification_authorization"
        case .invalidCategory:
            "notification_categories"
        case .invalidAction:
            "notification_actions"
        case .invalidSchedule:
            "notification_scheduling"
        case .scheduleFailed:
            "notification_scheduling_troubleshooting"
        case .delegateError:
            "notification_delegates"
        case .invalidConfiguration:
            "notification_configuration"
        case .operationFailed:
            "notification_troubleshooting"
        }
    }
}
