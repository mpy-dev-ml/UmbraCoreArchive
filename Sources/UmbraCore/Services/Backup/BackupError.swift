import Foundation

/// Errors that can occur during backup operations
public enum BackupError: LocalizedError {
    /// Invalid configuration
    case invalidConfiguration(String)
    /// Source not found
    case sourceNotFound(String)
    /// Storage not found
    case storageNotFound(String)
    /// Storage full
    case storageFull(String)
    /// Storage access denied
    case storageAccessDenied(String)
    /// Compression failed
    case compressionFailed(String)
    /// Encryption failed
    case encryptionFailed(String)
    /// Verification failed
    case verificationFailed(String)
    /// Retention failed
    case retentionFailed(String)
    /// Operation failed
    case operationFailed(String)

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case let .invalidConfiguration(reason):
            "Invalid backup configuration: \(reason)"

        case let .sourceNotFound(path):
            "Backup source not found: \(path)"

        case let .storageNotFound(location):
            "Backup storage not found: \(location)"

        case let .storageFull(location):
            "Backup storage full: \(location)"

        case let .storageAccessDenied(location):
            "Backup storage access denied: \(location)"

        case let .compressionFailed(reason):
            "Backup compression failed: \(reason)"

        case let .encryptionFailed(reason):
            "Backup encryption failed: \(reason)"

        case let .verificationFailed(reason):
            "Backup verification failed: \(reason)"

        case let .retentionFailed(reason):
            "Backup retention failed: \(reason)"

        case let .operationFailed(reason):
            "Backup operation failed: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidConfiguration:
            "Check configuration settings"

        case .sourceNotFound:
            "Verify source path exists"

        case .storageNotFound:
            "Verify storage location exists"

        case .storageFull:
            "Free up storage space"

        case .storageAccessDenied:
            "Check storage permissions"

        case .compressionFailed:
            "Check compression settings"

        case .encryptionFailed:
            "Check encryption settings"

        case .verificationFailed:
            "Try verifying backup again"

        case .retentionFailed:
            "Check retention policy"

        case .operationFailed:
            "Try the operation again"
        }
    }

    public var helpAnchor: String? {
        switch self {
        case .invalidConfiguration:
            "backup_configuration"

        case .sourceNotFound:
            "backup_sources"

        case .storageNotFound:
            "backup_storage"

        case .storageFull:
            "storage_management"

        case .storageAccessDenied:
            "storage_permissions"

        case .compressionFailed:
            "backup_compression"

        case .encryptionFailed:
            "backup_encryption"

        case .verificationFailed:
            "backup_verification"

        case .retentionFailed:
            "backup_retention"

        case .operationFailed:
            "backup_troubleshooting"
        }
    }
}
