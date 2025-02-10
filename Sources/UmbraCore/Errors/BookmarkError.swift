//
// BookmarkError.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Errors that can occur during security-scoped bookmark operations
public enum BookmarkError: LocalizedError {
    /// Bookmark not found
    case notFound(String)
    /// Access denied to resource
    case accessDenied(String)
    /// Bookmark is stale
    case staleBookmark(String)
    /// Active access prevents operation
    case activeAccess(String)
    /// Invalid bookmark data
    case invalidData(String)
    /// Storage error
    case storageError(String)
    /// Permission error
    case permissionError(String)
    /// Resource not available
    case resourceUnavailable(String)

    /// Localized description of the error
    public var errorDescription: String? {
        switch self {
        case .notFound(let id):
            return "Bookmark not found: \(id)"
        case .accessDenied(let path):
            return "Access denied to resource: \(path)"
        case .staleBookmark(let id):
            return "Bookmark is stale and needs to be recreated: \(id)"
        case .activeAccess(let id):
            return "Cannot perform operation while bookmark is being accessed: \(id)"
        case .invalidData(let reason):
            return "Invalid bookmark data: \(reason)"
        case .storageError(let reason):
            return "Failed to store bookmark: \(reason)"
        case .permissionError(let reason):
            return "Permission error: \(reason)"
        case .resourceUnavailable(let path):
            return "Resource not available: \(path)"
        }
    }

    /// Failure reason for the error
    public var failureReason: String? {
        switch self {
        case .notFound:
            return "The specified bookmark could not be found in storage"
        case .accessDenied:
            return "The system denied access to the security-scoped resource"
        case .staleBookmark:
            return "The bookmark data is no longer valid and needs to be recreated"
        case .activeAccess:
            return "The bookmark is currently being accessed and cannot be modified"
        case .invalidData:
            return "The bookmark data is corrupted or invalid"
        case .storageError:
            return "Failed to store or retrieve bookmark data"
        case .permissionError:
            return "Insufficient permissions to access the resource"
        case .resourceUnavailable:
            return "The resource is not available or does not exist"
        }
    }

    /// Recovery suggestion for the error
    public var recoverySuggestion: String? {
        switch self {
        case .notFound:
            return "Create a new bookmark for the resource"
        case .accessDenied:
            return "Request user permission to access the resource"
        case .staleBookmark:
            return "Create a new bookmark and update any stored references"
        case .activeAccess:
            return "Stop accessing the bookmark before performing this operation"
        case .invalidData:
            return "Create a new bookmark with valid data"
        case .storageError:
            return "Check storage permissions and available space"
        case .permissionError:
            return "Request necessary permissions from the user"
        case .resourceUnavailable:
            return "Verify the resource exists and is accessible"
        }
    }

    /// Help anchor for documentation
    public var helpAnchor: String {
        switch self {
        case .notFound:
            return "bookmark-not-found"
        case .accessDenied:
            return "bookmark-access-denied"
        case .staleBookmark:
            return "bookmark-stale"
        case .activeAccess:
            return "bookmark-active-access"
        case .invalidData:
            return "bookmark-invalid-data"
        case .storageError:
            return "bookmark-storage-error"
        case .permissionError:
            return "bookmark-permission-error"
        case .resourceUnavailable:
            return "bookmark-resource-unavailable"
        }
    }
}
