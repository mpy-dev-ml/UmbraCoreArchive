import Foundation

/// Represents errors that can occur during backup operations.
public enum ResticBackupError: ResticErrorProtocol {
    case backupFailed(String)
    case backupCancelled(String)
    case backupInProgress(String)
    case backupNotFound(String)
    case backupCorrupted(String)

    public var errorDescription: String {
        switch self {
        case .backupFailed(let path):
            return "Backup failed for path: \(path)"
        case .backupCancelled(let path):
            return "Backup cancelled for path: \(path)"
        case .backupInProgress(let path):
            return "Backup already in progress for path: \(path)"
        case .backupNotFound(let path):
            return "Backup not found for path: \(path)"
        case .backupCorrupted(let path):
            return "Backup is corrupted for path: \(path)"
        }
    }

    public var failureReason: String {
        switch self {
        case .backupFailed(let path):
            return "The backup operation failed for \(path)"
        case .backupCancelled(let path):
            return "The backup operation was cancelled for \(path)"
        case .backupInProgress(let path):
            return "Another backup operation is already running for \(path)"
        case .backupNotFound(let path):
            return "No backup exists at \(path)"
        case .backupCorrupted(let path):
            return "The backup at \(path) has integrity issues"
        }
    }

    public var recoverySuggestion: String {
        switch self {
        case .backupFailed(let path):
            return """
            - Check error logs for details
            - Verify path \(path) is accessible
            - Ensure sufficient disk space
            """
        case .backupCancelled(let path):
            return """
            - Try running the backup again for \(path)
            - Check if any blocking processes exist
            - Verify system resources are available
            """
        case .backupInProgress(let path):
            return """
            - Wait for the current backup to complete
            - Check backup status for \(path)
            - Cancel existing backup if necessary
            """
        case .backupNotFound(let path):
            return """
            - Verify the backup path \(path)
            - Check if backup was deleted
            - Create a new backup if needed
            """
        case .backupCorrupted(let path):
            return """
            - Run integrity check on \(path)
            - Try to repair the backup
            - Create a new backup if needed
            """
        }
    }

    public var command: String? {
        switch self {
        case .backupFailed(let path),
             .backupCancelled(let path),
             .backupInProgress(let path),
             .backupNotFound(let path),
             .backupCorrupted(let path):
            return Thread.callStackSymbols.first
        }
    }
}
