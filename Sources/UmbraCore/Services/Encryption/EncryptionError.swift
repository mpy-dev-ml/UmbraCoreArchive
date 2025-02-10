//
// EncryptionError.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Errors that can occur during encryption operations
public enum EncryptionError: LocalizedError {
    /// Key derivation failed
    case keyDerivationFailed
    /// Secure Enclave key creation failed
    case secureEnclaveKeyCreationFailed
    /// Invalid key size
    case invalidKeySize(Int)
    /// Invalid input data
    case invalidInputData(String)
    /// Encryption failed
    case encryptionFailed(String)
    /// Decryption failed
    case decryptionFailed(String)
    /// Invalid algorithm parameters
    case invalidParameters(String)
    /// Operation not supported
    case operationNotSupported(String)

    /// Localized description of the error
    public var errorDescription: String? {
        switch self {
        case .keyDerivationFailed:
            return "Failed to derive encryption key"
        case .secureEnclaveKeyCreationFailed:
            return "Failed to create Secure Enclave key"
        case .invalidKeySize(let size):
            return "Invalid key size: \(size) bits"
        case .invalidInputData(let reason):
            return "Invalid input data: \(reason)"
        case .encryptionFailed(let reason):
            return "Encryption failed: \(reason)"
        case .decryptionFailed(let reason):
            return "Decryption failed: \(reason)"
        case .invalidParameters(let reason):
            return "Invalid parameters: \(reason)"
        case .operationNotSupported(let reason):
            return "Operation not supported: \(reason)"
        }
    }

    /// Failure reason for the error
    public var failureReason: String? {
        switch self {
        case .keyDerivationFailed:
            return "The key derivation process failed to complete successfully"
        case .secureEnclaveKeyCreationFailed:
            return "Failed to create a key in the Secure Enclave"
        case .invalidKeySize:
            return "The specified key size is not supported"
        case .invalidInputData:
            return "The provided input data is invalid or corrupted"
        case .encryptionFailed:
            return "The encryption operation failed to complete"
        case .decryptionFailed:
            return "The decryption operation failed to complete"
        case .invalidParameters:
            return "The provided parameters are invalid or incompatible"
        case .operationNotSupported:
            return "The requested operation is not supported"
        }
    }

    /// Recovery suggestion for the error
    public var recoverySuggestion: String? {
        switch self {
        case .keyDerivationFailed:
            return "Try using a different key or key derivation parameters"
        case .secureEnclaveKeyCreationFailed:
            return "Check if the Secure Enclave is available and try again"
        case .invalidKeySize:
            return "Use a supported key size (e.g., 128, 256 bits)"
        case .invalidInputData:
            return "Verify the input data is valid and try again"
        case .encryptionFailed:
            return "Check the encryption parameters and try again"
        case .decryptionFailed:
            return "Verify the key and encrypted data are correct"
        case .invalidParameters:
            return "Check the documentation for supported parameters"
        case .operationNotSupported:
            return "Use a supported operation or algorithm"
        }
    }

    /// Help anchor for documentation
    public var helpAnchor: String {
        switch self {
        case .keyDerivationFailed:
            return "encryption-key-derivation-failed"
        case .secureEnclaveKeyCreationFailed:
            return "encryption-secure-enclave-failed"
        case .invalidKeySize:
            return "encryption-invalid-key-size"
        case .invalidInputData:
            return "encryption-invalid-input"
        case .encryptionFailed:
            return "encryption-failed"
        case .decryptionFailed:
            return "encryption-decryption-failed"
        case .invalidParameters:
            return "encryption-invalid-parameters"
        case .operationNotSupported:
            return "encryption-operation-not-supported"
        }
    }
}
