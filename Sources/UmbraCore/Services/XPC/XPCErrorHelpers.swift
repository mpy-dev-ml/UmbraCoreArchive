@preconcurrency import Foundation

// MARK: - XPCError+Helpers

extension XPCError {
    // MARK: - Connection Error Helpers

    func getConnectionFailureReason(_ error: XPCError) -> String {
        switch error {
        case .serviceUnavailable:
            "XPC service is not available or has terminated"
        case .notConnected:
            "No active connection to XPC service"
        case .invalidState:
            "Connection is in an invalid state"
        case .timeout:
            "Connection operation timed out"
        case .reconnectionFailed:
            "Failed to re-establish connection"
        default:
            "Unknown connection error occurred"
        }
    }

    func getConnectionErrorCode(_ error: XPCError) -> String {
        switch error {
        case .serviceUnavailable:
            "XPC_ERR_SERVICE_UNAVAILABLE"
        case .notConnected:
            "XPC_ERR_NOT_CONNECTED"
        case .invalidState:
            "XPC_ERR_INVALID_STATE"
        case .timeout:
            "XPC_ERR_TIMEOUT"
        case .reconnectionFailed:
            "XPC_ERR_RECONNECTION_FAILED"
        default:
            "XPC_ERR_UNKNOWN"
        }
    }

    // MARK: - Protocol Error Helpers

    func getProtocolFailureReason(_ error: XPCError) -> String {
        switch error {
        case .invalidProxy:
            "Invalid proxy object received"
        case .invalidMessage:
            "Invalid message format or content"
        case .invalidInterface:
            "Interface configuration is invalid"
        case .protocolMismatch:
            "Protocol version mismatch detected"
        default:
            "Unknown protocol error occurred"
        }
    }

    func getProtocolHelpAnchor(_ error: XPCError) -> String {
        switch error {
        case .invalidProxy:
            "xpc-invalid-proxy"
        case .invalidMessage:
            "xpc-invalid-message"
        case .invalidInterface:
            "xpc-invalid-interface"
        case .protocolMismatch:
            "xpc-protocol-mismatch"
        default:
            "xpc-unknown-error"
        }
    }

    // MARK: - Security Error Helpers

    func getSecurityFailureReason(_ error: XPCError) -> String {
        switch error {
        case .securityViolation:
            "Security policy violation detected"
        case .invalidEntitlements:
            "Required entitlements are missing"
        case .auditSessionInvalid:
            "Audit session validation failed"
        case .sandboxViolation:
            "Sandbox policy violation detected"
        default:
            "Unknown security error occurred"
        }
    }

    func getSecurityRecoverySuggestion(_ error: XPCError) -> String {
        switch error {
        case .securityViolation:
            "Check security policy configuration"
        case .invalidEntitlements:
            "Verify required entitlements are present"
        case .auditSessionInvalid:
            "Validate audit session configuration"
        case .sandboxViolation:
            "Review sandbox policy settings"
        default:
            "Review security configuration"
        }
    }
}
