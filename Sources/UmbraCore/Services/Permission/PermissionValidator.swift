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
        public init(passed: Bool, issues: [ValidationIssue] = []) {
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
        public init(type: IssueType, description: String) {
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
    /// Resource availability checker
    private let resourceChecker: ResourceAvailabilityChecking
    // MARK: - Initialization
    /// Initialize with dependencies
    /// - Parameters:
    ///   - logger: Logger for tracking operations
    ///   - resourceChecker: Resource availability checker
    public init(
        logger: LoggerProtocol,
        resourceChecker: ResourceAvailabilityChecking = ResourceAvailabilityChecker()
    ) {
        self.logger = logger
        self.resourceChecker = resourceChecker
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
            let issue = ValidationIssue(
                type: .permissionMissing,
                description: "Permission not found: \(type)"
            )
            issues.append(issue)
            return ValidationResult(passed: false, issues: issues)
        }
        // Validate access level
        if !isAccessLevelValid(currentLevel, required: accessLevel) {
            let issue = ValidationIssue(
                type: .invalidAccessLevel,
                description: "Invalid access level: \(currentLevel)"
            )
            issues.append(issue)
        }
        // Validate resource availability
        if !await resourceChecker.isResourceAvailable(type) {
            let issue = ValidationIssue(
                type: .resourceUnavailable,
                description: "Resource unavailable: \(type)"
            )
            issues.append(issue)
        }
        // Log validation result
        let logMessage = """
            Permission validation:
            Type: \(type)
            Required: \(accessLevel)
            Current: \(currentLevel)
            Issues: \(issues.count)
            """
        logger.debug(logMessage, file: #file, function: #function, line: #line)
        return ValidationResult(passed: issues.isEmpty, issues: issues)
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
            return false // Custom access levels require specific handling
        default:
            return false
        }
    }
}

/// Protocol for checking resource availability
public protocol ResourceAvailabilityChecking {
    /// Check if resource is available
    func isResourceAvailable(_ type: PermissionManager.PermissionType) async -> Bool
}

/// Default implementation of resource availability checking
public struct ResourceAvailabilityChecker: ResourceAvailabilityChecking {
    public init() {}
    public func isResourceAvailable(_ type: PermissionManager.PermissionType) async -> Bool {
        switch type {
        case .fileSystem:
            return FileManager.default.isUbiquitousItemAvailable
        case .keychain, .network, .camera, .microphone,
             .location, .notifications, .calendar,
             .contacts, .photos:
            return true // These should be implemented with actual availability checks
        case .custom:
            return false // Custom types require specific handling
        }
    }
}
