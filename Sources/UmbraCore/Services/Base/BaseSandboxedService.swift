//
// BaseSandboxedService.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Base class for services that operate within the sandbox
public class BaseSandboxedService: BaseService {
    /// Queue for synchronizing sandbox operations
    private let sandboxQueue = DispatchQueue(
        label: "dev.mpy.umbracore.sandbox",
        qos: .userInitiated,
        attributes: .concurrent
    )

    /// Initialize with a logger
    /// - Parameter logger: Logger for tracking operations
    public override init(logger: LoggerProtocol) {
        super.init(logger: logger)
    }

    /// Validate that the service is operating within sandbox constraints
    /// - Returns: true if the service is properly sandboxed
    /// - Throws: SandboxError if validation fails
    public func validateSandboxCompliance() throws -> Bool {
        // Default implementation assumes compliance
        // Subclasses should override this if they need specific validation
        logger.debug(
            "Validating sandbox compliance",
            file: #file,
            function: #function,
            line: #line
        )
        return true
    }

    /// Execute an operation with sandbox validation
    /// - Parameters:
    ///   - operation: Name of the operation for logging
    ///   - action: The operation to execute
    /// - Returns: The result of the operation
    /// - Throws: SandboxError if validation fails or the operation fails
    public func withSandboxValidation<T>(
        operation: String,
        action: () async throws -> T
    ) async throws -> T {
        try await sandboxQueue.sync {
            guard try validateSandboxCompliance() else {
                throw SandboxError.complianceValidationFailed(operation)
            }
            return try await action()
        }
    }

    /// Clean up any resources when the service is being deallocated
    deinit {
        logger.debug(
            "Cleaning up sandboxed service resources",
            file: #file,
            function: #function,
            line: #line
        )
    }
}

/// Sandbox-related errors
public enum SandboxError: LocalizedError {
    /// Sandbox compliance validation failed
    case complianceValidationFailed(String)
    /// Operation not permitted in sandbox
    case operationNotPermitted(String)
    /// Resource access denied by sandbox
    case resourceAccessDenied(String)

    public var errorDescription: String? {
        switch self {
        case .complianceValidationFailed(let operation):
            return "Sandbox compliance validation failed for operation '\(operation)'"
        case .operationNotPermitted(let operation):
            return "Operation '\(operation)' is not permitted in sandbox"
        case .resourceAccessDenied(let resource):
            return "Sandbox denied access to resource '\(resource)'"
        }
    }
}
