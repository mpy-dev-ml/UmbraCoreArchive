//
// PersistenceError.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Errors that can occur during persistence operations
public enum PersistenceError: LocalizedError {
    /// Directory not found
    case directoryNotFound
    /// File not found
    case fileNotFound(String)
    /// Save failed
    case saveFailed(String)
    /// Load failed
    case loadFailed(String)
    /// Remove failed
    case removeFailed(String)
    /// Compression failed
    case compressionFailed(String)
    /// Decompression failed
    case decompressionFailed(String)
    /// Encryption failed
    case encryptionFailed(String)
    /// Decryption failed
    case decryptionFailed(String)
    /// Invalid key
    case invalidKey(String)
    /// Invalid data
    case invalidData(String)

    public var errorDescription: String? {
        switch self {
        case .directoryNotFound:
            return "Storage directory not found"
        case .fileNotFound(let key):
            return "File not found for key: \(key)"
        case .saveFailed(let reason):
            return "Failed to save data: \(reason)"
        case .loadFailed(let reason):
            return "Failed to load data: \(reason)"
        case .removeFailed(let reason):
            return "Failed to remove data: \(reason)"
        case .compressionFailed(let reason):
            return "Failed to compress data: \(reason)"
        case .decompressionFailed(let reason):
            return "Failed to decompress data: \(reason)"
        case .encryptionFailed(let reason):
            return "Failed to encrypt data: \(reason)"
        case .decryptionFailed(let reason):
            return "Failed to decrypt data: \(reason)"
        case .invalidKey(let reason):
            return "Invalid storage key: \(reason)"
        case .invalidData(let reason):
            return "Invalid data: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .directoryNotFound:
            return "Try reinitialising the persistence service"
        case .fileNotFound:
            return "Check if the data was previously saved"
        case .saveFailed:
            return "Check disk space and permissions"
        case .loadFailed:
            return "Check if the file exists and is accessible"
        case .removeFailed:
            return "Check file permissions"
        case .compressionFailed, .decompressionFailed:
            return "Check data format and try again"
        case .encryptionFailed, .decryptionFailed:
            return "Check encryption key and try again"
        case .invalidKey:
            return "Use a valid storage key"
        case .invalidData:
            return "Check data format and try again"
        }
    }
}
