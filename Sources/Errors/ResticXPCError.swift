import Foundation

// MARK: - ResticXPCErrorDomain

/// Error domain for Restic XPC errors
@objc
public class ResticXPCErrorDomain: NSObject {
    @objc public static let name = "dev.mpy.UmbraCore.ResticXPCError"
}

// MARK: - ResticXPCErrorCode

/// Error codes for Restic XPC errors
@objc
public enum ResticXPCErrorCode: Int {
    case serviceUnavailable = 1_000
    case connectionFailed = 1_001
    case executionFailed = 1_002
    case invalidResponse = 1_003
    case timeout = 1_004
    case bookmarkInvalid = 1_005
    case accessDenied = 1_006
    case resourceNotFound = 1_007
    case versionMismatch = 1_008
    case internalError = 1_009
    case invalidArguments = 1_010
    case missingEnvironment = 1_011
    case unsafeArguments = 1_012
    case resourceUnavailable = 1_013
}

// MARK: - ResticXPCError

/// Class representing errors that can occur during Restic XPC service operations
@objc
public class ResticXPCError: NSError {
    // MARK: Lifecycle

    @objc
    private init(code: ResticXPCErrorCode, message: String) {
        super.init(
            domain: ResticXPCErrorDomain.name,
            code: code.rawValue,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }

    @objc
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: Public

    /// Create a service unavailable error
    @objc
    public static func serviceUnavailable(_ message: String) -> ResticXPCError {
        ResticXPCError(
            code: .serviceUnavailable,
            message: message
        )
    }

    /// Create a connection failed error
    @objc
    public static func connectionFailed(_ message: String) -> ResticXPCError {
        ResticXPCError(
            code: .connectionFailed,
            message: message
        )
    }

    /// Create an execution failed error
    @objc
    public static func executionFailed(_ message: String) -> ResticXPCError {
        ResticXPCError(
            code: .executionFailed,
            message: message
        )
    }

    /// Create an invalid response error
    @objc
    public static func invalidResponse(_ message: String) -> ResticXPCError {
        ResticXPCError(
            code: .invalidResponse,
            message: message
        )
    }

    /// Create a timeout error
    @objc
    public static func timeout(_ message: String) -> ResticXPCError {
        ResticXPCError(
            code: .timeout,
            message: message
        )
    }

    /// Create a bookmark invalid error
    @objc
    public static func bookmarkInvalid(_ message: String) -> ResticXPCError {
        ResticXPCError(
            code: .bookmarkInvalid,
            message: message
        )
    }

    /// Create an access denied error
    @objc
    public static func accessDenied(_ message: String) -> ResticXPCError {
        ResticXPCError(
            code: .accessDenied,
            message: message
        )
    }

    /// Create a resource not found error
    @objc
    public static func resourceNotFound(_ message: String) -> ResticXPCError {
        ResticXPCError(
            code: .resourceNotFound,
            message: message
        )
    }

    /// Create a version mismatch error
    @objc
    public static func versionMismatch(_ message: String) -> ResticXPCError {
        ResticXPCError(
            code: .versionMismatch,
            message: message
        )
    }

    /// Create an internal error
    @objc
    public static func internalError(_ message: String) -> ResticXPCError {
        ResticXPCError(
            code: .internalError,
            message: message
        )
    }

    /// Create an invalid arguments error
    @objc
    public static func invalidArguments(_ message: String) -> ResticXPCError {
        ResticXPCError(
            code: .invalidArguments,
            message: message
        )
    }

    /// Create a missing environment error
    @objc
    public static func missingEnvironment(_ message: String) -> ResticXPCError {
        ResticXPCError(
            code: .missingEnvironment,
            message: message
        )
    }

    /// Create an unsafe arguments error
    @objc
    public static func unsafeArguments(_ message: String) -> ResticXPCError {
        ResticXPCError(
            code: .unsafeArguments,
            message: message
        )
    }

    /// Create a resource unavailable error
    @objc
    public static func resourceUnavailable(_ message: String) -> ResticXPCError {
        ResticXPCError(
            code: .resourceUnavailable,
            message: message
        )
    }
}
