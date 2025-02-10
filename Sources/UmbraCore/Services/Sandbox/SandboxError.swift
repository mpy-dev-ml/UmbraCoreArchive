//
// SandboxError.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

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

    public var errorDescription: String? {
        switch self {
        case .monitorStartFailed(let reason):
            return "Monitor failed to start: \(reason)"
        case .monitorStopFailed(let reason):
            return "Monitor failed to stop: \(reason)"
        case .invalidMonitorState(let state):
            return "Invalid monitor state: \(state)"
        case .eventHandlingFailed(let reason):
            return "Event handling failed: \(reason)"
        case .resourceAccessDenied(let resource):
            return "Resource access denied: \(resource)"
        case .invalidConfiguration(let reason):
            return "Invalid configuration: \(reason)"
        case .operationFailed(let reason):
            return "Operation failed: \(reason)"
        case .securityViolation(let reason):
            return "Security violation: \(reason)"
        case .resourceUnavailable(let resource):
            return "Resource unavailable: \(resource)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .monitorStartFailed:
            return "Check monitor configuration and try again"
        case .monitorStopFailed:
            return "Force stop monitor and clean up resources"
        case .invalidMonitorState:
            return "Reset monitor to a valid state"
        case .eventHandlingFailed:
            return "Check event handler configuration"
        case .resourceAccessDenied:
            return "Request necessary permissions"
        case .invalidConfiguration:
            return "Check configuration settings"
        case .operationFailed:
            return "Try the operation again"
        case .securityViolation:
            return "Review security policies"
        case .resourceUnavailable:
            return "Check resource availability"
        }
    }

    public var helpAnchor: String? {
        switch self {
        case .monitorStartFailed:
            return "monitor_start"
        case .monitorStopFailed:
            return "monitor_stop"
        case .invalidMonitorState:
            return "monitor_state"
        case .eventHandlingFailed:
            return "event_handling"
        case .resourceAccessDenied:
            return "resource_access"
        case .invalidConfiguration:
            return "configuration"
        case .operationFailed:
            return "operation_troubleshooting"
        case .securityViolation:
            return "security_policies"
        case .resourceUnavailable:
            return "resource_availability"
        }
    }
}
