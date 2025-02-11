/// Represents errors that can occur during repository operations.
public enum ResticRepositoryError: ResticErrorProtocol {
    case repositoryNotFound(String)
    case repositoryLocked(String)
    case repositoryCorrupted(String)
    case repositoryInUse(String)
    case repositoryInvalidConfig(String)

    // MARK: Public

    public var errorDescription: String {
        switch self {
        case let .repositoryNotFound(path):
            "Repository not found at path: \(path)"
        case let .repositoryLocked(path):
            "Repository is locked at path: \(path)"
        case let .repositoryCorrupted(path):
            "Repository is corrupted at path: \(path)"
        case let .repositoryInUse(path):
            "Repository is in use at path: \(path)"
        case let .repositoryInvalidConfig(path):
            "Invalid repository configuration at path: \(path)"
        }
    }

    public var failureReason: String {
        switch self {
        case let .repositoryNotFound(path):
            "The repository at \(path) does not exist or is not accessible"
        case let .repositoryLocked(path):
            "The repository at \(path) is currently locked by another process"
        case let .repositoryCorrupted(path):
            "The repository at \(path) has integrity issues"
        case let .repositoryInUse(path):
            "The repository at \(path) is being used by another process"
        case let .repositoryInvalidConfig(path):
            "The repository configuration at \(path) is invalid or corrupted"
        }
    }

    public var recoverySuggestion: String {
        switch self {
        case .repositoryNotFound:
            """
            - Verify repository path exists
            - Check repository permissions
            - Create repository if needed
            """
        case .repositoryLocked:
            """
            - Wait for lock to be released
            - Check locking process
            - Break lock if necessary
            """
        case .repositoryCorrupted:
            """
            - Run repository check
            - Try repository repair
            - Restore from backup
            """
        case .repositoryInUse:
            """
            - Wait for other process
            - Check process status
            - Force unlock if needed
            """
        case .repositoryInvalidConfig:
            """
            - Check config format
            - Verify config values
            - Reset config if needed
            """
        }
    }

    public var command: String? {
        switch self {
        case let .repositoryNotFound(path),
             let .repositoryLocked(path),
             let .repositoryCorrupted(path),
             let .repositoryInUse(path),
             let .repositoryInvalidConfig(path):
            Thread.callStackSymbols.first
        }
    }
}
