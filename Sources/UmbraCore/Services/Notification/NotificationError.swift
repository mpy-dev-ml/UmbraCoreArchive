//
// NotificationError.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

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

    public var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Notification authorization denied"
        case .invalidCategory(let reason):
            return "Invalid notification category: \(reason)"
        case .invalidAction(let reason):
            return "Invalid notification action: \(reason)"
        case .invalidSchedule(let reason):
            return "Invalid notification schedule: \(reason)"
        case .scheduleFailed(let reason):
            return "Failed to schedule notification: \(reason)"
        case .delegateError(let reason):
            return "Notification delegate error: \(reason)"
        case .invalidConfiguration(let reason):
            return "Invalid notification configuration: \(reason)"
        case .operationFailed(let reason):
            return "Notification operation failed: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .authorizationDenied:
            return "Enable notifications in System Settings"
        case .invalidCategory:
            return "Check category identifier and actions"
        case .invalidAction:
            return "Check action identifier and options"
        case .invalidSchedule:
            return "Check schedule pattern and timing"
        case .scheduleFailed:
            return "Try rescheduling the notification"
        case .delegateError:
            return "Check delegate configuration"
        case .invalidConfiguration:
            return "Check notification configuration"
        case .operationFailed:
            return "Try the operation again"
        }
    }

    public var helpAnchor: String? {
        switch self {
        case .authorizationDenied:
            return "notification_authorization"
        case .invalidCategory:
            return "notification_categories"
        case .invalidAction:
            return "notification_actions"
        case .invalidSchedule:
            return "notification_scheduling"
        case .scheduleFailed:
            return "notification_scheduling_troubleshooting"
        case .delegateError:
            return "notification_delegates"
        case .invalidConfiguration:
            return "notification_configuration"
        case .operationFailed:
            return "notification_troubleshooting"
        }
    }
}
