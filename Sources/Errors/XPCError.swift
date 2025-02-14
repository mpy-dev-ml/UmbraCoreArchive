@preconcurrency import Foundation
import Logging

// MARK: - XPC Error

/// Errors that can occur during XPC operations
public enum XPCError: LocalizedError, CustomDebugStringConvertible, Sendable {
    // MARK: - Error Categories

    /// Category of XPC error
    public enum Category: String, Sendable {
        case connection = "Connection Error"
        case protocolError = "Protocol Error"
        case security = "Security Error"
        case system = "System Error"
        case operation = "Operation Error"
        case lifecycle = "Lifecycle Error"
        case configuration = "Configuration Error"
    }

    /// Severity level of the error
    public enum Severity: String, Sendable {
        /// Critical errors that require immediate attention and may affect system stability
        case critical = "Critical"
        /// Serious errors that affect functionality but not system stability
        case error = "Error"
        /// Issues that should be addressed but don't affect core functionality
        case warning = "Warning"
        /// Informational messages about non-critical issues
        case info = "Info"
    }

    // MARK: - Properties

    /// The error category
    public var category: Category {
        switch self {
        case .serviceUnavailable, .notConnected, .invalidState, .timeout, .reconnectionFailed:
            return .connection
        case .invalidMessage, .invalidResponse, .messageValidation:
            return .protocolError
        case .securityViolation, .invalidEntitlements, .auditSessionInvalid, .sandboxViolation:
            return .security
        case .systemResource, .resourceLimit:
            return .system
        case .operationCancelled, .operationTimeout, .operationFailed:
            return .operation
        case .lifecycleError:
            return .lifecycle
        case .configurationError:
            return .configuration
        }
    }

    /// The severity level of the error
    public var severity: Severity {
        switch self {
        case .securityViolation, .auditSessionInvalid, .sandboxViolation:
            return .critical
        case .serviceUnavailable, .notConnected, .invalidState, .timeout,
             .reconnectionFailed, .invalidMessage, .invalidResponse,
             .messageValidation, .invalidEntitlements:
            return .error
        case .systemResource, .resourceLimit:
            return .warning
        case .operationCancelled, .operationTimeout, .operationFailed,
             .lifecycleError, .configurationError:
            return .info
        }
    }

    // MARK: - Connection Errors

    /// Service is not available or cannot be reached
    case serviceUnavailable(reason: String)

    /// Not connected to XPC service
    case notConnected(reason: String)

    /// Invalid connection state
    case invalidState(reason: String)

    /// Connection timed out
    case timeout(reason: String)

    /// Reconnection attempt failed
    case reconnectionFailed(reason: String)

    // MARK: - Protocol Errors

    /// Invalid message format or content received
    case invalidMessage(reason: String)

    /// Invalid response received
    case invalidResponse(reason: String)

    /// Message validation failed
    case messageValidation(reason: String)

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

    /// Resource limit reached
    case resourceLimit(reason: String)

    // MARK: - Operation Errors

    /// Operation cancelled
    case operationCancelled(reason: String)

    /// Operation timeout
    case operationTimeout(reason: String)

    /// Operation failed
    case operationFailed(reason: String)

    // MARK: - Lifecycle Errors

    /// Lifecycle error
    case lifecycleError(reason: String)

    // MARK: - Configuration Errors

    /// Configuration error
    case configurationError(reason: String)

    // MARK: - Helper Methods

    /// Get error metadata for logging
    public var metadata: Logger.Metadata {
        [
            "error.category": .string(category.rawValue),
            "error.severity": .string(severity.rawValue),
            "error.type": .string(String(describing: type(of: self))),
            "error.description": .string(errorDescription ?? "Unknown"),
            "error.reason": .string(failureReason ?? "Unknown"),
            "error.recovery": .string(recoverySuggestion ?? "Unknown"),
            "error.timestamp": .string(ISO8601DateFormatter().string(from: Date())),
            "error.id": .string(UUID().uuidString)
        ]
    }
}

// MARK: - LocalizedError

extension XPCError {
    public var errorDescription: String? {
        switch self {
        case let .serviceUnavailable(reason):
            "XPC service unavailable: \(reason)"
        case let .notConnected(reason):
            "XPC service not connected: \(reason)"
        case let .invalidState(reason):
            "XPC connection state invalid: \(reason)"
        case let .timeout(reason):
            "XPC connection timed out: \(reason)"
        case let .reconnectionFailed(reason):
            "XPC reconnection failed: \(reason)"
        case let .invalidMessage(reason):
            "XPC invalid message: \(reason)"
        case let .invalidResponse(reason):
            "XPC invalid response: \(reason)"
        case let .messageValidation(reason):
            "XPC message validation failed: \(reason)"
        case let .securityViolation(reason):
            "XPC security violation: \(reason)"
        case let .invalidEntitlements(reason):
            "XPC invalid entitlements: \(reason)"
        case let .auditSessionInvalid(reason):
            "XPC audit session invalid: \(reason)"
        case let .sandboxViolation(reason):
            "XPC sandbox violation: \(reason)"
        case let .systemResource(reason):
            "XPC system resource constraint: \(reason)"
        case let .resourceLimit(reason):
            "XPC resource limit reached: \(reason)"
        case let .operationCancelled(reason):
            "XPC operation cancelled: \(reason)"
        case let .operationTimeout(reason):
            "XPC operation timed out: \(reason)"
        case let .operationFailed(reason):
            "XPC operation failed: \(reason)"
        case let .lifecycleError(reason):
            "XPC lifecycle error: \(reason)"
        case let .configurationError(reason):
            "XPC configuration error: \(reason)"
        }
    }

    public var failureReason: String? {
        switch self {
        case .serviceUnavailable, .notConnected, .invalidState, .timeout, .reconnectionFailed:
            "Connection to XPC service failed"
        case .invalidMessage, .invalidResponse, .messageValidation:
            "XPC protocol error occurred"
        case .securityViolation, .invalidEntitlements, .auditSessionInvalid, .sandboxViolation:
            "Security constraint violation"
        case .systemResource, .resourceLimit:
            "System resource constraint"
        case .operationCancelled, .operationTimeout, .operationFailed:
            "Operation error occurred"
        case .lifecycleError:
            "Service lifecycle error"
        case .configurationError:
            "Service configuration error"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .serviceUnavailable, .notConnected:
            "Check if the XPC service is running and try reconnecting"
        case .invalidState:
            "Reset the connection state and try again"
        case .timeout:
            "Check network conditions and try again"
        case .reconnectionFailed:
            "Wait a moment and try reconnecting"
        case .invalidMessage, .invalidResponse, .messageValidation:
            "Check message format and content"
        case .securityViolation, .invalidEntitlements:
            "Verify security permissions and entitlements"
        case .auditSessionInvalid:
            "Check audit session validity"
        case .sandboxViolation:
            "Review sandbox permissions"
        case .systemResource:
            "Free up system resources and try again"
        case .resourceLimit:
            "Wait for resources to become available"
        case .operationCancelled:
            "Retry the operation if needed"
        case .operationTimeout:
            "Increase timeout duration or optimize operation"
        case .operationFailed:
            "Check operation parameters and try again"
        case .lifecycleError:
            "Restart the service"
        case .configurationError:
            "Check service configuration"
        }
    }

    public var helpAnchor: String? {
        "xpc-error-\(category.rawValue.lowercased().replacingOccurrences(of: " ", with: "-"))"
    }
}

// MARK: - CustomDebugStringConvertible

extension XPCError {
    public var debugDescription: String {
        """
        XPCError:
        Category: \(category.rawValue)
        Severity: \(severity.rawValue)
        Description: \(errorDescription ?? "Unknown")
        Reason: \(failureReason ?? "Unknown")
        Recovery: \(recoverySuggestion ?? "Unknown")
        """
    }
}
