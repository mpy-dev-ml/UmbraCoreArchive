//
// ServiceError.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// An enumeration of errors that can occur during service lifecycle and operations.
///
/// `ServiceError` provides detailed error information for various aspects of
/// service management, including:
/// - Service lifecycle
/// - State management
/// - Dependency handling
/// - Operation execution
/// - Resource management
///
/// Each error case includes relevant context to help with:
/// - Error diagnosis
/// - State recovery
/// - User feedback
/// - System monitoring
///
/// Example usage:
/// ```swift
/// do {
///     try await service.initialize()
/// } catch let error as ServiceError {
///     switch error {
///     case .notInitialized(let service):
///         logger.error("Service not initialised: \(service)")
///     case .dependencyUnavailable(let service, let dependency):
///         logger.error("\(service) missing dependency: \(dependency)")
///     default:
///         logger.error("Service error: \(error.localizedDescription)")
///     }
///
///     if let recovery = error.recoverySuggestion {
///         logger.info("Recovery suggestion: \(recovery)")
///     }
/// }
/// ```

// MARK: - Service Error

/// Errors that can occur during service lifecycle and operations
@objc public enum ServiceError: Int, LocalizedError {
    // MARK: - Supporting Types
    
    /// Service state information
    public struct ServiceState: CustomStringConvertible {
        /// Name of the service state
        public let name: String
        
        /// Current state value
        public let state: String
        
        /// Creates a new service state
        /// - Parameters:
        ///   - name: Name of the service
        ///   - state: Current state
        public init(name: String, state: String) {
            self.name = name
            self.state = state
        }
        
        public var description: String {
            "\(name) in state: \(state)"
        }
    }
    
    /// Resource usage information
    public struct ResourceUsage: CustomStringConvertible {
        /// Current resource usage
        public let current: UInt64
        
        /// Resource usage limit
        public let limit: UInt64
        
        /// Unit of measurement
        public let unit: String
        
        /// Creates new resource usage
        /// - Parameters:
        ///   - current: Current usage
        ///   - limit: Usage limit
        ///   - unit: Measurement unit
        public init(
            current: UInt64,
            limit: UInt64,
            unit: String
        ) {
            self.current = current
            self.limit = limit
            self.unit = unit
        }
        
        public var description: String {
            String(
                format: "Current: %llu %@, Limit: %llu %@",
                current, unit, limit, unit
            )
        }
    }
    
    // MARK: - Lifecycle Cases
    
    /// Service not initialised
    case notInitialized(String)
    
    /// Service already initialised
    case alreadyInitialized(String)
    
    /// Service initialisation failed
    case initializationFailed(service: String, reason: String)
    
    // MARK: - State Cases
    
    /// Invalid service state
    case invalidState(
        service: String,
        current: ServiceState,
        expected: ServiceState
    )
    
    /// State transition failed
    case stateTransitionFailed(
        service: String,
        from: ServiceState,
        to: ServiceState
    )
    
    /// State lock timeout
    case stateLockTimeout(service: String, state: ServiceState)
    
    // MARK: - Dependency Cases
    
    /// Required dependency unavailable
    case dependencyUnavailable(service: String, dependency: String)
    
    /// Dependency misconfigured
    case dependencyMisconfigured(
        service: String,
        dependency: String,
        reason: String
    )
    
    /// Dependency timeout
    case dependencyTimeout(service: String, dependency: String)
    
    // MARK: - Operation Cases
    
    /// Operation failed
    case operationFailed(
        service: String,
        operation: String,
        reason: String
    )
    
    /// Operation timeout
    case operationTimeout(
        service: String,
        operation: String,
        duration: TimeInterval
    )
    
    /// Operation cancelled
    case operationCancelled(service: String, operation: String)
    
    // MARK: - Resource Cases
    
    /// Resource unavailable
    case resourceUnavailable(service: String, resource: String)
    
    /// Resource exhausted
    case resourceExhausted(service: String, resource: String)
    
    /// Resource limit exceeded
    case resourceLimitExceeded(
        service: String,
        resource: String,
        usage: ResourceUsage
    )
    
    // MARK: - Retry Cases
    
    /// Retry failed
    case retryFailed(
        service: String,
        operation: String,
        attempts: Int,
        error: Error
    )
    
    /// Retry limit exceeded
    case retryLimitExceeded(
        service: String,
        operation: String,
        limit: Int
    )
    
    // MARK: - Security Cases
    
    /// Authentication failed
    case authenticationFailed(service: String, reason: String)
    
    /// Authorization failed
    case authorizationFailed(service: String, resource: String)
    
    /// Security violation
    case securityViolation(service: String, violation: String)
    
    // MARK: - LocalizedError
    
    public var errorDescription: String? {
        switch self {
        case let .notInitialized(service):
            return "Service not initialised: \(service)"
            
        case let .alreadyInitialized(service):
            return "Service already initialised: \(service)"
            
        case let .initializationFailed(service, reason):
            return formatError(
                "Failed to initialise service",
                service: service,
                details: reason
            )
            
        case let .invalidState(service, current, expected):
            return formatError(
                "Invalid service state",
                service: service,
                details: "Current: \(current), Expected: \(expected)"
            )
            
        case let .stateTransitionFailed(service, from, to):
            return formatError(
                "State transition failed",
                service: service,
                details: "From: \(from), To: \(to)"
            )
            
        case let .stateLockTimeout(service, state):
            return formatError(
                "State lock timeout",
                service: service,
                details: "State: \(state)"
            )
            
        case let .dependencyUnavailable(service, dependency):
            return formatError(
                "Dependency unavailable",
                service: service,
                details: "Dependency: \(dependency)"
            )
            
        case let .dependencyMisconfigured(service, dependency, reason):
            return formatError(
                "Dependency misconfigured",
                service: service,
                details: "\(dependency): \(reason)"
            )
            
        case let .dependencyTimeout(service, dependency):
            return formatError(
                "Dependency timeout",
                service: service,
                details: "Dependency: \(dependency)"
            )
            
        case let .operationFailed(service, operation, reason):
            return formatError(
                "Operation failed",
                service: service,
                details: "\(operation): \(reason)"
            )
            
        case let .operationTimeout(service, operation, duration):
            return formatError(
                "Operation timeout",
                service: service,
                details: "\(operation) after \(duration)s"
            )
            
        case let .operationCancelled(service, operation):
            return formatError(
                "Operation cancelled",
                service: service,
                details: "Operation: \(operation)"
            )
            
        case let .resourceUnavailable(service, resource):
            return formatError(
                "Resource unavailable",
                service: service,
                details: "Resource: \(resource)"
            )
            
        case let .resourceExhausted(service, resource):
            return formatError(
                "Resource exhausted",
                service: service,
                details: "Resource: \(resource)"
            )
            
        case let .resourceLimitExceeded(service, resource, usage):
            return formatError(
                "Resource limit exceeded",
                service: service,
                details: "\(resource): \(usage)"
            )
            
        case let .retryFailed(service, operation, attempts, error):
            return formatError(
                "Retry failed",
                service: service,
                details: """
                    Operation: \(operation), \
                    Attempts: \(attempts), \
                    Error: \(error)
                    """
            )
            
        case let .retryLimitExceeded(service, operation, limit):
            return formatError(
                "Retry limit exceeded",
                service: service,
                details: """
                    Operation: \(operation), \
                    Limit: \(limit)
                    """
            )
            
        case let .authenticationFailed(service, reason):
            return formatError(
                "Authentication failed",
                service: service,
                details: reason
            )
            
        case let .authorizationFailed(service, resource):
            return formatError(
                "Authorisation failed",
                service: service,
                details: "Resource: \(resource)"
            )
            
        case let .securityViolation(service, violation):
            return formatError(
                "Security violation",
                service: service,
                details: violation
            )
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .notInitialized:
            return "Initialise the service before using it"
            
        case .alreadyInitialized:
            return "Ensure service is not already initialised"
            
        case .initializationFailed:
            return "Check the service configuration and try again"
            
        case .invalidState:
            return "Reset service to a valid state"
            
        case .stateTransitionFailed:
            return """
                Check if the state transition is valid \
                and retry
                """
            
        case .stateLockTimeout:
            return """
                Consider increasing the timeout duration \
                or check for deadlocks
                """
            
        case .dependencyUnavailable:
            return """
                Ensure all required dependencies are \
                available and running
                """
            
        case .dependencyMisconfigured:
            return """
                Check the dependency configuration \
                and correct any issues
                """
            
        case .dependencyTimeout:
            return """
                Verify the dependency is responsive \
                and increase timeout if needed
                """
            
        case .operationFailed:
            return "Check the operation parameters and try again"
            
        case .operationTimeout:
            return "Consider increasing the operation timeout"
            
        case .operationCancelled:
            return "Retry the operation if needed"
            
        case .resourceUnavailable:
            return """
                Wait for the resource to become available \
                or use an alternative
                """
            
        case .resourceExhausted:
            return """
                Wait for resources to be freed \
                or increase resource limits
                """
            
        case .resourceLimitExceeded:
            return """
                Reduce resource usage \
                or increase resource limits
                """
            
        case .retryFailed:
            return """
                Check the underlying error \
                and adjust retry strategy
                """
            
        case .retryLimitExceeded:
            return """
                Increase retry limit \
                or investigate persistent failures
                """
            
        case .authenticationFailed:
            return "Verify credentials and try again"
            
        case .authorizationFailed:
            return "Verify permissions and request access if needed"
            
        case .securityViolation:
            return "Review security policies and ensure compliance"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .notInitialized:
            return "Service must be initialised before use"
            
        case .alreadyInitialized:
            return "Service cannot be initialised multiple times"
            
        case .initializationFailed:
            return "Service initialisation encountered an error"
            
        case .invalidState:
            return "Service is in an invalid state for the requested operation"
            
        case .stateTransitionFailed:
            return "Service failed to transition between states"
            
        case .stateLockTimeout:
            return "Service failed to acquire state lock within timeout"
            
        case .dependencyUnavailable:
            return "Required service dependency is not available"
            
        case .dependencyMisconfigured:
            return "Service dependency is not properly configured"
            
        case .dependencyTimeout:
            return "Service dependency did not respond within timeout"
            
        case .operationFailed:
            return "Service operation encountered an error"
            
        case .operationTimeout:
            return "Service operation did not complete within timeout"
            
        case .operationCancelled:
            return "Service operation was cancelled"
            
        case .resourceUnavailable:
            return "Required resource is not available"
            
        case .resourceExhausted:
            return "Resource has been exhausted"
            
        case .resourceLimitExceeded:
            return "Resource usage exceeds configured limits"
            
        case .retryFailed:
            return "Operation retry attempts failed"
            
        case .retryLimitExceeded:
            return "Operation exceeded maximum retry attempts"
            
        case .authenticationFailed:
            return "Service authentication failed"
            
        case .authorizationFailed:
            return "Service authorisation failed"
            
        case .securityViolation:
            return "Service encountered a security violation"
        }
    }
    
    // MARK: - Private Methods
    
    private func formatError(
        _ type: String,
        service: String,
        details: String
    ) -> String {
        "\(type) in \(service): \(details)"
    }
}
