@preconcurrency import Foundation
import Logging

// MARK: - XPCErrorHelpers

/// Helper functions for XPC error handling and diagnostics
/// enum for handling xPCErrorHelpers
@frozen
public enum XPCErrorHelpers {
    // MARK: - Types

    /// Error code prefix for XPC errors
    private static let errorCodePrefix = "XPC_ERR"

    /// Error code mapping
    public struct ErrorCode: Sendable {
        /// Error code string
        public let code: String
        /// Error domain
        public let domain: String
        /// Error category
        public let category: XPCError.Category

        fileprivate init(
            code: String,
            domain: String = "dev.mpy.umbra.xpc",
            category: XPCError.Category
        ) {
            self.code = code
            self.domain = domain
            self.category = category
        }
    }

    // MARK: - Error Codes

    /// Get error code for XPC error
    /// - Parameter error: XPC error
    /// - Returns: Error code information
    public static func getErrorCode(_ error: XPCError) -> ErrorCode {
        switch error {
        // Connection Errors
        case .serviceUnavailable:
            ErrorCode(code: "\(errorCodePrefix)_SERVICE_UNAVAILABLE", category: .connection)

        case .notConnected:
            ErrorCode(code: "\(errorCodePrefix)_NOT_CONNECTED", category: .connection)

        case .invalidState:
            ErrorCode(code: "\(errorCodePrefix)_INVALID_STATE", category: .connection)

        case .timeout:
            ErrorCode(code: "\(errorCodePrefix)_TIMEOUT", category: .connection)

        case .reconnectionFailed:
            ErrorCode(code: "\(errorCodePrefix)_RECONNECTION_FAILED", category: .connection)

        // Protocol Errors
        case .invalidProxy:
            ErrorCode(code: "\(errorCodePrefix)_INVALID_PROXY", category: .protocol)

        case .invalidMessage:
            ErrorCode(code: "\(errorCodePrefix)_INVALID_MESSAGE", category: .protocol)

        case .invalidInterface:
            ErrorCode(code: "\(errorCodePrefix)_INVALID_INTERFACE", category: .protocol)

        case .protocolMismatch:
            ErrorCode(code: "\(errorCodePrefix)_PROTOCOL_MISMATCH", category: .protocol)

        // Security Errors
        case .securityViolation:
            ErrorCode(code: "\(errorCodePrefix)_SECURITY_VIOLATION", category: .security)

        case .invalidEntitlements:
            ErrorCode(code: "\(errorCodePrefix)_INVALID_ENTITLEMENTS", category: .security)

        case .auditSessionInvalid:
            ErrorCode(code: "\(errorCodePrefix)_AUDIT_SESSION_INVALID", category: .security)

        case .sandboxViolation:
            ErrorCode(code: "\(errorCodePrefix)_SANDBOX_VIOLATION", category: .security)

        // System Errors
        case .systemResource:
            ErrorCode(code: "\(errorCodePrefix)_SYSTEM_RESOURCE", category: .system)

        case .memoryPressure:
            ErrorCode(code: "\(errorCodePrefix)_MEMORY_PRESSURE", category: .system)

        case .processLimit:
            ErrorCode(code: "\(errorCodePrefix)_PROCESS_LIMIT", category: .system)

        // Operation Errors
        case .operationCancelled:
            ErrorCode(code: "\(errorCodePrefix)_OPERATION_CANCELLED", category: .operation)

        case .operationTimeout:
            ErrorCode(code: "\(errorCodePrefix)_OPERATION_TIMEOUT", category: .operation)

        case .operationFailed:
            ErrorCode(code: "\(errorCodePrefix)_OPERATION_FAILED", category: .operation)
        }
    }

    // MARK: - Connection Error Helpers

    /// Get failure reason for connection error
    /// - Parameter error: XPC error
    /// - Returns: Detailed failure reason
    public static func getConnectionFailureReason(_ error: XPCError) -> String {
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

    // MARK: - Protocol Error Helpers

    /// Get failure reason for protocol error
    /// - Parameter error: XPC error
    /// - Returns: Detailed failure reason
    public static func getProtocolFailureReason(_ error: XPCError) -> String {
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

    /// Get help anchor for protocol error
    /// - Parameter error: XPC error
    /// - Returns: Help documentation anchor
    public static func getProtocolHelpAnchor(_ error: XPCError) -> String {
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

    /// Get failure reason for security error
    /// - Parameter error: XPC error
    /// - Returns: Detailed failure reason
    public static func getSecurityFailureReason(_ error: XPCError) -> String {
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

    /// Get recovery suggestion for security error
    /// - Parameter error: XPC error
    /// - Returns: Recovery suggestion
    public static func getSecurityRecoverySuggestion(_ error: XPCError) -> String {
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

    // MARK: - System Error Helpers

    /// Get failure reason for system error
    /// - Parameter error: XPC error
    /// - Returns: Detailed failure reason
    public static func getSystemFailureReason(_ error: XPCError) -> String {
        switch error {
        case .systemResource:
            "System resource constraints encountered"

        case .memoryPressure:
            "System is under memory pressure"

        case .processLimit:
            "Process limit has been reached"

        default:
            "Unknown system error occurred"
        }
    }

    // MARK: - Metadata Helpers

    /// Get metadata for error logging
    /// - Parameter error: XPC error
    /// - Returns: Logger metadata
    public static func getErrorMetadata(_ error: XPCError) -> Logger.Metadata {
        let errorCode = getErrorCode(error)

        return [
            "error_code": .string(errorCode.code),
            "error_domain": .string(errorCode.domain),
            "error_category": .string(errorCode.category.rawValue),
            "error_severity": .string(error.severity.rawValue),
            "error_description": .string(error.errorDescription ?? "Unknown"),
            "error_reason": .string(error.failureReason ?? "Unknown"),
            "error_recovery": .string(error.recoverySuggestion ?? "Unknown"),
            "error_help": .string(error.helpAnchor ?? "Unknown")
        ]
    }
}
