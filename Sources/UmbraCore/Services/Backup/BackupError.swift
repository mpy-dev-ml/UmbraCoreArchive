//
// BackupError.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Errors that can occur during backup operations
public enum BackupError: LocalizedError {
    /// Invalid configuration
    case invalidConfiguration(String)
    /// Source not found
    case sourceNotFound(String)
    /// Storage not found
    case storageNotFound(String)
    /// Storage full
    case storageFull(String)
    /// Storage access denied
    case storageAccessDenied(String)
    /// Compression failed
    case compressionFailed(String)
    /// Encryption failed
    case encryptionFailed(String)
    /// Verification failed
    case verificationFailed(String)
    /// Retention failed
    case retentionFailed(String)
    /// Operation failed
    case operationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let reason):
            return "Invalid backup configuration: \(reason)"
        case .sourceNotFound(let path):
            return "Backup source not found: \(path)"
        case .storageNotFound(let location):
            return "Backup storage not found: \(location)"
        case .storageFull(let location):
            return "Backup storage full: \(location)"
        case .storageAccessDenied(let location):
            return "Backup storage access denied: \(location)"
        case .compressionFailed(let reason):
            return "Backup compression failed: \(reason)"
        case .encryptionFailed(let reason):
            return "Backup encryption failed: \(reason)"
        case .verificationFailed(let reason):
            return "Backup verification failed: \(reason)"
        case .retentionFailed(let reason):
            return "Backup retention failed: \(reason)"
        case .operationFailed(let reason):
            return "Backup operation failed: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidConfiguration:
            return "Check configuration settings"
        case .sourceNotFound:
            return "Verify source path exists"
        case .storageNotFound:
            return "Verify storage location exists"
        case .storageFull:
            return "Free up storage space"
        case .storageAccessDenied:
            return "Check storage permissions"
        case .compressionFailed:
            return "Check compression settings"
        case .encryptionFailed:
            return "Check encryption settings"
        case .verificationFailed:
            return "Try verifying backup again"
        case .retentionFailed:
            return "Check retention policy"
        case .operationFailed:
            return "Try the operation again"
        }
    }

    public var helpAnchor: String? {
        switch self {
        case .invalidConfiguration:
            return "backup_configuration"
        case .sourceNotFound:
            return "backup_sources"
        case .storageNotFound:
            return "backup_storage"
        case .storageFull:
            return "storage_management"
        case .storageAccessDenied:
            return "storage_permissions"
        case .compressionFailed:
            return "backup_compression"
        case .encryptionFailed:
            return "backup_encryption"
        case .verificationFailed:
            return "backup_verification"
        case .retentionFailed:
            return "backup_retention"
        case .operationFailed:
            return "backup_troubleshooting"
        }
    }
}
