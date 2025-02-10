/// Represents errors that can occur during repository operations.
public enum ResticRepositoryError: ResticErrorProtocol {
    case repositoryNotFound(String)
    case repositoryLocked(String)
    case repositoryCorrupted(String)
    case repositoryInUse(String)
    case repositoryInvalidConfig(String)

    public var errorDescription: String {
        switch self {
        case .repositoryNotFound(let path):
            return "Repository not found at path: \(path)"
        case .repositoryLocked(let path):
            return "Repository is locked at path: \(path)"
        case .repositoryCorrupted(let path):
            return "Repository is corrupted at path: \(path)"
        case .repositoryInUse(let path):
            return "Repository is in use at path: \(path)"
        case .repositoryInvalidConfig(let path):
            return "Invalid repository configuration at path: \(path)"
        }
    }

    public var failureReason: String {
        switch self {
        case .repositoryNotFound(let path):
            return "The repository at \(path) does not exist or is not accessible"
        case .repositoryLocked(let path):
            return "The repository at \(path) is currently locked by another process"
        case .repositoryCorrupted(let path):
            return "The repository at \(path) has integrity issues"
        case .repositoryInUse(let path):
            return "The repository at \(path) is being used by another process"
        case .repositoryInvalidConfig(let path):
            return "The repository configuration at \(path) is invalid or corrupted"
        }
    }

    public var recoverySuggestion: String {
        switch self {
        case .repositoryNotFound:
            return """
            - Verify repository path exists
            - Check repository permissions
            - Create repository if needed
            """
        case .repositoryLocked:
            return """
            - Wait for lock to be released
            - Check locking process
            - Break lock if necessary
            """
        case .repositoryCorrupted:
            return """
            - Run repository check
            - Try repository repair
            - Restore from backup
            """
        case .repositoryInUse:
            return """
            - Wait for other process
            - Check process status
            - Force unlock if needed
            """
        case .repositoryInvalidConfig:
            return """
            - Check config format
            - Verify config values
            - Reset config if needed
            """
        }
    }

    public var command: String? {
        switch self {
        case .repositoryNotFound(let path),
             .repositoryLocked(let path),
             .repositoryCorrupted(let path),
             .repositoryInUse(let path),
             .repositoryInvalidConfig(let path):
            return Thread.callStackSymbols.first
        }
    }
}
