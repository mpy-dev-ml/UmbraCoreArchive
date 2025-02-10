//
// ServiceFactory+Validation.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

extension ServiceFactory {
    /// Validate service factory configuration
    /// - Returns: true if configuration is valid
    /// - Throws: ServiceFactoryError if validation fails
    public static func validateConfiguration() throws -> Bool {
        try queue.sync {
            // Validate development configuration
            if configuration.developmentEnabled {
                guard developmentConfiguration.artificialDelay >= 0 else {
                    throw ServiceFactoryError.invalidConfiguration(
                        "Artificial delay must be non-negative"
                    )
                }
            }

            return true
        }
    }

    /// Validate service creation
    /// - Parameter service: Service to validate
    /// - Returns: true if service is valid
    /// - Throws: ServiceFactoryError if validation fails
    public static func validateService(_ service: Any) throws -> Bool {
        try queue.sync {
            // Validate service type
            switch service {
            case let sandboxed as BaseSandboxedService:
                return try sandboxed.validateSandboxCompliance()

            case let logging as LoggingService:
                return logging.logger != nil

            default:
                throw ServiceFactoryError.invalidServiceType(
                    String(describing: type(of: service))
                )
            }
        }
    }
}

/// Errors that can occur in the service factory
public enum ServiceFactoryError: LocalizedError {
    /// Invalid configuration
    case invalidConfiguration(String)
    /// Invalid service type
    case invalidServiceType(String)
    /// Service creation failed
    case serviceCreationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let reason):
            return "Invalid service factory configuration: \(reason)"
        case .invalidServiceType(let type):
            return "Invalid service type: \(type)"
        case .serviceCreationFailed(let service):
            return "Failed to create service: \(service)"
        }
    }
}
