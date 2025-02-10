//
// PermissionError.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Errors that can occur during permission operations
public enum PermissionError: LocalizedError {
    /// Permission denied
    case permissionDenied(String)
    /// Permission expired
    case permissionExpired(String)
    /// Permission not found
    case permissionNotFound(String)
    /// Invalid permission
    case invalidPermission(String)
    /// Unsupported permission
    case unsupportedPermission(String)
    /// Permission request failed
    case requestFailed(String)
    /// Permission validation failed
    case validationFailed(String)
    /// Unimplemented permission
    case unimplemented(String)
    /// Operation failed
    case operationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .permissionDenied(let permission):
            return "Permission denied: \(permission)"
        case .permissionExpired(let permission):
            return "Permission expired: \(permission)"
        case .permissionNotFound(let permission):
            return "Permission not found: \(permission)"
        case .invalidPermission(let reason):
            return "Invalid permission: \(reason)"
        case .unsupportedPermission(let permission):
            return "Unsupported permission: \(permission)"
        case .requestFailed(let reason):
            return "Permission request failed: \(reason)"
        case .validationFailed(let reason):
            return "Permission validation failed: \(reason)"
        case .unimplemented(let permission):
            return "Permission not implemented: \(permission)"
        case .operationFailed(let reason):
            return "Permission operation failed: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Request permission from user"
        case .permissionExpired:
            return "Request permission again"
        case .permissionNotFound:
            return "Request permission first"
        case .invalidPermission:
            return "Check permission configuration"
        case .unsupportedPermission:
            return "Use a supported permission type"
        case .requestFailed:
            return "Try requesting permission again"
        case .validationFailed:
            return "Check permission validity"
        case .unimplemented:
            return "Use an implemented permission type"
        case .operationFailed:
            return "Try the operation again"
        }
    }

    public var helpAnchor: String? {
        switch self {
        case .permissionDenied:
            return "permission_request"
        case .permissionExpired:
            return "permission_expiry"
        case .permissionNotFound:
            return "permission_lookup"
        case .invalidPermission:
            return "permission_configuration"
        case .unsupportedPermission:
            return "permission_types"
        case .requestFailed:
            return "permission_request_process"
        case .validationFailed:
            return "permission_validation"
        case .unimplemented:
            return "permission_implementation"
        case .operationFailed:
            return "permission_troubleshooting"
        }
    }
}
