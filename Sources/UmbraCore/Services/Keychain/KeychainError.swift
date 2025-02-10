//
// KeychainError.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation
import Security

/// Errors that can occur during keychain operations
public enum KeychainError: LocalizedError {
    /// Add operation failed
    case addFailed(account: String, service: String, status: OSStatus)
    /// Update operation failed
    case updateFailed(account: String, service: String, status: OSStatus)
    /// Delete operation failed
    case deleteFailed(account: String, service: String, status: OSStatus)
    /// Get operation failed
    case getFailed(account: String, service: String, status: OSStatus)
    /// Invalid data
    case invalidData(String)
    /// Invalid access group
    case invalidAccessGroup(String)
    /// Invalid configuration
    case invalidConfiguration(String)
    /// Operation failed
    case operationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .addFailed(let account, let service, let status):
            return """
                Failed to add keychain item:
                Account: \(account)
                Service: \(service)
                Status: \(status) (\(securityError(for: status)))
                """
        case .updateFailed(let account, let service, let status):
            return """
                Failed to update keychain item:
                Account: \(account)
                Service: \(service)
                Status: \(status) (\(securityError(for: status)))
                """
        case .deleteFailed(let account, let service, let status):
            return """
                Failed to delete keychain item:
                Account: \(account)
                Service: \(service)
                Status: \(status) (\(securityError(for: status)))
                """
        case .getFailed(let account, let service, let status):
            return """
                Failed to get keychain item:
                Account: \(account)
                Service: \(service)
                Status: \(status) (\(securityError(for: status)))
                """
        case .invalidData(let reason):
            return "Invalid keychain data: \(reason)"
        case .invalidAccessGroup(let group):
            return "Invalid keychain access group: \(group)"
        case .invalidConfiguration(let reason):
            return "Invalid keychain configuration: \(reason)"
        case .operationFailed(let reason):
            return "Keychain operation failed: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .addFailed:
            return "Check item uniqueness and access permissions"
        case .updateFailed:
            return "Check item existence and access permissions"
        case .deleteFailed:
            return "Check item existence and access permissions"
        case .getFailed:
            return "Check item existence and access permissions"
        case .invalidData:
            return "Check data format and encoding"
        case .invalidAccessGroup:
            return "Check access group configuration"
        case .invalidConfiguration:
            return "Check keychain configuration"
        case .operationFailed:
            return "Try the operation again"
        }
    }

    public var helpAnchor: String? {
        switch self {
        case .addFailed:
            return "keychain_add"
        case .updateFailed:
            return "keychain_update"
        case .deleteFailed:
            return "keychain_delete"
        case .getFailed:
            return "keychain_get"
        case .invalidData:
            return "keychain_data"
        case .invalidAccessGroup:
            return "keychain_access_groups"
        case .invalidConfiguration:
            return "keychain_configuration"
        case .operationFailed:
            return "keychain_troubleshooting"
        }
    }

    /// Get security error description
    /// - Parameter status: Security framework status code
    /// - Returns: Error description
    private func securityError(for status: OSStatus) -> String {
        switch status {
        case errSecSuccess:
            return "No error"
        case errSecUnimplemented:
            return "Function not implemented"
        case errSecParam:
            return "Invalid parameters"
        case errSecAllocate:
            return "Failed to allocate memory"
        case errSecNotAvailable:
            return "No keychain is available"
        case errSecDuplicateItem:
            return "Item already exists"
        case errSecItemNotFound:
            return "Item not found"
        case errSecInteractionNotAllowed:
            return "Interaction not allowed"
        case errSecDecode:
            return "Unable to decode data"
        case errSecAuthFailed:
            return "Authentication failed"
        default:
            return "Unknown error (\(status))"
        }
    }
}
