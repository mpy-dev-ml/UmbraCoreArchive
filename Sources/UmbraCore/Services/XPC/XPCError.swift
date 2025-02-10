//
// XPCError.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Errors that can occur during XPC operations
public enum XPCError: LocalizedError {
    /// Not connected to service
    case notConnected
    /// Invalid connection state
    case invalidState(String)
    /// Invalid proxy object
    case invalidProxy(String)
    /// Connection timeout
    case timeout
    /// Invalid message
    case invalidMessage(String)
    /// Security error
    case securityError(String)
    /// Operation failed
    case operationFailed(String)

    /// Localized description of the error
    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to XPC service"
        case .invalidState(let reason):
            return "Invalid connection state: \(reason)"
        case .invalidProxy(let reason):
            return "Invalid proxy object: \(reason)"
        case .timeout:
            return "Connection timeout"
        case .invalidMessage(let reason):
            return "Invalid message: \(reason)"
        case .securityError(let reason):
            return "Security error: \(reason)"
        case .operationFailed(let reason):
            return "Operation failed: \(reason)"
        }
    }

    /// Failure reason for the error
    public var failureReason: String? {
        switch self {
        case .notConnected:
            return "The XPC service connection is not established"
        case .invalidState:
            return "The connection is in an invalid state for this operation"
        case .invalidProxy:
            return "Failed to obtain a valid proxy object"
        case .timeout:
            return "The connection attempt timed out"
        case .invalidMessage:
            return "The message format or content is invalid"
        case .securityError:
            return "A security violation occurred"
        case .operationFailed:
            return "The XPC operation failed to complete"
        }
    }

    /// Recovery suggestion for the error
    public var recoverySuggestion: String? {
        switch self {
        case .notConnected:
            return "Connect to the XPC service before performing operations"
        case .invalidState:
            return "Wait for the connection to be in the correct state"
        case .invalidProxy:
            return "Verify the interface protocol and try reconnecting"
        case .timeout:
            return "Check network conditions and try again"
        case .invalidMessage:
            return "Verify the message format and content"
        case .securityError:
            return "Check security permissions and entitlements"
        case .operationFailed:
            return "Try the operation again or check logs for details"
        }
    }

    /// Help anchor for documentation
    public var helpAnchor: String {
        switch self {
        case .notConnected:
            return "xpc-not-connected"
        case .invalidState:
            return "xpc-invalid-state"
        case .invalidProxy:
            return "xpc-invalid-proxy"
        case .timeout:
            return "xpc-timeout"
        case .invalidMessage:
            return "xpc-invalid-message"
        case .securityError:
            return "xpc-security-error"
        case .operationFailed:
            return "xpc-operation-failed"
        }
    }
}
