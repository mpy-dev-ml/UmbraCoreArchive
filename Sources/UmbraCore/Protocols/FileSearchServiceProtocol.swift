import Foundation

// MARK: - FileSearchServiceProtocol

/// Protocol for searching files across backups
public protocol FileSearchServiceProtocol: Sendable {
    /// Search for a file across all snapshots in a repository
    /// - Parameters:
    ///   - pattern: Search pattern (supports glob patterns)
    ///   - repository: Repository to search in
    /// - Returns: Array of file matches with their snapshot information
    func searchFile(
        pattern: String,
        in repository: Repository
    ) async throws -> [FileMatch]

    /// Get all versions of a specific file
    /// - Parameters:
    ///   - path: Full path of the file
    ///   - repository: Repository to search in
    /// - Returns: Array of file versions with their snapshot information
    func getFileVersions(
        path: String,
        in repository: Repository
    ) async throws -> [FileVersion]
}

// MARK: - FileMatch

/// Represents a matched file in a backup
public struct FileMatch: Identifiable, Hashable {
    // MARK: Lifecycle

    public init(
        id: UUID = UUID(),
        path: String,
        size: UInt64,
        modTime: Date,
        snapshot: ResticSnapshot
    ) {
        self.id = id
        self.path = path
        self.size = size
        self.modTime = modTime
        self.snapshot = snapshot
    }

    // MARK: Public

    public let id: UUID
    public let path: String
    public let size: UInt64
    public let modTime: Date
    public let snapshot: ResticSnapshot
}

// MARK: - FileVersion

/// Represents a specific version of a file
public struct FileVersion: Identifiable, Hashable {
    // MARK: Lifecycle

    public init(
        id: UUID = UUID(),
        path: String,
        size: UInt64,
        modTime: Date,
        snapshot: ResticSnapshot,
        hash: String
    ) {
        self.id = id
        self.path = path
        self.size = size
        self.modTime = modTime
        self.snapshot = snapshot
        self.hash = hash
    }

    // MARK: Public

    public let id: UUID
    public let path: String
    public let size: UInt64
    public let modTime: Date
    public let snapshot: ResticSnapshot
    public let hash: String
}

// MARK: - FileSearchError

/// Errors that can occur during file search operations
public enum FileSearchError: LocalizedError {
    case invalidPattern(String)
    case searchFailed(String)
    case snapshotInaccessible
    case repositoryLocked

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case let .invalidPattern(pattern):
            "Invalid search pattern: \(pattern)"

        case let .searchFailed(reason):
            "File search failed: \(reason)"

        case .snapshotInaccessible:
            "Cannot access snapshot"

        case .repositoryLocked:
            "Repository is currently locked"
        }
    }
}
