//
// SecurityError.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Security-related errors
public enum SecurityError: LocalizedError {
    /// Bookmark creation failed
    case bookmarkCreationFailed(String)
    /// Bookmark resolution failed
    case bookmarkResolutionFailed(String)
    /// Bookmark is stale
    case bookmarkStale
    /// Permission denied
    case permissionDenied(String)
    /// Access validation failed
    case accessValidationFailed(String)
    /// Operation not permitted
    case operationNotPermitted(String)
    /// Keychain error
    case keychainError(String)
    /// Encryption error
    case encryptionError(String)
    /// Decryption error
    case decryptionError(String)
    /// Key management error
    case keyManagementError(String)

    public var errorDescription: String? {
        switch self {
        case .bookmarkCreationFailed(let reason):
            return "Failed to create bookmark: \(reason)"
        case .bookmarkResolutionFailed(let reason):
            return "Failed to resolve bookmark: \(reason)"
        case .bookmarkStale:
            return "Bookmark is stale and needs to be recreated"
        case .permissionDenied(let reason):
            return "Permission denied: \(reason)"
        case .accessValidationFailed(let reason):
            return "Access validation failed: \(reason)"
        case .operationNotPermitted(let reason):
            return "Operation not permitted: \(reason)"
        case .keychainError(let reason):
            return "Keychain error: \(reason)"
        case .encryptionError(let reason):
            return "Encryption error: \(reason)"
        case .decryptionError(let reason):
            return "Decryption error: \(reason)"
        case .keyManagementError(let reason):
            return "Key management error: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .bookmarkStale:
            return "Request permission again to create a new bookmark"
        case .permissionDenied:
            return "Try requesting permission again or select a different file"
        case .keychainError:
            return "Check keychain access and permissions"
        case .encryptionError, .decryptionError:
            return "Verify encryption key and try again"
        case .keyManagementError:
            return "Check key validity and permissions"
        default:
            return nil
        }
    }
}
