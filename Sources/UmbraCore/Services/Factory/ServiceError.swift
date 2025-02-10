//
// ServiceError.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Errors that can occur during service operations
public enum ServiceError: LocalizedError {
    /// Service not found
    case serviceNotFound(String)
    /// Invalid service type
    case invalidServiceType(String)
    /// Service creation failed
    case serviceCreationFailed(String)
    /// Service configuration failed
    case serviceConfigurationFailed(String)
    /// Service initialization failed
    case serviceInitializationFailed(String)
    /// Service registration failed
    case serviceRegistrationFailed(String)
    /// Invalid configuration
    case invalidConfiguration(String)
    /// Operation failed
    case operationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .serviceNotFound(let service):
            return "Service not found: \(service)"
        case .invalidServiceType(let type):
            return "Invalid service type: \(type)"
        case .serviceCreationFailed(let reason):
            return "Failed to create service: \(reason)"
        case .serviceConfigurationFailed(let reason):
            return "Failed to configure service: \(reason)"
        case .serviceInitializationFailed(let reason):
            return "Failed to initialize service: \(reason)"
        case .serviceRegistrationFailed(let reason):
            return "Failed to register service: \(reason)"
        case .invalidConfiguration(let reason):
            return "Invalid service configuration: \(reason)"
        case .operationFailed(let reason):
            return "Service operation failed: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .serviceNotFound:
            return "Check service name and registration"
        case .invalidServiceType:
            return "Check service type and protocol"
        case .serviceCreationFailed:
            return "Check service dependencies"
        case .serviceConfigurationFailed:
            return "Check service configuration"
        case .serviceInitializationFailed:
            return "Check service initialization"
        case .serviceRegistrationFailed:
            return "Check service registration"
        case .invalidConfiguration:
            return "Check factory configuration"
        case .operationFailed:
            return "Try the operation again"
        }
    }

    public var helpAnchor: String? {
        switch self {
        case .serviceNotFound:
            return "service_lookup"
        case .invalidServiceType:
            return "service_types"
        case .serviceCreationFailed:
            return "service_creation"
        case .serviceConfigurationFailed:
            return "service_configuration"
        case .serviceInitializationFailed:
            return "service_initialization"
        case .serviceRegistrationFailed:
            return "service_registration"
        case .invalidConfiguration:
            return "factory_configuration"
        case .operationFailed:
            return "service_troubleshooting"
        }
    }
}
