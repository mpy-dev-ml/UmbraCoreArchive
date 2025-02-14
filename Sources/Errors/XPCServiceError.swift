@preconcurrency import Foundation
import Logging

// MARK: - XPC Service Error

/// Errors that can occur in XPC service operations
@frozen
@Error
public enum XPCServiceError: LocalizedError, CustomDebugStringConvertible, Sendable {
    // MARK: - Error Categories

    /// Category of service error
    public enum Category: String, Sendable, CaseIterable {
        case operation = "Operation Error"
        case validation = "Validation Error"
        case security = "Security Error"
        case resource = "Resource Error"
        case system = "System Error"
    }

    /// Severity level of the error
    public enum Severity: String, Sendable, CaseIterable {
        case critical = "Critical"
        case error = "Error"
        case warning = "Warning"
        case info = "Info"
    }

    // MARK: - Operation Errors

    /// Operation failed
    @ErrorCase("XPC operation failed: {reason}")
    case operationFailed(reason: String)

    /// Operation cancelled
    @ErrorCase("XPC operation cancelled: {reason}")
    case operationCancelled(reason: String)

    /// Operation timeout
    @ErrorCase("XPC operation timeout: {reason}")
    case operationTimeout(reason: String)

    /// Invalid operation type
    @ErrorCase("Invalid XPC operation type: {reason}")
    case invalidOperationType(reason: String)

    // MARK: - Validation Errors

    /// Invalid arguments
    @ErrorCase("Invalid XPC arguments: {reason}")
    case invalidArguments(reason: String)

    /// Invalid path
    @ErrorCase("Invalid XPC path: {reason}")
    case invalidPath(reason: String)

    /// Invalid environment
    @ErrorCase("Invalid XPC environment: {reason}")
    case invalidEnvironment(reason: String)

    /// Invalid bookmark
    @ErrorCase("Invalid XPC bookmark: {reason}")
    case invalidBookmark(reason: String)

    // MARK: - Security Errors

    /// Permission denied
    @ErrorCase("XPC permission denied: {reason}")
    case permissionDenied(reason: String)

    /// Invalid entitlements
    @ErrorCase("Invalid XPC entitlements: {reason}")
    case invalidEntitlements(reason: String)

    /// Security violation
    @ErrorCase("XPC security violation: {reason}")
    case securityViolation(reason: String)

    /// Sandbox violation
    @ErrorCase("XPC sandbox violation: {reason}")
    case sandboxViolation(reason: String)

    // MARK: - Resource Errors

    /// Resource not found
    @ErrorCase("XPC resource not found: {reason}")
    case resourceNotFound(reason: String)

    /// Resource busy
    @ErrorCase("XPC resource busy: {reason}")
    case resourceBusy(reason: String)

    /// Resource exhausted
    @ErrorCase("XPC resource exhausted: {reason}")
    case resourceExhausted(reason: String)

    /// Resource invalid
    @ErrorCase("Invalid XPC resource: {reason}")
    case resourceInvalid(reason: String)

    // MARK: - System Errors

    /// System error occurred
    @ErrorCase("XPC system error: {reason}")
    case systemError(reason: String)

    /// Memory pressure condition
    @ErrorCase("XPC memory pressure: {reason}")
    case memoryPressure(reason: String)

    /// Process limit reached
    @ErrorCase("XPC process limit reached: {reason}")
    case processLimit(reason: String)

    // MARK: - Error Properties

    /// Category of the error
    public var category: Category {
        switch self {
        case .operationFailed, .operationCancelled, .operationTimeout, .invalidOperationType:
            .operation

        case .invalidArguments, .invalidPath, .invalidEnvironment, .invalidBookmark:
            .validation

        case .permissionDenied, .invalidEntitlements, .securityViolation, .sandboxViolation:
            .security

        case .resourceNotFound, .resourceBusy, .resourceExhausted, .resourceInvalid:
            .resource

        case .systemError, .memoryPressure, .processLimit:
            .system
        }
    }

    /// Severity of the error
    public var severity: Severity {
        switch self {
        case .securityViolation, .sandboxViolation:
            .critical
        case .operationFailed, .invalidOperationType, .permissionDenied,
             .invalidEntitlements, .resourceNotFound, .systemError:
            .error
        case .operationTimeout, .resourceBusy, .memoryPressure, .processLimit:
            .warning
        case .operationCancelled, .invalidArguments, .invalidPath,
             .invalidEnvironment, .invalidBookmark, .resourceExhausted,
             .resourceInvalid:
            .info
        }
    }

    /// Whether the error is recoverable
    public var isRecoverable: Bool {
        switch category {
        case .operation, .validation, .resource:
            true

        case .security, .system:
            false
        }
    }

    /// Whether the error requires immediate attention
    public var requiresImmediateAttention: Bool {
        severity == .critical
    }

    // MARK: - Error Description

    public var errorDescription: String? {
        switch self {
        case let .operationFailed(reason),
             let .operationCancelled(reason),
             let .operationTimeout(reason),
             let .invalidOperationType(reason),
             let .invalidArguments(reason),
             let .invalidPath(reason),
             let .invalidEnvironment(reason),
             let .invalidBookmark(reason),
             let .permissionDenied(reason),
             let .invalidEntitlements(reason),
             let .securityViolation(reason),
             let .sandboxViolation(reason),
             let .resourceNotFound(reason),
             let .resourceBusy(reason),
             let .resourceExhausted(reason),
             let .resourceInvalid(reason),
             let .systemError(reason),
             let .memoryPressure(reason),
             let .processLimit(reason):
            reason
        }
    }

    public var failureReason: String? {
        switch category {
        case .operation:
            "Operation could not be completed successfully"

        case .validation:
            "Input validation failed"

        case .security:
            "Security requirements not met"

        case .resource:
            "Required resource unavailable"

        case .system:
            "System-level error occurred"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .operationFailed:
            "Check operation parameters and try again"

        case .operationCancelled:
            "Retry the operation if needed"

        case .operationTimeout:
            "Increase timeout duration or optimize operation"

        case .invalidOperationType:
            "Verify operation type is supported"

        case .invalidArguments:
            "Check argument format and values"

        case .invalidPath:
            "Verify path exists and is accessible"

        case .invalidEnvironment:
            "Check environment variables"

        case .invalidBookmark:
            "Recreate security-scoped bookmark"

        case .permissionDenied:
            "Request necessary permissions"

        case .invalidEntitlements:
            "Update entitlements configuration"

        case .securityViolation:
            "Review security policy requirements"

        case .sandboxViolation:
            "Check sandbox configuration"

        case .resourceNotFound:
            "Verify resource exists"

        case .resourceBusy:
            "Wait and try again"

        case .resourceExhausted:
            "Free up resources and retry"

        case .resourceInvalid:
            "Validate resource configuration"

        case .systemError:
            "Check system logs for details"

        case .memoryPressure:
            "Free up memory and retry"

        case .processLimit:
            "Terminate unnecessary processes"
        }
    }

    public var helpAnchor: String? {
        "xpc-service-error-\(category.rawValue.lowercased().replacingOccurrences(of: " ", with: "-"))"
    }

    // MARK: - Logging Support

    /// Log level for the error
    public var logLevel: Logger.Level {
        switch severity {
        case .critical:
            .critical

        case .error:
            .error

        case .warning:
            .warning

        case .info:
            .info
        }
    }

    /// Metadata for logging
    public var loggingMetadata: Logger.Metadata {
        [
            "error_category": .string(category.rawValue),
            "error_severity": .string(severity.rawValue),
            "error_description": .string(errorDescription ?? "Unknown"),
            "error_reason": .string(failureReason ?? "Unknown"),
            "error_recovery": .string(recoverySuggestion ?? "Unknown"),
            "error_recoverable": .string(String(isRecoverable)),
            "error_immediate_attention": .string(String(requiresImmediateAttention)),
        ]
    }

    // MARK: - CustomDebugStringConvertible

    public var debugDescription: String {
        """
        XPCServiceError:
          Category: \(category.rawValue)
          Severity: \(severity.rawValue)
          Type: \(String(describing: self))
          Description: \(errorDescription ?? "No description")
          Failure Reason: \(failureReason ?? "No failure reason")
          Recovery Suggestion: \(recoverySuggestion ?? "No recovery suggestion")
          Help Anchor: \(helpAnchor ?? "No help anchor")
          Recoverable: \(isRecoverable)
          Requires Immediate Attention: \(requiresImmediateAttention)
        """
    }
}
