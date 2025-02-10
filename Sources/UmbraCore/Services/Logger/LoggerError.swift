//
// LoggerError.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Errors that can occur during logging operations
public enum LoggerError: LocalizedError {
    /// Failed to write to log destination
    case writeFailure(Error)
    /// Invalid log configuration
    case invalidConfiguration(String)
    /// Log destination not accessible
    case destinationNotAccessible(URL)
    /// Permission denied
    case permissionDenied(URL)

    /// Localized description of the error
    public var errorDescription: String? {
        switch self {
        case .writeFailure(let error):
            return "Failed to write to log: \(error.localizedDescription)"
        case .invalidConfiguration(let reason):
            return "Invalid log configuration: \(reason)"
        case .destinationNotAccessible(let url):
            return "Log destination not accessible: \(url.path)"
        case .permissionDenied(let url):
            return "Permission denied for log destination: \(url.path)"
        }
    }

    /// Failure reason for the error
    public var failureReason: String? {
        switch self {
        case .writeFailure:
            return "The system was unable to write to the log destination"
        case .invalidConfiguration:
            return "The provided logging configuration is invalid"
        case .destinationNotAccessible:
            return "The specified log destination cannot be accessed"
        case .permissionDenied:
            return "The application does not have permission to access the log destination"
        }
    }

    /// Recovery suggestion for the error
    public var recoverySuggestion: String? {
        switch self {
        case .writeFailure:
            return "Check disk space and permissions"
        case .invalidConfiguration:
            return "Review logging configuration settings"
        case .destinationNotAccessible:
            return "Verify the log destination exists and is accessible"
        case .permissionDenied:
            return "Request necessary permissions or use a different log destination"
        }
    }
}
