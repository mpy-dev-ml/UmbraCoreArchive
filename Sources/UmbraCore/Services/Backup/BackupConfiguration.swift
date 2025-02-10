//
// BackupConfiguration.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Configuration for backup operations
public struct BackupConfiguration: Codable {
    // MARK: - Types

    /// Backup type
    public enum BackupType: String, Codable {
        /// Full backup
        case full
        /// Incremental backup
        case incremental
        /// Differential backup
        case differential
    }

    /// Compression type
    public enum CompressionType: String, Codable {
        /// No compression
        case none
        /// ZIP compression
        case zip
        /// GZIP compression
        case gzip
        /// LZMA compression
        case lzma
    }

    /// Encryption type
    public enum EncryptionType: String, Codable {
        /// No encryption
        case none
        /// AES-256 encryption
        case aes256
        /// ChaCha20 encryption
        case chacha20
    }

    /// Schedule type
    public enum ScheduleType: String, Codable {
        /// Manual schedule
        case manual
        /// Hourly schedule
        case hourly
        /// Daily schedule
        case daily
        /// Weekly schedule
        case weekly
        /// Monthly schedule
        case monthly
        /// Custom schedule
        case custom
    }

    /// Retention policy
    public struct RetentionPolicy: Codable {
        /// Maximum number of backups
        public let maxBackups: Int
        /// Maximum age in days
        public let maxAgeDays: Int
        /// Minimum required backups
        public let minRequiredBackups: Int

        /// Initialize with values
        public init(
            maxBackups: Int = 10,
            maxAgeDays: Int = 30,
            minRequiredBackups: Int = 3
        ) {
            self.maxBackups = maxBackups
            self.maxAgeDays = maxAgeDays
            self.minRequiredBackups = minRequiredBackups
        }
    }

    /// Storage location
    public struct StorageLocation: Codable {
        /// Location URL
        public let url: URL
        /// Access credentials
        public let credentials: Credentials?
        /// Storage quota in bytes
        public let quota: Int64?

        /// Initialize with values
        public init(
            url: URL,
            credentials: Credentials? = nil,
            quota: Int64? = nil
        ) {
            self.url = url
            self.credentials = credentials
            self.quota = quota
        }
    }

    /// Access credentials
    public struct Credentials: Codable {
        /// Username if any
        public let username: String?
        /// Password if any
        public let password: String?
        /// Access token if any
        public let accessToken: String?

        /// Initialize with values
        public init(
            username: String? = nil,
            password: String? = nil,
            accessToken: String? = nil
        ) {
            self.username = username
            self.password = password
            self.accessToken = accessToken
        }
    }

    // MARK: - Properties

    /// Configuration identifier
    public let id: UUID

    /// Configuration name
    public let name: String

    /// Backup type
    public let backupType: BackupType

    /// Compression type
    public let compressionType: CompressionType

    /// Encryption type
    public let encryptionType: EncryptionType

    /// Schedule type
    public let scheduleType: ScheduleType

    /// Source paths
    public let sourcePaths: [URL]

    /// Exclusion patterns
    public let exclusionPatterns: [String]

    /// Storage locations
    public let storageLocations: [StorageLocation]

    /// Retention policy
    public let retentionPolicy: RetentionPolicy

    /// Whether verification is enabled
    public let verificationEnabled: Bool

    /// Whether notifications are enabled
    public let notificationsEnabled: Bool

    /// Custom metadata
    public let metadata: [String: String]

    // MARK: - Initialization

    /// Initialize with values
    /// - Parameters:
    ///   - id: Configuration identifier
    ///   - name: Configuration name
    ///   - backupType: Backup type
    ///   - compressionType: Compression type
    ///   - encryptionType: Encryption type
    ///   - scheduleType: Schedule type
    ///   - sourcePaths: Source paths
    ///   - exclusionPatterns: Exclusion patterns
    ///   - storageLocations: Storage locations
    ///   - retentionPolicy: Retention policy
    ///   - verificationEnabled: Whether verification is enabled
    ///   - notificationsEnabled: Whether notifications are enabled
    ///   - metadata: Custom metadata
    public init(
        id: UUID = UUID(),
        name: String,
        backupType: BackupType = .full,
        compressionType: CompressionType = .zip,
        encryptionType: EncryptionType = .none,
        scheduleType: ScheduleType = .manual,
        sourcePaths: [URL],
        exclusionPatterns: [String] = [],
        storageLocations: [StorageLocation],
        retentionPolicy: RetentionPolicy = RetentionPolicy(),
        verificationEnabled: Bool = true,
        notificationsEnabled: Bool = true,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.backupType = backupType
        self.compressionType = compressionType
        self.encryptionType = encryptionType
        self.scheduleType = scheduleType
        self.sourcePaths = sourcePaths
        self.exclusionPatterns = exclusionPatterns
        self.storageLocations = storageLocations
        self.retentionPolicy = retentionPolicy
        self.verificationEnabled = verificationEnabled
        self.notificationsEnabled = notificationsEnabled
        self.metadata = metadata
    }

    // MARK: - Public Methods

    /// Validate configuration
    /// - Returns: Whether configuration is valid
    /// - Throws: Error if validation fails
    public func validate() throws -> Bool {
        // Validate name
        guard !name.isEmpty else {
            throw BackupError.invalidConfiguration("Name cannot be empty")
        }

        // Validate source paths
        guard !sourcePaths.isEmpty else {
            throw BackupError.invalidConfiguration("Source paths cannot be empty")
        }

        // Validate storage locations
        guard !storageLocations.isEmpty else {
            throw BackupError.invalidConfiguration(
                "Storage locations cannot be empty"
            )
        }

        // Validate retention policy
        guard retentionPolicy.maxBackups > 0,
              retentionPolicy.maxAgeDays > 0,
              retentionPolicy.minRequiredBackups > 0,
              retentionPolicy.minRequiredBackups <= retentionPolicy.maxBackups
        else {
            throw BackupError.invalidConfiguration(
                "Invalid retention policy values"
            )
        }

        return true
    }

    /// Get storage location by URL
    /// - Parameter url: Location URL
    /// - Returns: Storage location if found
    public func getStorageLocation(
        for url: URL
    ) -> StorageLocation? {
        return storageLocations.first { $0.url == url }
    }

    /// Check if path is excluded
    /// - Parameter path: Path to check
    /// - Returns: Whether path is excluded
    public func isPathExcluded(_ path: String) -> Bool {
        return exclusionPatterns.contains { pattern in
            path.range(
                of: pattern,
                options: [.regularExpression]
            ) != nil
        }
    }
}
