import Foundation

// MARK: - ServiceErrorProtocol

/// Protocol defining common functionality for service-related errors
public protocol ServiceErrorProtocol: LocalizedError, CustomDebugStringConvertible {
    /// The category of the error
    var category: String { get }
    
    /// The severity level of the error
    var severity: String { get }
    
    /// Additional context or metadata about the error
    var context: [String: String] { get }
    
    /// Whether the error is recoverable
    var isRecoverable: Bool { get }
    
    /// Suggested recovery steps if applicable
    var recoverySuggestion: String? { get }
}

// MARK: - Error Conformance

public extension ServiceErrorProtocol {
    /// Convert to NSError
    var asNSError: NSError {
        let userInfo = [NSLocalizedDescriptionKey: localizedDescription]
        
        return NSError(
            domain: "dev.mpy.umbracore.service",
            code: 0,
            userInfo: userInfo
        )
    }
}

// MARK: - Default Implementations

public extension ServiceErrorProtocol {
    var errorDescription: String? {
        return localizedDescription
    }
    
    var debugDescription: String {
        return "\(localizedDescription) (category: \(category), severity: \(severity), context: \(context), recoverable: \(isRecoverable))"
    }
}
