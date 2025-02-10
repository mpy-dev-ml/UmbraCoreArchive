//
// ServiceLifecycle.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Service lifecycle management framework
///
/// The ServiceLifecycle framework provides a comprehensive solution for managing
/// the lifecycle of services within the application. It includes:
/// - State management and transitions
/// - Lifecycle event handling
/// - Error handling and recovery
/// - Validation and safety checks
public protocol ServiceLifecycle: AnyObject {
    /// Current state of the service
    var state: ServiceState { get }

    /// Logger for tracking operations
    var logger: LoggerProtocol { get }

    /// Initialize the service
    /// - Throws: ServiceLifecycleError if initialization fails
    func initialize() throws

    /// Start the service
    /// - Throws: ServiceLifecycleError if start fails
    func start() throws

    /// Stop the service
    /// - Throws: ServiceLifecycleError if stop fails
    func stop() throws

    /// Reset the service to its initial state
    /// - Throws: ServiceLifecycleError if reset fails
    func reset() throws
}

/// Possible states of a service
public enum ServiceState: String {
    /// Service is uninitialized
    case uninitialized
    /// Service is initialized but not started
    case initialized
    /// Service is starting
    case starting
    /// Service is running
    case running
    /// Service is stopping
    case stopping
    /// Service is stopped
    case stopped
    /// Service encountered an error
    case error

    /// Whether the service is in a usable state
    public var isUsable: Bool {
        self == .running
    }

    /// Whether the service can be started
    public var canStart: Bool {
        self == .initialized || self == .stopped
    }

    /// Whether the service can be stopped
    public var canStop: Bool {
        self == .running
    }
}

/// Default implementation of ServiceLifecycle
public extension ServiceLifecycle {
    /// Validate that the service is in a usable state
    /// - Parameter operation: Operation being attempted
    /// - Throws: ServiceLifecycleError if service is not usable
    func validateUsable(for operation: String) throws {
        guard state.isUsable else {
            throw ServiceLifecycleError.invalidState(
                "Cannot perform '\(operation)' in state '\(state.rawValue)'"
            )
        }
    }

    /// Validate that the service can be started
    /// - Throws: ServiceLifecycleError if service cannot be started
    func validateCanStart() throws {
        guard state.canStart else {
            throw ServiceLifecycleError.invalidState(
                "Cannot start service in state '\(state.rawValue)'"
            )
        }
    }

    /// Validate that the service can be stopped
    /// - Throws: ServiceLifecycleError if service cannot be stopped
    func validateCanStop() throws {
        guard state.canStop else {
            throw ServiceLifecycleError.invalidState(
                "Cannot stop service in state '\(state.rawValue)'"
            )
        }
    }
}

/// Errors that can occur in service lifecycle
public enum ServiceLifecycleError: LocalizedError {
    /// Service is in an invalid state for the requested operation
    case invalidState(String)
    /// Service initialization failed
    case initializationFailed(String)
    /// Service start failed
    case startFailed(String)
    /// Service stop failed
    case stopFailed(String)
    /// Service reset failed
    case resetFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidState(let reason):
            return "Invalid service state: \(reason)"
        case .initializationFailed(let reason):
            return "Service initialization failed: \(reason)"
        case .startFailed(let reason):
            return "Service start failed: \(reason)"
        case .stopFailed(let reason):
            return "Service stop failed: \(reason)"
        case .resetFailed(let reason):
            return "Service reset failed: \(reason)"
        }
    }
}
