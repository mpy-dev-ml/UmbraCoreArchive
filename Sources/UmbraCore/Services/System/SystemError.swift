//
// SystemError.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

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

    public var errorDescription: String? {
        switch self {
        case .monitorStartFailed(let reason):
            return "Monitor failed to start: \(reason)"
        case .monitorStopFailed(let reason):
            return "Monitor failed to stop: \(reason)"
        case .invalidMonitorState(let state):
            return "Invalid monitor state: \(state)"
        case .resourceAccessDenied(let resource):
            return "Resource access denied: \(resource)"
        case .unsupportedResource(let resource):
            return "Unsupported resource: \(resource)"
        case .resourceUnavailable(let resource):
            return "Resource unavailable: \(resource)"
        case .invalidConfiguration(let reason):
            return "Invalid configuration: \(reason)"
        case .operationFailed(let reason):
            return "Operation failed: \(reason)"
        case .unimplemented(let feature):
            return "Feature not implemented: \(feature)"
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
        case .resourceAccessDenied:
            return "Request necessary permissions"
        case .unsupportedResource:
            return "Use a supported resource type"
        case .resourceUnavailable:
            return "Check resource availability"
        case .invalidConfiguration:
            return "Check configuration settings"
        case .operationFailed:
            return "Try the operation again"
        case .unimplemented:
            return "Use an implemented feature"
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
        case .resourceAccessDenied:
            return "resource_access"
        case .unsupportedResource:
            return "resource_types"
        case .resourceUnavailable:
            return "resource_availability"
        case .invalidConfiguration:
            return "configuration"
        case .operationFailed:
            return "operation_troubleshooting"
        case .unimplemented:
            return "implementation_status"
        }
    }
}
