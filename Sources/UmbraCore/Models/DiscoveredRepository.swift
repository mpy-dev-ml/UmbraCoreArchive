import Foundation

// MARK: - DiscoveredRepository

/// A discovered Restic repository in the filesystem
///
/// Represents a Restic repository found during filesystem scanning, containing
/// essential information about its location, type, and associated metadata.
@frozen
public struct DiscoveredRepository:
    Identifiable,
    Hashable,
    Sendable
{
    // MARK: - Properties

    /// Unique identifier for the repository
    public let id: UUID

    /// Location where the repository was discovered
    public let url: URL

    /// Type of repository (local, SFTP, etc.)
    public let type: RepositoryType

    /// When the repository was discovered
    public let discoveredAt: Date

    /// Whether repository verification succeeded
    public let isVerified: Bool

    /// Additional repository information
    public let metadata: RepositoryMetadata

    // MARK: - Computed Properties

    /// Formatted repository size string (e.g., "1.2 GB")
    public var formattedSize: String {
        guard let size = metadata.size else { return "Unknown" }
        return ByteCountFormatter.string(
            fromByteCount: Int64(size),
            countStyle: .binary
        )
    }

    /// Relative time description of discovery (e.g., "2 hours ago")
    public var discoveredTimeAgo: String {
        RelativeDateTimeFormatter().localizedString(
            for: discoveredAt,
            relativeTo: Date()
        )
    }

    // MARK: - Initialisation

    /// Creates a new discovered repository
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - url: Repository location
    ///   - type: Repository type
    ///   - discoveredAt: Discovery timestamp
    ///   - isVerified: Verification status
    ///   - metadata: Additional information
    public init(
        id: UUID = UUID(),
        url: URL,
        type: RepositoryType,
        discoveredAt: Date,
        isVerified: Bool,
        metadata: RepositoryMetadata
    ) {
        self.id = id
        self.url = url
        self.type = type
        self.discoveredAt = discoveredAt
        self.isVerified = isVerified
        self.metadata = metadata
    }

    // MARK: - Equatable

    public static func == (lhs: DiscoveredRepository, rhs: DiscoveredRepository) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - RepositoryMetadata

/// Additional metadata about a discovered repository
///
/// Optional metadata that may be available for a discovered repository.
/// Properties are optional as they might not be available or may be
/// expensive to calculate for all repositories.
@frozen
public struct RepositoryMetadata:
    Hashable,
    Sendable
{
    // MARK: - Properties

    /// Repository size in bytes
    public let size: UInt64?

    /// Last modification timestamp
    public let lastModified: Date?

    /// Number of snapshots
    public let snapshotCount: Int?

    // MARK: - Computed Properties

    /// Whether any metadata is available
    public var hasMetadata: Bool {
        size != nil || lastModified != nil || snapshotCount != nil
    }

    /// Formatted last modified date
    public var formattedLastModified: String? {
        guard let date = lastModified else { return nil }
        return DateFormatter.localizedString(
            from: date,
            dateStyle: .medium,
            timeStyle: .short
        )
    }

    // MARK: - Initialisation

    /// Creates new repository metadata
    /// - Parameters:
    ///   - size: Size in bytes
    ///   - lastModified: Last modified date
    ///   - snapshotCount: Number of snapshots
    public init(
        size: UInt64? = nil,
        lastModified: Date? = nil,
        snapshotCount: Int? = nil
    ) {
        self.size = size
        self.lastModified = lastModified
        self.snapshotCount = snapshotCount
    }
}
