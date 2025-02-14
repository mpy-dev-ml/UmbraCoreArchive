import Foundation

// MARK: - ServiceErrorProtocol

/// Protocol defining common functionality for service-related errors
@objc
public protocol ServiceErrorProtocol: Error {
    /// Service name associated with the error
    var serviceName: String { get }
    
    /// Localized description of the error
    var localizedDescription: String { get }
    
    /// Reason for the error
    @objc optional var failureReason: String? { get }
    
    /// Suggestion for recovering from the error
    @objc optional var recoverySuggestion: String? { get }
    
    /// Error metadata dictionary
    var errorUserInfo: [String: Any] { get }
}

// MARK: - Error Conformance

public extension ServiceErrorProtocol {
    /// Convert to NSError
    var asNSError: NSError {
        let userInfo = errorUserInfo
        
        return NSError(
            domain: "dev.mpy.umbracore.service",
            code: 0,
            userInfo: userInfo
        )
    }
}

// MARK: - Default Implementations

public extension ServiceErrorProtocol {
    var errorUserInfo: [String: Any] {
        var info: [String: Any] = [
            "serviceName": serviceName
        ]
        
        if let reason = failureReason {
            info[NSLocalizedFailureReasonErrorKey] = reason
        }
        
        if let suggestion = recoverySuggestion {
            info[NSLocalizedRecoverySuggestionErrorKey] = suggestion
        }
        
        return info
    }
}
