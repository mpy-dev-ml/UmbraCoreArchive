import Foundation

/// Validator for backup operations
public struct BackupValidator {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - performanceMonitor: Performance monitor
    ///   - logger: Logger for tracking operations
    public init(
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        self.performanceMonitor = performanceMonitor
        self.logger = logger
    }

    // MARK: Public

    // MARK: - Types

    /// Validation result
    public struct ValidationResult {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            passed: Bool,
            issues: [ValidationIssue] = []
        ) {
            self.passed = passed
            self.issues = issues
        }

        // MARK: Public

        /// Whether validation passed
        public let passed: Bool

        /// Validation issues if any
        public let issues: [ValidationIssue]
    }

    /// Validation issue
    public struct ValidationIssue {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            type: IssueType,
            description: String
        ) {
            self.type = type
            self.description = description
        }

        // MARK: Public

        /// Issue type
        public let type: IssueType

        /// Issue description
        public let description: String
    }

    /// Issue type
    public enum IssueType {
        /// Configuration issue
        case configuration
        /// Source issue
        case source
        /// Storage issue
        case storage
        /// Compression issue
        case compression
        /// Encryption issue
        case encryption
        /// Verification issue
        case verification
        /// Retention issue
        case retention
        /// Custom issue
        case custom(String)
    }

    // MARK: - Public Methods

    /// Validate backup configuration
    /// - Parameter configuration: Backup configuration
    /// - Returns: Validation result
    /// - Throws: Error if validation fails
    public func validateConfiguration(
        _ configuration: BackupServiceProtocol.BackupConfiguration
    ) async throws -> ValidationResult {
        try await performanceMonitor.trackDuration(
            "backup.validate.configuration"
        ) {
            var issues: [ValidationIssue] = []

            try validateBasicConfiguration(
                configuration,
                issues: &issues
            )

            try await validateSources(
                configuration,
                issues: &issues
            )

            try await validateStorage(
                configuration,
                issues: &issues
            )

            try validateCompression(
                configuration,
                issues: &issues
            )

            try validateEncryption(
                configuration,
                issues: &issues
            )

            try validateRetention(
                configuration,
                issues: &issues
            )

            logger.info(
                """
                Backup configuration validation:
                Name: \(configuration.name)
                Issues: \(issues.count)
                """,
                config: LogConfig(
                    metadata: [
                        "name": configuration.name,
                        "issues": String(issues.count)
                    ]
                )
            )

            return ValidationResult(
                passed: issues.isEmpty,
                issues: issues
            )
        }
    }

    // MARK: Private

    /// Logger for tracking operations
    private let logger: LoggerProtocol

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    // MARK: - Private Methods

    /// Validate basic configuration
    private func validateBasicConfiguration(
        _ configuration: BackupServiceProtocol.BackupConfiguration,
        issues: inout [ValidationIssue]
    ) throws {
        if configuration.name.isEmpty {
            issues.append(
                ValidationIssue(
                    type: .configuration,
                    description: "Name cannot be empty"
                )
            )
        }

        if configuration.sourcePaths.isEmpty {
            issues.append(
                ValidationIssue(
                    type: .source,
                    description: "Source paths cannot be empty"
                )
            )
        }

        if configuration.storageLocations.isEmpty {
            issues.append(
                ValidationIssue(
                    type: .storage,
                    description: "Storage locations cannot be empty"
                )
            )
        }
    }

    /// Validate sources
    private func validateSources(
        _ configuration: BackupServiceProtocol.BackupConfiguration,
        issues: inout [ValidationIssue]
    ) async throws {
        for source in configuration.sourcePaths {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(
                atPath: source.path,
                isDirectory: &isDirectory
            ) else {
                issues.append(
                    ValidationIssue(
                        type: .source,
                        description: "Source not found: \(source.path)"
                    )
                )
                continue
            }

            guard FileManager.default.isReadableFile(
                atPath: source.path
            ) else {
                issues.append(
                    ValidationIssue(
                        type: .source,
                        description: "Source not readable: \(source.path)"
                    )
                )
                continue
            }
        }
    }

    /// Validate storage
    private func validateStorage(
        _ configuration: BackupServiceProtocol.BackupConfiguration,
        issues: inout [ValidationIssue]
    ) async throws {
        for storage in configuration.storageLocations {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(
                atPath: storage.url.path,
                isDirectory: &isDirectory
            ) else {
                issues.append(
                    ValidationIssue(
                        type: .storage,
                        description: "Storage not found: \(storage.url.path)"
                    )
                )
                continue
            }

            guard FileManager.default.isWritableFile(
                atPath: storage.url.path
            ) else {
                issues.append(
                    ValidationIssue(
                        type: .storage,
                        description: "Storage not writable: \(storage.url.path)"
                    )
                )
                continue
            }

            if let quota = storage.quota {
                let attributes = try FileManager.default.attributesOfFileSystem(
                    forPath: storage.url.path
                )
                if let freeSize = attributes[.systemFreeSize] as? Int64,
                   freeSize < quota {
                    issues.append(
                        ValidationIssue(
                            type: .storage,
                            description: """
                            Storage quota exceeds available space: \
                            \(storage.url.path)
                            """
                        )
                    )
                }
            }
        }
    }

    /// Validate compression
    private func validateCompression(
        _ configuration: BackupServiceProtocol.BackupConfiguration,
        issues: inout [ValidationIssue]
    ) throws {
        switch configuration.compressionType {
        case .none:
            break
        case .zip,
             .gzip:
            break

        case .lzma:
            guard CompressionManager.shared.isLZMAAvailable else {
                issues.append(
                    ValidationIssue(
                        type: .compression,
                        description: "LZMA compression not available"
                    )
                )
                return
            }
        }
    }

    /// Validate encryption
    private func validateEncryption(
        _ configuration: BackupServiceProtocol.BackupConfiguration,
        issues: inout [ValidationIssue]
    ) throws {
        switch configuration.encryptionType {
        case .none:
            break

        case .aes256:
            guard EncryptionManager.shared.isAESAvailable else {
                issues.append(
                    ValidationIssue(
                        type: .encryption,
                        description: "AES-256 encryption not available"
                    )
                )
                return
            }

        case .chacha20:
            guard EncryptionManager.shared.isChaCha20Available else {
                issues.append(
                    ValidationIssue(
                        type: .encryption,
                        description: "ChaCha20 encryption not available"
                    )
                )
                return
            }
        }
    }

    /// Validate retention
    private func validateRetention(
        _ configuration: BackupServiceProtocol.BackupConfiguration,
        issues: inout [ValidationIssue]
    ) throws {
        let policy = configuration.retentionPolicy

        if policy.maxBackups <= 0 {
            issues.append(
                ValidationIssue(
                    type: .retention,
                    description: "Maximum backups must be positive"
                )
            )
        }

        if policy.maxAgeDays <= 0 {
            issues.append(
                ValidationIssue(
                    type: .retention,
                    description: "Maximum age must be positive"
                )
            )
        }

        if policy.minRequiredBackups <= 0 {
            issues.append(
                ValidationIssue(
                    type: .retention,
                    description: "Minimum required backups must be positive"
                )
            )
        }

        if policy.minRequiredBackups > policy.maxBackups {
            issues.append(
                ValidationIssue(
                    type: .retention,
                    description: """
                    Minimum required backups cannot exceed maximum backups
                    """
                )
            )
        }
    }
}
