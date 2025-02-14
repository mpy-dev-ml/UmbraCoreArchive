@preconcurrency import Foundation

/// Error type for Restic operations
@objc
public final class ResticError: NSObject, @unchecked Sendable {
    // MARK: - Properties

    /// Error code
    @objc public let code: Int

    /// Error message
    @objc public let message: String

    /// Additional context information
    @objc public let contextInfo: [String: Any]

    // MARK: - Initialization

    /// Initialize with error details
    /// - Parameters:
    ///   - code: Error code
    ///   - message: Error message
    ///   - contextInfo: Additional context information
    @objc
    public init(
        code: Int,
        message: String,
        contextInfo: [String: Any] = [:]
    ) {
        self.code = code
        self.message = message
        self.contextInfo = contextInfo
        super.init()
    }

    // MARK: - NSObject Override

    @objc
    override public var description: String {
        "ResticError(code: \(code), message: \(message), context: \(contextInfo))"
    }
}

// MARK: - Error Types

public extension ResticError {
    /// enum for handling code:
    enum Code: Int {
        case invalidConfiguration = 1
        case repositoryNotFound = 2
        case invalidCredentials = 3
        case snapshotCreationFailed = 4
        case snapshotRestoreFailed = 5
        case backupFailed = 6
        case timeoutError = 7
        case unknownError = 999
    }

    static func invalidConfiguration(_ message: String) -> ResticError {
        ResticError(code: Code.invalidConfiguration.rawValue, message: message)
    }

    static func repositoryNotFound(_ path: String) -> ResticError {
        ResticError(
            code: Code.repositoryNotFound.rawValue,
            message: "Repository not found at path: \(path)"
        )
    }

    static func invalidCredentials(_ message: String) -> ResticError {
        ResticError(code: Code.invalidCredentials.rawValue, message: message)
    }

    static func snapshotCreationFailed(_ message: String) -> ResticError {
        ResticError(code: Code.snapshotCreationFailed.rawValue, message: message)
    }

    static func snapshotRestoreFailed(_ message: String) -> ResticError {
        ResticError(code: Code.snapshotRestoreFailed.rawValue, message: message)
    }

    static func backupFailed(_ message: String) -> ResticError {
        ResticError(code: Code.backupFailed.rawValue, message: message)
    }

    static func timeoutError(_ message: String) -> ResticError {
        ResticError(code: Code.timeoutError.rawValue, message: message)
    }

    static func unknownError(_ message: String) -> ResticError {
        ResticError(code: Code.unknownError.rawValue, message: message)
    }
}
