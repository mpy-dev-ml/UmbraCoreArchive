import Foundation

// MARK: - XPC Error

/// Errors that can occur during XPC operations
public enum XPCError: LocalizedError {
    // MARK: - Connection Errors

    /// Service is not available
    case serviceUnavailable(reason: String)

    /// Not connected to service
    case notConnected(reason: String)

    /// Invalid connection state
    case invalidState(reason: String)

    /// Connection timeout
    case timeout(reason: String)

    /// Reconnection failed
    case reconnectionFailed(reason: String)

    // MARK: - Protocol Errors

    /// Invalid proxy object
    case invalidProxy(reason: String)

    /// Invalid message format or content
    case invalidMessage(reason: String)

    /// Invalid interface configuration
    case invalidInterface(reason: String)

    /// Protocol version mismatch
    case protocolMismatch(reason: String)

    // MARK: - Security Errors

    /// Security violation
    case securityViolation(reason: String)

    /// Invalid entitlements
    case invalidEntitlements(reason: String)

    /// Audit session validation failed
    case auditSessionInvalid(reason: String)

    /// Sandbox violation
    case sandboxViolation(reason: String)

    // MARK: - Operation Errors

    /// Operation failed
    case operationFailed(reason: String)

    /// Operation cancelled
    case operationCancelled(reason: String)

    /// Operation timeout
    case operationTimeout(reason: String)

    /// Resource unavailable
    case resourceUnavailable(reason: String)

    // MARK: - System Errors

    /// System resource error
    case systemResource(reason: String)

    /// Memory pressure
    case memoryPressure(reason: String)

    /// Process terminated
    case processTerminated(reason: String)

    // MARK: Public

    // MARK: - LocalizedError Implementation

    /// Localised description of the error
    public var errorDescription: String? {
        switch self {
        // Connection Errors
        case let .serviceUnavailable(reason):
            "XPC service is unavailable: \(reason)"
        case let .notConnected(reason):
            "Not connected to XPC service: \(reason)"
        case let .invalidState(reason):
            "Invalid connection state: \(reason)"
        case let .timeout(reason):
            "Connection timed out: \(reason)"
        case let .reconnectionFailed(reason):
            "Reconnection failed: \(reason)"
        // Protocol Errors
        case let .invalidProxy(reason):
            "Invalid proxy object: \(reason)"
        case let .invalidMessage(reason):
            "Invalid message: \(reason)"
        case let .invalidInterface(reason):
            "Invalid interface: \(reason)"
        case let .protocolMismatch(reason):
            "Protocol mismatch: \(reason)"
        // Security Errors
        case let .securityViolation(reason):
            "Security violation: \(reason)"
        case let .invalidEntitlements(reason):
            "Invalid entitlements: \(reason)"
        case let .auditSessionInvalid(reason):
            "Audit session invalid: \(reason)"
        case let .sandboxViolation(reason):
            "Sandbox violation: \(reason)"
        // Operation Errors
        case let .operationFailed(reason):
            "Operation failed: \(reason)"
        case let .operationCancelled(reason):
            "Operation cancelled: \(reason)"
        case let .operationTimeout(reason):
            "Operation timed out: \(reason)"
        case let .resourceUnavailable(reason):
            "Resource unavailable: \(reason)"
        // System Errors
        case let .systemResource(reason):
            "System resource error: \(reason)"
        case let .memoryPressure(reason):
            "Memory pressure: \(reason)"
        case let .processTerminated(reason):
            "Process terminated: \(reason)"
        }
    }

    /// Detailed failure reason
    public var failureReason: String? {
        switch self {
        // Connection Errors
        case .serviceUnavailable:
            "The XPC service is not available or has been terminated"
        case .notConnected:
            "No active connection to the XPC service exists"
        case .invalidState:
            "The connection is in an invalid state for the requested operation"
        case .timeout:
            "The operation exceeded the maximum allowed time"
        case .reconnectionFailed:
            "Attempts to re-establish the connection were unsuccessful"
        // Protocol Errors
        case .invalidProxy:
            "Failed to obtain or cast a valid proxy object"
        case .invalidMessage:
            "The message format or content is invalid or corrupted"
        case .invalidInterface:
            "The XPC interface configuration is invalid or incompatible"
        case .protocolMismatch:
            "The client and service protocol versions are incompatible"
        // Security Errors
        case .securityViolation:
            "A security policy or requirement was violated"
        case .invalidEntitlements:
            "The required entitlements are missing or invalid"
        case .auditSessionInvalid:
            "The audit session validation failed"
        case .sandboxViolation:
            "The operation violated sandbox restrictions"
        // Operation Errors
        case .operationFailed:
            "The requested operation failed to complete successfully"
        case .operationCancelled:
            "The operation was cancelled before completion"
        case .operationTimeout:
            "The operation did not complete within the time limit"
        case .resourceUnavailable:
            "A required resource is not available"
        // System Errors
        case .systemResource:
            "A system resource constraint was encountered"
        case .memoryPressure:
            "The system is experiencing memory pressure"
        case .processTerminated:
            "The XPC service process was terminated"
        }
    }

    /// Suggested recovery steps
    public var recoverySuggestion: String? {
        switch self {
        // Connection Errors
        case .serviceUnavailable:
            "Check if the XPC service is installed and running"
        case .notConnected:
            "Establish a connection before performing operations"
        case .invalidState:
            "Wait for the connection to stabilise and try again"
        case .timeout:
            "Check system load and network conditions, then retry"
        case .reconnectionFailed:
            "Check service availability and connection settings"
        // Protocol Errors
        case .invalidProxy:
            "Verify interface protocol and reconnect"
        case .invalidMessage:
            "Check message format and content validity"
        case .invalidInterface:
            "Verify interface configuration and compatibility"
        case .protocolMismatch:
            "Update client or service to compatible versions"
        // Security Errors
        case .securityViolation:
            "Review security policies and permissions"
        case .invalidEntitlements:
            "Verify app entitlements configuration"
        case .auditSessionInvalid:
            "Check audit session configuration"
        case .sandboxViolation:
            "Review sandbox permissions and entitlements"
        // Operation Errors
        case .operationFailed:
            "Check logs for details and try again"
        case .operationCancelled:
            "Retry the operation if still needed"
        case .operationTimeout:
            "Consider increasing timeout duration"
        case .resourceUnavailable:
            "Wait for resource availability and retry"
        // System Errors
        case .systemResource:
            "Free up system resources and retry"
        case .memoryPressure:
            "Free up memory or wait for pressure to decrease"
        case .processTerminated:
            "Restart the XPC service and reconnect"
        }
    }

    /// Documentation help anchor
    public var helpAnchor: String {
        switch self {
        // Connection Errors
        case .serviceUnavailable: "xpc-service-unavailable"
        case .notConnected: "xpc-not-connected"
        case .invalidState: "xpc-invalid-state"
        case .timeout: "xpc-timeout"
        case .reconnectionFailed: "xpc-reconnection-failed"
        // Protocol Errors
        case .invalidProxy: "xpc-invalid-proxy"
        case .invalidMessage: "xpc-invalid-message"
        case .invalidInterface: "xpc-invalid-interface"
        case .protocolMismatch: "xpc-protocol-mismatch"
        // Security Errors
        case .securityViolation: "xpc-security-violation"
        case .invalidEntitlements: "xpc-invalid-entitlements"
        case .auditSessionInvalid: "xpc-audit-session-invalid"
        case .sandboxViolation: "xpc-sandbox-violation"
        // Operation Errors
        case .operationFailed: "xpc-operation-failed"
        case .operationCancelled: "xpc-operation-cancelled"
        case .operationTimeout: "xpc-operation-timeout"
        case .resourceUnavailable: "xpc-resource-unavailable"
        // System Errors
        case .systemResource: "xpc-system-resource"
        case .memoryPressure: "xpc-memory-pressure"
        case .processTerminated: "xpc-process-terminated"
        }
    }

    /// Error code for logging and analytics
    public var errorCode: String {
        switch self {
        // Connection Errors
        case .serviceUnavailable: "XPC001"
        case .notConnected: "XPC002"
        case .invalidState: "XPC003"
        case .timeout: "XPC004"
        case .reconnectionFailed: "XPC005"
        // Protocol Errors
        case .invalidProxy: "XPC101"
        case .invalidMessage: "XPC102"
        case .invalidInterface: "XPC103"
        case .protocolMismatch: "XPC104"
        // Security Errors
        case .securityViolation: "XPC201"
        case .invalidEntitlements: "XPC202"
        case .auditSessionInvalid: "XPC203"
        case .sandboxViolation: "XPC204"
        // Operation Errors
        case .operationFailed: "XPC301"
        case .operationCancelled: "XPC302"
        case .operationTimeout: "XPC303"
        case .resourceUnavailable: "XPC304"
        // System Errors
        case .systemResource: "XPC401"
        case .memoryPressure: "XPC402"
        case .processTerminated: "XPC403"
        }
    }
}
