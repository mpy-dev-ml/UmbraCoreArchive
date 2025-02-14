import Foundation

/// Represents errors that can occur during repository operations.
public enum ResticRepositoryError: ResticErrorProtocol {
    case repositoryNotFound(path: String)
    case repositoryCorrupted(path: String, details: String)
    case repositoryLocked(path: String)
    case repositoryInUse(path: String)
    case repositoryFull(path: String, available: UInt64)
    case indexCorrupted(path: String)
    case invalidFormat(path: String, details: String)
    case incompatibleVersion(path: String, version: String)

    // MARK: - ResticErrorProtocol

    public var command: String? {
        switch self {
        case .repositoryNotFound(let path):
            "restic -r \(path) check"

        case .repositoryCorrupted(let path, _):
            "restic -r \(path) check"

        case .repositoryLocked(let path):
            "restic -r \(path) unlock"

        case .repositoryInUse(let path):
            "restic -r \(path) check"

        case .repositoryFull(let path, _):
            "restic -r \(path) check"

        case .indexCorrupted(let path):
            "restic -r \(path) rebuild-index"

        case .invalidFormat(let path, _):
            "restic -r \(path) check"

        case .incompatibleVersion(let path, _):
            "restic -r \(path) version"
        }
    }

    public var contextInfo: [String: String] {
        switch self {
        case .repositoryNotFound(let path):
            ["path": path]

        case let .repositoryCorrupted(path, details):
            [
                "path": path,
                "details": details
            ]

        case .repositoryLocked(let path):
            ["path": path]

        case .repositoryInUse(let path):
            ["path": path]

        case let .repositoryFull(path, available):
            [
                "path": path,
                "available": "\(available)"
            ]

        case .indexCorrupted(let path):
            ["path": path]

        case let .invalidFormat(path, details):
            [
                "path": path,
                "details": details
            ]

        case let .incompatibleVersion(path, version):
            [
                "path": path,
                "version": version
            ]
        }
    }

    public var exitCode: Int32 {
        switch self {
        case .repositoryNotFound: 1
        case .repositoryCorrupted: 2
        case .repositoryLocked: 3
        case .repositoryInUse: 4
        case .repositoryFull: 5
        case .indexCorrupted: 6
        case .invalidFormat: 7
        case .incompatibleVersion: 8
        }
    }

    public var errorType: ResticErrorType {
        switch self {
        case .repositoryNotFound:
            .configuration

        case .repositoryCorrupted, .indexCorrupted:
            .validation

        case .repositoryLocked, .repositoryInUse:
            .resource

        case .repositoryFull:
            .resource

        case .invalidFormat:
            .validation

        case .incompatibleVersion:
            .configuration
        }
    }

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .repositoryNotFound(let path):
            "Repository not found at \(path)"

        case let .repositoryCorrupted(path, details):
            "Repository corrupted at \(path): \(details)"

        case .repositoryLocked(let path):
            "Repository is locked at \(path)"

        case .repositoryInUse(let path):
            "Repository is in use at \(path)"

        case let .repositoryFull(path, available):
            "Repository full at \(path) (available: \(available) bytes)"

        case .indexCorrupted(let path):
            "Repository index corrupted at \(path)"

        case let .invalidFormat(path, details):
            "Invalid repository format at \(path): \(details)"

        case let .incompatibleVersion(path, version):
            "Incompatible repository version at \(path): \(version)"
        }
    }

    public var failureReason: String? {
        switch self {
        case .repositoryNotFound:
            "The repository directory does not exist or is not accessible"

        case .repositoryCorrupted:
            "The repository data is corrupted and needs repair"

        case .repositoryLocked:
            "Another process has locked the repository"

        case .repositoryInUse:
            "The repository is being accessed by another process"

        case .repositoryFull:
            "The repository has run out of storage space"

        case .indexCorrupted:
            "The repository index is corrupted and needs rebuilding"

        case .invalidFormat:
            "The repository format is invalid or unsupported"

        case .incompatibleVersion:
            "The repository version is not compatible with this version of Restic"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .repositoryNotFound:
            "Check the repository path and ensure it exists"

        case .repositoryCorrupted:
            "Run 'restic check --repair' to attempt repair"

        case .repositoryLocked:
            "Run 'restic unlock' if no other process is using the repository"

        case .repositoryInUse:
            "Wait for other processes to finish or check for stuck locks"

        case .repositoryFull:
            "Free up space or move repository to a larger storage"

        case .indexCorrupted:
            "Run 'restic rebuild-index' to rebuild the index"

        case .invalidFormat:
            "Check repository format and ensure compatibility"

        case .incompatibleVersion:
            "Update Restic to a compatible version"
        }
    }
}
