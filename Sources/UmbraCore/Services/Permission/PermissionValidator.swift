//
// PermissionValidator.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Validator for permission operations
public struct PermissionValidator {
    // MARK: - Types
    
    /// Validation result
    public struct ValidationResult {
        /// Whether validation passed
        public let passed: Bool
        
        /// Validation issues if any
        public let issues: [ValidationIssue]
        
        /// Initialize with values
        public init(
            passed: Bool,
            issues: [ValidationIssue] = []
        ) {
            self.passed = passed
            self.issues = issues
        }
    }
    
    /// Validation issue
    public struct ValidationIssue {
        /// Issue type
        public let type: IssueType
        
        /// Issue description
        public let description: String
        
        /// Initialize with values
        public init(
            type: IssueType,
            description: String
        ) {
            self.type = type
            self.description = description
        }
    }
    
    /// Issue type
    public enum IssueType {
        /// Permission missing
        case permissionMissing
        /// Permission expired
        case permissionExpired
        /// Invalid access level
        case invalidAccessLevel
        /// Invalid configuration
        case invalidConfiguration
        /// Resource unavailable
        case resourceUnavailable
        /// Custom issue
        case custom(String)
    }
    
    // MARK: - Properties
    
    /// Logger for tracking operations
    private let logger: LoggerProtocol
    
    // MARK: - Initialization
    
    /// Initialize with dependencies
    /// - Parameter logger: Logger for tracking operations
    public init(logger: LoggerProtocol) {
        self.logger = logger
    }
    
    // MARK: - Public Methods
    
    /// Validate permission
    /// - Parameters:
    ///   - type: Permission type
    ///   - accessLevel: Required access level
    ///   - manager: Permission manager
    /// - Returns: Validation result
    /// - Throws: Error if validation fails
    public func validatePermission(
        _ type: PermissionManager.PermissionType,
        accessLevel: PermissionManager.AccessLevel,
        manager: PermissionManager
    ) async throws -> ValidationResult {
        var issues: [ValidationIssue] = []
        
        // Check permission exists
        guard let currentLevel = try await manager.checkPermission(type) else {
            issues.append(
                ValidationIssue(
                    type: .permissionMissing,
                    description: "Permission not found: \(type)"
                )
            )
            return ValidationResult(passed: false, issues: issues)
        }
        
        // Validate access level
        if !isAccessLevelValid(currentLevel, required: accessLevel) {
            issues.append(
                ValidationIssue(
                    type: .invalidAccessLevel,
                    description: "Invalid access level: \(currentLevel)"
                )
            )
        }
        
        // Validate resource availability
        if !await isResourceAvailable(for: type) {
            issues.append(
                ValidationIssue(
                    type: .resourceUnavailable,
                    description: "Resource unavailable: \(type)"
                )
            )
        }
        
        // Log validation result
        logger.debug(
            """
            Permission validation:
            Type: \(type)
            Required: \(accessLevel)
            Current: \(currentLevel)
            Issues: \(issues.count)
            """,
            file: #file,
            function: #function,
            line: #line
        )
        
        return ValidationResult(
            passed: issues.isEmpty,
            issues: issues
        )
    }
    
    // MARK: - Private Methods
    
    /// Check if access level is valid
    private func isAccessLevelValid(
        _ current: PermissionManager.AccessLevel,
        required: PermissionManager.AccessLevel
    ) -> Bool {
        switch (current, required) {
        case (.full, _):
            return true
        case (.readWrite, .readWrite), (.readWrite, .readOnly):
            return true
        case (.readOnly, .readOnly):
            return true
        case (.custom, _), (_, .custom):
            // Custom access levels require specific handling
            return false
        default:
            return false
        }
    }
    
    /// Check if resource is available
    private func isResourceAvailable(
        for type: PermissionManager.PermissionType
    ) async -> Bool {
        switch type {
        case .fileSystem:
            return FileManager.default.isUbiquitousItemAvailable
        case .keychain:
            return true // Keychain is always available
        case .network:
            return true // Network availability should be checked
        case .camera:
            return true // Camera availability should be checked
        case .microphone:
            return true // Microphone availability should be checked
        case .location:
            return true // Location services availability should be checked
        case .notifications:
            return true // Notification availability should be checked
        case .calendar:
            return true // Calendar availability should be checked
        case .contacts:
            return true // Contacts availability should be checked
        case .photos:
            return true // Photos availability should be checked
        case .custom:
            return false // Custom types require specific handling
        }
    }
}
