import Foundation

/// Errors that can occur during service dependency management
@objc
public enum ServiceDependencyError: Int, ServiceErrorProtocol {
    /// Required dependency is missing
    case missingDependency
    /// Dependency initialization failed
    case initializationFailed
    /// Dependency validation failed
    case validationFailed
    /// Circular dependency detected
    case circularDependency
    
    /// Service name associated with the error
    public var serviceName: String {
        "DependencyService"
    }
    
    /// Localized description of the error
    public var localizedDescription: String {
        switch self {
        case .missingDependency:
            return "Required service dependency is missing"
        case .initializationFailed:
            return "Failed to initialize service dependency"
        case .validationFailed:
            return "Service dependency validation failed"
        case .circularDependency:
            return "Circular dependency detected in service graph"
        }
    }
    
    /// Reason for the failure
    public var failureReason: String? {
        switch self {
        case .missingDependency:
            return "A required dependency was not provided or could not be found"
        case .initializationFailed:
            return "The dependency could not be properly initialized"
        case .validationFailed:
            return "The dependency failed validation checks"
        case .circularDependency:
            return "A circular reference was detected in the dependency graph"
        }
    }
    
    /// Suggestion for recovering from the error
    public var recoverySuggestion: String? {
        switch self {
        case .missingDependency:
            return "Ensure all required dependencies are properly registered"
        case .initializationFailed:
            return "Check the dependency configuration and try again"
        case .validationFailed:
            return "Verify the dependency meets all requirements"
        case .circularDependency:
            return "Review the dependency graph and remove circular references"
        }
    }
}
