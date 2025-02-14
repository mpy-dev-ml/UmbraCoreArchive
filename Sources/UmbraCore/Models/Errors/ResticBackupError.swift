import Foundation

/// Represents errors that can occur during backup operations.
public enum ResticBackupError: ResticErrorProtocol {
    case invalidPath(path: String)
    case insufficientSpace(path: String, required: UInt64, available: UInt64)
    case backupInProgress(path: String)
    case backupFailed(path: String, details: String)
    case invalidConfiguration(details: String)
    case networkError(details: String)
    case timeout(path: String, duration: TimeInterval)

    // MARK: - ResticErrorProtocol

    public var command: String? {
        switch self {
        case .invalidPath(let path):
            "restic backup \(path)"

        case .insufficientSpace(let path, _, _):
            "restic backup \(path)"

        case .backupInProgress(let path):
            "restic backup \(path)"

        case .backupFailed(let path, _):
            "restic backup \(path)"

        case .invalidConfiguration, .networkError, .timeout:
            nil
        }
    }

    public var contextInfo: [String: String] {
        switch self {
        case .invalidPath(let path):
            ["path": path]

        case let .insufficientSpace(path, required, available):
            [
                "path": path,
                "required": "\(required)",
                "available": "\(available)"
            ]

        case .backupInProgress(let path):
            ["path": path]

        case let .backupFailed(path, details):
            [
                "path": path,
                "details": details
            ]

        case .invalidConfiguration(let details):
            ["details": details]

        case .networkError(let details):
            ["details": details]

        case let .timeout(path, duration):
            [
                "path": path,
                "duration": "\(duration)"
            ]
        }
    }

    public var exitCode: Int32 {
        switch self {
        case .invalidPath: 2
        case .insufficientSpace: 3
        case .backupInProgress: 4
        case .backupFailed: 5
        case .invalidConfiguration: 6
        case .networkError: 7
        case .timeout: 8
        }
    }

    public var errorType: ResticErrorType {
        switch self {
        case .invalidPath, .invalidConfiguration:
            .configuration

        case .insufficientSpace:
            .resource

        case .backupInProgress, .backupFailed:
            .operation

        case .networkError:
            .network

        case .timeout:
            .system
        }
    }

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .invalidPath(let path):
            "Invalid backup path: \(path)"

        case let .insufficientSpace(path, required, available):
            "Insufficient space for backup at \(path). Required: \(required) bytes, Available: \(available) bytes"

        case .backupInProgress(let path):
            "Backup already in progress for \(path)"

        case let .backupFailed(path, details):
            "Backup failed for \(path): \(details)"

        case .invalidConfiguration(let details):
            "Invalid backup configuration: \(details)"

        case .networkError(let details):
            "Network error during backup: \(details)"

        case let .timeout(path, duration):
            "Backup timed out for \(path) after \(duration) seconds"
        }
    }

    public var failureReason: String? {
        switch self {
        case .invalidPath:
            "The specified path does not exist or is not accessible"

        case .insufficientSpace:
            "There is not enough disk space available to complete the backup"

        case .backupInProgress:
            "Another backup operation is already running"

        case .backupFailed:
            "The backup operation encountered an error and could not complete"

        case .invalidConfiguration:
            "The backup configuration is invalid or incomplete"

        case .networkError:
            "A network error occurred while communicating with the backup server"

        case .timeout:
            "The backup operation took too long to complete"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidPath:
            "Check that the path exists and you have appropriate permissions"

        case .insufficientSpace:
            "Free up disk space or choose a different backup location"

        case .backupInProgress:
            "Wait for the current backup to complete before starting a new one"

        case .backupFailed:
            "Check the error details and try again"

        case .invalidConfiguration:
            "Review and correct your backup configuration"

        case .networkError:
            "Check your network connection and try again"

        case .timeout:
            "Consider increasing the timeout duration or breaking up the backup into smaller parts"
        }
    }
}
