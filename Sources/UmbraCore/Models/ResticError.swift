//
// ResticError.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

// MARK: - Error Codes

/// Error codes for Restic backup operations
@objc
public enum ResticBackupErrorCode: Int {
    // MARK: - Repository Cases
    
    /// Repository not found at specified path
    case repositoryNotFound = 1
    
    /// Invalid repository credentials
    case invalidCredentials = 2
    
    /// Invalid repository structure
    case invalidRepositoryStructure = 10
    
    // MARK: - Operation Cases
    
    /// Backup operation failed
    case backupFailed = 3
    
    /// Restore operation failed
    case restoreFailed = 4
    
    /// Snapshot operation failed
    case snapshotFailed = 5
    
    /// Repository initialisation failed
    case initializationFailed = 6
    
    // MARK: - System Cases
    
    /// Permission denied for operation
    case permissionDenied = 7
    
    /// Network-related error
    case networkError = 8
    
    /// Unknown or unexpected error
    case unknownError = 9
}

// MARK: - Backup Error

/// Represents errors that can occur during Restic backup operations
@objc
public final class ResticBackupError: NSError {
    // MARK: - Properties
    
    /// Domain identifier for Restic backup errors
    public static let domain = "dev.mpy.rBUM.ResticBackup"
    
    /// Additional error details if available
    public var errorDetails: String? {
        userInfo[ErrorKeys.details] as? String
    }
    
    /// Timestamp when the error occurred
    public var errorTimestamp: Date? {
        userInfo[ErrorKeys.timestamp] as? Date
    }
    
    // MARK: - Factory Methods
    
    /// Creates a new ResticBackupError with the specified code and message
    /// - Parameters:
    ///   - code: The error code indicating the type of error
    ///   - message: A user-friendly description of the error
    ///   - details: Optional additional details about the error
    /// - Returns: A configured ResticBackupError instance
    public static func error(
        code: ResticBackupErrorCode,
        message: String,
        details: String? = nil
    ) -> ResticBackupError {
        var userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: message
        ]
        
        if let details {
            userInfo[ErrorKeys.details] = details
            userInfo[ErrorKeys.errorCode] = code.rawValue
            userInfo[ErrorKeys.timestamp] = Date()
        }
        
        return ResticBackupError(
            domain: domain,
            code: code.rawValue,
            userInfo: userInfo
        )
    }
}

// MARK: - Restic Error

/// Error type for Restic command operations
@objc
public enum ResticError: Int, LocalizedError {
    // MARK: - Command Cases
    
    /// Invalid command parameters or syntax
    case invalidCommand = 1
    
    /// Invalid working directory path
    case invalidWorkingDirectory = 2
    
    /// Invalid security-scoped bookmark
    case invalidBookmark = 3
    
    // MARK: - Permission Cases
    
    /// Access denied to resource
    case accessDenied = 4
    
    /// Resource-related error
    case resourceError = 5
    
    /// Unknown or unexpected error
    case unknownError = 6
    
    // MARK: - Operation Cases
    
    /// Compression operation failed
    case compressionError(String)
    
    /// Insufficient disk space for operation
    case insufficientDiskSpace(required: UInt64, available: UInt64)
    
    /// Invalid configuration settings
    case invalidConfiguration(String)
    
    /// Invalid repository credentials
    case invalidCredentials(String)
    
    /// Invalid file or directory path
    case invalidPath(String)
    
    /// Invalid application settings
    case invalidSettings(String)
    
    /// Invalid snapshot identifier
    case invalidSnapshotId(String)
    
    /// Invalid tag format or value
    case invalidTag(String)
    
    /// Repository lock error
    case lockError(String)
    
    /// Network-related error
    case networkError(String)
    
    // MARK: - Repository Cases
    
    /// Repository already exists
    case repositoryExists
    
    /// Repository not found at path
    case repositoryNotFound
    
    /// Restic binary not installed
    case resticNotInstalled
    
    /// Snapshot not found in repository
    case snapshotNotFound(String)
    
    /// Unexpected or internal error
    case unexpectedError(String)
    
    // MARK: - LocalizedError
    
    public var errorDescription: String? {
        switch self {
        case let .compressionError(message):
            return formatError("Compression error", message)
            
        case let .insufficientDiskSpace(required, available):
            return formatDiskSpaceError(
                required: required,
                available: available
            )
            
        case .invalidCommand:
            return "Invalid command"
            
        case .invalidWorkingDirectory:
            return "Invalid working directory"
            
        case .invalidBookmark:
            return "Invalid security-scoped bookmark"
            
        case .accessDenied:
            return "Access denied"
            
        case .resourceError:
            return "Resource error"
            
        case .unknownError:
            return "Unknown error"
            
        case let .invalidConfiguration(message):
            return formatError("Invalid configuration", message)
            
        case let .invalidCredentials(message):
            return formatError("Invalid credentials", message)
            
        case let .invalidPath(message):
            return formatError("Invalid path", message)
            
        case let .invalidSettings(message):
            return formatError("Invalid settings", message)
            
        case let .invalidSnapshotId(message):
            return formatError("Invalid snapshot ID", message)
            
        case let .invalidTag(message):
            return formatError("Invalid tag", message)
            
        case let .lockError(message):
            return formatError("Lock error", message)
            
        case let .networkError(message):
            return formatError("Network error", message)
            
        case .repositoryExists:
            return "Repository already exists"
            
        case .repositoryNotFound:
            return "Repository not found"
            
        case .resticNotInstalled:
            return "Restic is not installed"
            
        case let .snapshotNotFound(message):
            return formatError("Snapshot not found", message)
            
        case let .unexpectedError(message):
            return formatError("Unexpected error", message)
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .compressionError:
            return "Failed to compress or decompress data"
            
        case .insufficientDiskSpace:
            return "Not enough disk space available"
            
        case .invalidCommand:
            return "Command syntax or parameters are invalid"
            
        case .invalidWorkingDirectory:
            return "Working directory does not exist or is inaccessible"
            
        case .invalidBookmark:
            return "Security-scoped bookmark is invalid or expired"
            
        case .accessDenied:
            return "Permission denied for requested operation"
            
        case .resourceError:
            return "Failed to access or manage system resource"
            
        case .unknownError:
            return "An unexpected error occurred"
            
        case .invalidConfiguration:
            return "Configuration settings are invalid"
            
        case .invalidCredentials:
            return "Authentication credentials are invalid"
            
        case .invalidPath:
            return "File or directory path is invalid"
            
        case .invalidSettings:
            return "Application settings are invalid"
            
        case .invalidSnapshotId:
            return "Snapshot identifier is invalid"
            
        case .invalidTag:
            return "Tag format or value is invalid"
            
        case .lockError:
            return "Failed to acquire or release repository lock"
            
        case .networkError:
            return "Network operation failed"
            
        case .repositoryExists:
            return "Cannot create repository that already exists"
            
        case .repositoryNotFound:
            return "Repository does not exist at specified path"
            
        case .resticNotInstalled:
            return "Restic binary not found in system path"
            
        case .snapshotNotFound:
            return "Snapshot not found in repository"
            
        case .unexpectedError:
            return "An internal error occurred"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .compressionError:
            return "Check file permissions and available disk space"
            
        case .insufficientDiskSpace:
            return "Free up disk space or choose a different location"
            
        case .invalidCommand:
            return "Check command syntax and parameters"
            
        case .invalidWorkingDirectory:
            return "Verify directory exists and is accessible"
            
        case .invalidBookmark:
            return "Request access to the directory again"
            
        case .accessDenied:
            return "Request necessary permissions and try again"
            
        case .resourceError:
            return "Check system resources and try again"
            
        case .unknownError:
            return "Try again or contact support if the issue persists"
            
        case .invalidConfiguration:
            return "Check configuration settings and correct any errors"
            
        case .invalidCredentials:
            return "Verify credentials and try again"
            
        case .invalidPath:
            return "Check path exists and is accessible"
            
        case .invalidSettings:
            return "Review and correct application settings"
            
        case .invalidSnapshotId:
            return "Verify snapshot ID format and existence"
            
        case .invalidTag:
            return "Check tag format and allowed characters"
            
        case .lockError:
            return "Wait and try again, or check for stale locks"
            
        case .networkError:
            return "Check network connection and try again"
            
        case .repositoryExists:
            return "Use existing repository or choose different location"
            
        case .repositoryNotFound:
            return "Create repository or verify path"
            
        case .resticNotInstalled:
            return "Install Restic using package manager"
            
        case .snapshotNotFound:
            return "Verify snapshot exists in repository"
            
        case .unexpectedError:
            return "Report issue with error details"
        }
    }
    
    // MARK: - Factory Methods
    
    /// Creates an NSError from a ResticError
    /// - Parameters:
    ///   - code: The ResticError case
    ///   - message: Additional error message
    /// - Returns: Configured NSError instance
    public static func error(
        _ code: ResticError,
        _ message: String
    ) -> NSError {
        let userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: message,
            ErrorKeys.errorCode: code.rawValue,
            ErrorKeys.timestamp: Date()
        ]
        
        return NSError(
            domain: "dev.mpy.rBUM.Restic",
            code: code.rawValue,
            userInfo: userInfo
        )
    }
    
    // MARK: - Private Methods
    
    private func formatError(
        _ type: String,
        _ message: String
    ) -> String {
        "\(type): \(message)"
    }
    
    private func formatDiskSpaceError(
        required: UInt64,
        available: UInt64
    ) -> String {
        let requiredGB = Double(required) / 1_000_000_000
        let availableGB = Double(available) / 1_000_000_000
        return String(
            format: "Insufficient disk space - Required: %.2f GB, Available: %.2f GB",
            requiredGB,
            availableGB
        )
    }
}

// MARK: - Constants

private enum ErrorKeys {
    static let details = "ErrorDetailsKey"
    static let errorCode = "ErrorCodeKey"
    static let timestamp = "ErrorTimestampKey"
}
