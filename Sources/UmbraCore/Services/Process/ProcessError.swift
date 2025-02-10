//
// ProcessError.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Errors that can occur during process operations
public enum ProcessError: LocalizedError {
    /// Process is already being monitored
    case alreadyMonitoring(Int32)
    /// Process is not being monitored
    case notMonitoring(Int32)
    /// Failed to get process info
    case infoPidFailed(Int32)
    /// Failed to get process name
    case namePidFailed(Int32)
    /// Process terminated
    case terminated(Int32)
    /// Operation timeout
    case timeout(Int32)
    /// Invalid state
    case invalidState(String)
    /// Operation failed
    case operationFailed(String)

    /// Localized description of the error
    public var errorDescription: String? {
        switch self {
        case .alreadyMonitoring(let pid):
            return "Process is already being monitored: \(pid)"
        case .notMonitoring(let pid):
            return "Process is not being monitored: \(pid)"
        case .infoPidFailed(let pid):
            return "Failed to get process info: \(pid)"
        case .namePidFailed(let pid):
            return "Failed to get process name: \(pid)"
        case .terminated(let pid):
            return "Process terminated: \(pid)"
        case .timeout(let pid):
            return "Operation timed out for process: \(pid)"
        case .invalidState(let reason):
            return "Invalid process state: \(reason)"
        case .operationFailed(let reason):
            return "Process operation failed: \(reason)"
        }
    }

    /// Failure reason for the error
    public var failureReason: String? {
        switch self {
        case .alreadyMonitoring:
            return "The process is already being monitored by the system"
        case .notMonitoring:
            return "The process is not currently being monitored"
        case .infoPidFailed:
            return "Failed to retrieve process information from the system"
        case .namePidFailed:
            return "Failed to retrieve process name from the system"
        case .terminated:
            return "The process has terminated and is no longer running"
        case .timeout:
            return "The operation exceeded the maximum allowed time"
        case .invalidState:
            return "The process is in an invalid state for this operation"
        case .operationFailed:
            return "The process operation failed to complete successfully"
        }
    }

    /// Recovery suggestion for the error
    public var recoverySuggestion: String? {
        switch self {
        case .alreadyMonitoring:
            return "Stop monitoring the process before attempting to monitor it again"
        case .notMonitoring:
            return "Start monitoring the process before performing operations"
        case .infoPidFailed:
            return "Verify the process exists and you have permission to access it"
        case .namePidFailed:
            return "Verify the process exists and you have permission to access it"
        case .terminated:
            return "Restart the process if needed"
        case .timeout:
            return "Try the operation again or increase the timeout duration"
        case .invalidState:
            return "Wait for the process to be in a valid state"
        case .operationFailed:
            return "Check the process status and try the operation again"
        }
    }

    /// Help anchor for documentation
    public var helpAnchor: String {
        switch self {
        case .alreadyMonitoring:
            return "process-already-monitoring"
        case .notMonitoring:
            return "process-not-monitoring"
        case .infoPidFailed:
            return "process-info-failed"
        case .namePidFailed:
            return "process-name-failed"
        case .terminated:
            return "process-terminated"
        case .timeout:
            return "process-timeout"
        case .invalidState:
            return "process-invalid-state"
        case .operationFailed:
            return "process-operation-failed"
        }
    }
}
