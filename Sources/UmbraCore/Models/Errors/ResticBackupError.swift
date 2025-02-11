import Foundation

/// Represents errors that can occur during backup operations.
public enum ResticBackupError: ResticErrorProtocol {
    case backupFailed(String)
    case backupCancelled(String)
    case backupInProgress(String)
    case backupNotFound(String)
    case backupCorrupted(String)

    // MARK: Public

    public var errorDescription: String {
        switch self {
        case let .backupFailed(path):
            "Backup failed for path: \(path)"
        case let .backupCancelled(path):
            "Backup cancelled for path: \(path)"
        case let .backupInProgress(path):
            "Backup already in progress for path: \(path)"
        case let .backupNotFound(path):
            "Backup not found for path: \(path)"
        case let .backupCorrupted(path):
            "Backup is corrupted for path: \(path)"
        }
    }

    public var failureReason: String {
        switch self {
        case let .backupFailed(path):
            "The backup operation failed for \(path)"
        case let .backupCancelled(path):
            "The backup operation was cancelled for \(path)"
        case let .backupInProgress(path):
            "Another backup operation is already running for \(path)"
        case let .backupNotFound(path):
            "No backup exists at \(path)"
        case let .backupCorrupted(path):
            "The backup at \(path) has integrity issues"
        }
    }

    public var recoverySuggestion: String {
        switch self {
        case let .backupFailed(path):
            """
            - Check error logs for details
            - Verify path \(path) is accessible
            - Ensure sufficient disk space
            """
        case let .backupCancelled(path):
            """
            - Try running the backup again for \(path)
            - Check if any blocking processes exist
            - Verify system resources are available
            """
        case let .backupInProgress(path):
            """
            - Wait for the current backup to complete
            - Check backup status for \(path)
            - Cancel existing backup if necessary
            """
        case let .backupNotFound(path):
            """
            - Verify the backup path \(path)
            - Check if backup was deleted
            - Create a new backup if needed
            """
        case let .backupCorrupted(path):
            """
            - Run integrity check on \(path)
            - Try to repair the backup
            - Create a new backup if needed
            """
        }
    }

    public var command: String? {
        switch self {
        case let .backupFailed(path),
             let .backupCancelled(path),
             let .backupInProgress(path),
             let .backupNotFound(path),
             let .backupCorrupted(path):
            Thread.callStackSymbols.first
        }
    }
}
