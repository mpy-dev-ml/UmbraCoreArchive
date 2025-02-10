//
// ResourceError.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Errors that can occur during resource operations
public enum ResourceError: LocalizedError {
    /// Resource not found
    case resourceNotFound(String)
    /// Invalid resource type
    case invalidResourceType(String)
    /// Invalid resource data
    case invalidResourceData(String)
    /// Store failed
    case storeFailed(String)
    /// Load failed
    case loadFailed(String)
    /// Remove failed
    case removeFailed(String)
    /// Invalid identifier
    case invalidIdentifier(String)
    /// Invalid metadata
    case invalidMetadata(String)
    /// Cache error
    case cacheError(String)

    public var errorDescription: String? {
        switch self {
        case .resourceNotFound(let identifier):
            return "Resource not found: \(identifier)"
        case .invalidResourceType(let type):
            return "Invalid resource type: \(type)"
        case .invalidResourceData(let reason):
            return "Invalid resource data: \(reason)"
        case .storeFailed(let reason):
            return "Failed to store resource: \(reason)"
        case .loadFailed(let reason):
            return "Failed to load resource: \(reason)"
        case .removeFailed(let reason):
            return "Failed to remove resource: \(reason)"
        case .invalidIdentifier(let reason):
            return "Invalid resource identifier: \(reason)"
        case .invalidMetadata(let reason):
            return "Invalid resource metadata: \(reason)"
        case .cacheError(let reason):
            return "Resource cache error: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .resourceNotFound:
            return "Check if the resource exists"
        case .invalidResourceType:
            return "Use a valid resource type"
        case .invalidResourceData:
            return "Check resource data format"
        case .storeFailed:
            return "Check disk space and permissions"
        case .loadFailed:
            return "Check if resource exists and is accessible"
        case .removeFailed:
            return "Check resource permissions"
        case .invalidIdentifier:
            return "Use a valid resource identifier"
        case .invalidMetadata:
            return "Check resource metadata format"
        case .cacheError:
            return "Try reloading the resource cache"
        }
    }
}
