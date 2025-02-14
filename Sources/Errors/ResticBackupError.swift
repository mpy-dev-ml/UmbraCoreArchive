@preconcurrency import Foundation

/// Error type for Restic backup operations
public final class ResticBackupError: Error, @unchecked Sendable {
    // MARK: - Error Types

    /// Types of backup errors
    public enum ErrorType: Int {
        case invalidPath
        case repositoryNotFound
        case backupFailed
        case snapshotFailed
        case restoreFailed
        case cleanupFailed
        case pruneError
        case networkError
        case permissionDenied
    }

    // MARK: - Properties

    /// The specific type of error that occurred
    public let errorType: ErrorType

    /// Additional context about the error
    public let context: String?

    /// The underlying error if any
    public let underlyingError: Error?

    // MARK: - Error Properties

    override public var domain: String {
        "com.umbracore.restic.backup"
    }

    override public var code: Int {
        errorType.rawValue
    }

    override public var localizedDescription: String {
        switch errorType {
        case .invalidPath:
            "Invalid backup path specified"

        case .repositoryNotFound:
            "Restic repository not found"

        case .backupFailed:
            "Backup operation failed"

        case .snapshotFailed:
            "Snapshot operation failed"

        case .restoreFailed:
            "Restore operation failed"

        case .cleanupFailed:
            "Cleanup operation failed"

        case .pruneError:
            "Repository prune operation failed"

        case .networkError:
            "Network error during backup operation"

        case .permissionDenied:
            "Permission denied for backup operation"
        }
    }

    override public var localizedFailureReason: String? {
        context
    }

    override public var underlyingErrors: [Error] {
        if let error: () -> Void = underlyingError {
            return [error]
        }
        return []
    }

    // MARK: - Initialization

    /// Initialize a backup error
    /// - Parameters:
    ///   - type: Type of error
    ///   - context: Additional context
    ///   - underlyingError: Underlying error if any
    public init(
        type: ErrorType,
        context: String? = nil,
        underlyingError: Error? = nil
    ) {
        errorType = type
        self.context = context
        self.underlyingError = underlyingError
        super.init(domain: "com.umbracore.restic.backup", code: type.rawValue)
    }

    required init?(coder: NSCoder) {
        guard let errorType = ErrorType(rawValue: coder.decodeInteger(forKey: "errorType")) else {
            return nil
        }
        self.errorType = errorType
        context = coder.decodeObject(forKey: "context") as? String
        underlyingError = coder.decodeObject(forKey: "underlyingError") as? Error
        super.init(coder: coder)
    }

    override public func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(errorType.rawValue, forKey: "errorType")
        coder.encode(context, forKey: "context")
        if let error: () -> Void = underlyingError as? Error {
            coder.encode(error, forKey: "underlyingError")
        }
    }
}
