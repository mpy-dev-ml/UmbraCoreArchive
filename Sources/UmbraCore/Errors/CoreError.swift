//
// CoreError.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Base error type for UmbraCore errors
public enum CoreError: LocalizedError {
    /// Indicates an operation that requires authentication failed
    case authenticationFailed
    /// Indicates an operation failed due to insufficient permissions
    case insufficientPermissions
    /// Indicates an operation failed due to invalid configuration
    case invalidConfiguration(String)
    /// Indicates an operation failed due to a system error
    case systemError(String)

    public var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Authentication failed"
        case .insufficientPermissions:
            return "Insufficient permissions to perform the operation"
        case .invalidConfiguration(let details):
            return "Invalid configuration: \(details)"
        case .systemError(let details):
            return "System error: \(details)"
        }
    }
}
