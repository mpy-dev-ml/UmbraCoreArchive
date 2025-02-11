// MARK: - Operation Options

/// Options for backup operations
public struct BackupOptions: Codable {
    /// Enable compression for backup
    public let compression: Bool?
    /// Paths to exclude from backup
    public let excludes: [String]?
    /// Paths to include in backup
    public let includes: [String]?
    /// Tags to apply to backup
    public let tags: [String]?

    public init(
        compression: Bool? = nil,
        excludes: [String]? = nil,
        includes: [String]? = nil,
        tags: [String]? = nil
    ) {
        self.compression = compression
        self.excludes = excludes
        self.includes = includes
        self.tags = tags
    }
}

/// Options for restore operations
public struct RestoreOptions: Codable {
    /// Include deleted files in restore
    public let includeDeleted: Bool?
    /// Overwrite existing files
    public let overwrite: Bool?
    /// Preserve original permissions
    public let preservePermissions: Bool?
    /// Verify restored files
    public let verify: Bool?

    public init(
        includeDeleted: Bool? = nil,
        overwrite: Bool? = nil,
        preservePermissions: Bool? = nil,
        verify: Bool? = nil
    ) {
        self.includeDeleted = includeDeleted
        self.overwrite = overwrite
        self.preservePermissions = preservePermissions
        self.verify = verify
    }
}

// MARK: - ResticXPCService Operations

extension ResticXPCService {
    /// Perform a backup operation
    /// - Parameters:
    ///   - source: Source path to backup
    ///   - destination: Destination path for backup
    ///   - options: Backup configuration options
    /// - Returns: True if backup succeeded
    /// - Throws: ResticXPCError if operation fails
    func performBackupOperation(
        source: String,
        destination: String,
        options: BackupOptions
    ) throws -> Bool {
        // Convert options to dictionary for legacy support
        let optionsDict = try JSONSerialization.jsonObject(
            with: JSONEncoder().encode(options)
        ) as? [String: Any] ?? [:]

        return try executeBackup(
            from: source,
            to: destination,
            with: optionsDict
        )
    }

    /// Perform a restore operation
    /// - Parameters:
    ///   - source: Source path to restore from
    ///   - destination: Destination path for restored files
    ///   - snapshot: Snapshot ID to restore
    ///   - options: Restore configuration options
    /// - Returns: True if restore succeeded
    /// - Throws: ResticXPCError if operation fails
    func performRestoreOperation(
        source: String,
        destination: String,
        snapshot: String,
        options: RestoreOptions
    ) throws -> Bool {
        // Convert options to dictionary for legacy support
        let optionsDict = try JSONSerialization.jsonObject(
            with: JSONEncoder().encode(options)
        ) as? [String: Any] ?? [:]

        return try executeRestore(
            from: source,
            to: destination,
            snapshot: snapshot,
            with: optionsDict
        )
    }

    // MARK: - Private Methods

    private func executeBackup(
        from source: String,
        to destination: String,
        with options: [String: Any]
    ) throws -> Bool {
        guard fileManager.fileExists(atPath: source) else {
            throw ResticXPCError.sourceNotFound
        }

        let operation = BackupOperation(
            source: source,
            destination: destination,
            options: options
        )

        return try operationQueue.sync {
            try operation.execute()
        }
    }

    private func executeRestore(
        from source: String,
        to destination: String,
        snapshot: String,
        with options: [String: Any]
    ) throws -> Bool {
        guard fileManager.fileExists(atPath: source) else {
            throw ResticXPCError.sourceNotFound
        }

        let operation = RestoreOperation(
            source: source,
            destination: destination,
            snapshot: snapshot,
            options: options
        )

        return try operationQueue.sync {
            try operation.execute()
        }
    }
}
