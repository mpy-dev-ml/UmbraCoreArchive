import Foundation
import Logging

/// Validator for backup operations
@Observable
public final class BackupValidator: Sendable {
    // MARK: - Properties

    private let performanceMonitor: PerformanceMonitor
    private let logger: LoggerProtocol

    // MARK: - Types

    /// Validation result
    @Observable
    public final class ValidationResult: Sendable {
        /// Whether validation passed
        public let passed: Bool

        /// Validation issues if any
        public let issues: [ValidationIssue]

        /// Initialize with values
        public init(
            passed: Bool,
            issues: [ValidationIssue] = []
        ) {
            self.passed = passed
            self.issues = issues
        }
    }

    /// Validation issue
    @Error public struct ValidationIssue: Sendable {
        /// Issue type
        public let type: IssueType

        /// Issue description
        @ErrorDescription
        public let description: String

        /// Recovery suggestion based on issue type
        @ErrorRecoverySuggestion
        public var recoverySuggestion: String {
            switch type {
            case .configuration:
                "Review and update the backup configuration settings"

            case .source:
                "Check if the source paths exist and are accessible"

            case .storage:
                "Verify storage locations are available and have sufficient space"

            case .compression:
                "Ensure the selected compression method is supported"

            case .encryption:
                "Verify encryption requirements and key availability"

            case .verification:
                "Check verification settings and requirements"

            case .retention:
                "Review retention policy settings"

            case .custom:
                "Review the specific issue details"
            }
        }

        /// Initialize with values
        public init(
            type: IssueType,
            description: String
        ) {
            self.type = type
            self.description = description
        }
    }

    /// Issue type
    public enum IssueType: Sendable {
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

        public var description: String {
            switch self {
            case .configuration: "Configuration Issue"
            case .source: "Source Issue"
            case .storage: "Storage Issue"
            case .compression: "Compression Issue"
            case .encryption: "Encryption Issue"
            case .verification: "Verification Issue"
            case .retention: "Retention Issue"
            case let .custom(type): type
            }
        }
    }

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

    // MARK: - Public Methods

    /// Validate backup configuration
    /// - Parameter configuration: Backup configuration
    /// - Returns: Validation result
    /// - Throws: ValidationIssue if validation fails
    public func validateConfiguration(
        _ configuration: BackupConfiguration
    ) async throws -> ValidationResult {
        try await performanceMonitor.trackDuration(
            "backup.validate.configuration"
        ) {
            var issues: [ValidationIssue] = []

            // Validate basic configuration first
            try validateBasicConfiguration(configuration, issues: &issues)

            // Use async let for concurrent validation
            async let sourceValidation = validateSources(configuration, issues: &issues)
            async let storageValidation = validateStorage(configuration, issues: &issues)
            async let compressionValidation = validateCompression(configuration, issues: &issues)
            async let encryptionValidation = validateEncryption(configuration, issues: &issues)
            async let retentionValidation = validateRetention(configuration, issues: &issues)

            // Wait for all validations to complete
            try await (
                sourceValidation,
                storageValidation,
                compressionValidation,
                encryptionValidation,
                retentionValidation
            )

            logger.log(
                level: .info,
                message: """
                Backup configuration validation completed:
                Name: \(configuration.name)
                Sources: \(configuration.sourcePaths.count)
                Storage: \(configuration.storageLocations.count)
                Issues: \(issues.count)
                """
            )

            return ValidationResult(
                passed: issues.isEmpty,
                issues: issues
            )
        }
    }

    // MARK: - Private Methods

    /// Validate basic configuration
    private func validateBasicConfiguration(
        _ configuration: BackupConfiguration,
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
        _ configuration: BackupConfiguration,
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
        _ configuration: BackupConfiguration,
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
        _ configuration: BackupConfiguration,
        issues: inout [ValidationIssue]
    ) async throws {
        switch configuration.compressionType {
        case .none, .zip, .gzip:
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
        _ configuration: BackupConfiguration,
        issues: inout [ValidationIssue]
    ) async throws {
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
        _ configuration: BackupConfiguration,
        issues: inout [ValidationIssue]
    ) async throws {
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
