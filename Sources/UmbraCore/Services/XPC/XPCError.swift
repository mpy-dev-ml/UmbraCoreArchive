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

    // MARK: - System Errors

    /// System resource constraint
    case systemResource(reason: String)

    /// Memory pressure condition
    case memoryPressure(reason: String)

    /// Process limit reached
    case processLimit(reason: String)

    // MARK: - LocalizedError Implementation

    public var errorDescription: String? {
        switch self {
        case let .serviceUnavailable(reason),
             let .notConnected(reason),
             let .invalidState(reason),
             let .timeout(reason),
             let .reconnectionFailed(reason),
             let .invalidProxy(reason),
             let .invalidMessage(reason),
             let .invalidInterface(reason),
             let .protocolMismatch(reason),
             let .securityViolation(reason),
             let .invalidEntitlements(reason),
             let .auditSessionInvalid(reason),
             let .sandboxViolation(reason),
             let .systemResource(reason),
             let .memoryPressure(reason),
             let .processLimit(reason):
            reason
        }
    }

    public var failureReason: String? {
        switch self {
        case .serviceUnavailable, .notConnected, .invalidState, .timeout, .reconnectionFailed:
            XPCErrorHelpers.getConnectionFailureReason(self)

        case .invalidProxy, .invalidMessage, .invalidInterface, .protocolMismatch:
            XPCErrorHelpers.getProtocolFailureReason(self)

        case .securityViolation, .invalidEntitlements, .auditSessionInvalid, .sandboxViolation:
            XPCErrorHelpers.getSecurityFailureReason(self)

        case .systemResource, .memoryPressure, .processLimit:
            XPCErrorHelpers.getSystemFailureReason(self)
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .serviceUnavailable:
            "Check if the XPC service is running and properly configured"

        case .notConnected:
            "Try re-establishing the connection"

        case .invalidState:
            "Reset the connection state"

        case .timeout:
            "Check network connectivity and try again"

        case .reconnectionFailed:
            "Verify service availability and try reconnecting"

        case .invalidProxy:
            "Verify proxy configuration"

        case .invalidMessage:
            "Check message format and content"

        case .invalidInterface:
            "Update interface configuration"

        case .protocolMismatch:
            "Update to compatible protocol version"

        case .securityViolation, .invalidEntitlements, .auditSessionInvalid, .sandboxViolation:
            XPCErrorHelpers.getSecurityRecoverySuggestion(self)

        case .systemResource:
            "Free up system resources and try again"

        case .memoryPressure:
            "Free up memory and try again"

        case .processLimit:
            "Terminate unnecessary processes and try again"
        }
    }

    public var helpAnchor: String? {
        switch self {
        case .serviceUnavailable, .notConnected, .invalidState, .timeout, .reconnectionFailed:
            "xpc-connection-errors"

        case .invalidProxy, .invalidMessage, .invalidInterface, .protocolMismatch:
            XPCErrorHelpers.getProtocolHelpAnchor(self)

        case .securityViolation, .invalidEntitlements, .auditSessionInvalid, .sandboxViolation:
            "xpc-security-errors"

        case .systemResource, .memoryPressure, .processLimit:
            "xpc-system-errors"
        }
    }
}
