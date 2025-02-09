//
// BackupServiceProtocol.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Protocol defining the core backup service functionality
public protocol BackupServiceProtocol: Sendable {
    /// The delegate to receive backup operation updates
    var delegate: BackupServiceDelegate? { get set }
    
    // Core backup operations
    
    /// Starts a backup operation with the specified configuration
    /// - Parameter configuration: The configuration for the backup operation
    /// - Returns: A boolean indicating whether the backup was started successfully
    func startBackup(with configuration: BackupConfiguration) async throws -> Bool
    
    /// Stops the current backup operation
    /// - Returns: A boolean indicating whether the backup was stopped successfully
    func stopBackup() async throws -> Bool
    
    /// Pauses the current backup operation
    /// - Returns: A boolean indicating whether the backup was paused successfully
    func pauseBackup() async throws -> Bool
    
    /// Resumes a paused backup operation
    /// - Returns: A boolean indicating whether the backup was resumed successfully
    func resumeBackup() async throws -> Bool
    
    /// Gets the current status of the backup operation
    /// - Returns: The current backup status
    func getBackupStatus() async -> BackupStatus
    
    // Backup configuration
    
    /// Sets the backup configuration
    /// - Parameter configuration: The new backup configuration
    /// - Throws: BackupError if the configuration cannot be set
    func setConfiguration(_ configuration: BackupConfiguration) throws
    
    /// Gets the current backup configuration
    /// - Returns: The current backup configuration
    /// - Throws: BackupError if the configuration cannot be retrieved
    func getConfiguration() throws -> BackupConfiguration
    
    /// Updates the backup schedule
    /// - Parameter schedule: The new backup schedule
    /// - Throws: BackupError if the schedule cannot be updated
    func updateSchedule(_ schedule: BackupSchedule) throws
    
    /// Gets the current backup schedule
    /// - Returns: The current backup schedule
    /// - Throws: BackupError if the schedule cannot be retrieved
    func getSchedule() throws -> BackupSchedule
    
    // Backup history and metrics
    
    /// Gets the backup history for a given time period
    /// - Parameter period: The time period to get history for
    /// - Returns: An array of backup history entries
    /// - Throws: BackupError if the history cannot be retrieved
    func getBackupHistory(for period: TimePeriod) throws -> [BackupHistoryEntry]
    
    /// Gets the backup metrics for a given time period
    /// - Parameter period: The time period to get metrics for
    /// - Returns: The backup metrics for the specified period
    /// - Throws: BackupError if the metrics cannot be retrieved
    func getBackupMetrics(for period: TimePeriod) throws -> BackupMetrics
    
    // Retention policy management
    
    /// Sets the retention policy for backups
    /// - Parameter policy: The new retention policy
    /// - Throws: BackupError if the policy cannot be set
    func setRetentionPolicy(_ policy: RetentionPolicy) throws
    
    /// Gets the current retention policy
    /// - Returns: The current retention policy
    /// - Throws: BackupError if the policy cannot be retrieved
    func getRetentionPolicy() throws -> RetentionPolicy
    
    /// Applies the retention policy to existing backups
    /// - Returns: The number of backups affected by the policy application
    /// - Throws: BackupError if the policy cannot be applied
    func applyRetentionPolicy() async throws -> Int
}

/// Delegate protocol for receiving backup operation updates and status changes
public protocol BackupServiceDelegate: AnyObject {
    /// Called when a backup operation starts
    func backupDidStart()
    
    /// Called when a backup operation completes successfully
    func backupDidComplete()
    
    /// Called when a backup operation fails
    /// - Parameter error: The error that caused the failure
    func backupDidFail(_ error: Error)
    
    /// Called when a backup operation is paused
    func backupDidPause()
    
    /// Called when a backup operation is resumed
    func backupDidResume()
    
    /// Called when backup progress is updated
    /// - Parameter progress: The current backup progress
    func backupProgressDidUpdate(_ progress: BackupProgress)
    
    /// Called when the backup status changes
    /// - Parameter status: The new backup status
    func backupStatusDidChange(_ status: BackupStatus)
}

/// Configuration for backup operations
public struct BackupConfiguration: Codable, Hashable {
    /// Source paths to backup
    public let sourcePaths: [URL]
    /// Target repository URL
    public let targetURL: URL
    /// Backup type (full, incremental, etc.)
    public let type: BackupType
    /// Compression level (0-9)
    public let compressionLevel: Int
    /// Maximum upload speed in bytes per second (0 for unlimited)
    public let maxUploadSpeed: Int64
    /// Whether to verify data after backup
    public let verifyAfterBackup: Bool
    /// Tags to apply to the backup
    public let tags: [String]
    /// Exclude patterns
    public let excludePatterns: [String]
    
    public init(
        sourcePaths: [URL],
        targetURL: URL,
        type: BackupType,
        compressionLevel: Int = 6,
        maxUploadSpeed: Int64 = 0,
        verifyAfterBackup: Bool = true,
        tags: [String] = [],
        excludePatterns: [String] = []
    ) {
        self.sourcePaths = sourcePaths
        self.targetURL = targetURL
        self.type = type
        self.compressionLevel = compressionLevel
        self.maxUploadSpeed = maxUploadSpeed
        self.verifyAfterBackup = verifyAfterBackup
        self.tags = tags
        self.excludePatterns = excludePatterns
    }
}

/// Schedule for automated backups
public struct BackupSchedule: Codable, Hashable {
    /// Days of the week to run backups
    public let days: Set<DayOfWeek>
    /// Time of day to start backups
    public let startTime: Date
    /// Whether the schedule is enabled
    public let isEnabled: Bool
    
    public init(days: Set<DayOfWeek>, startTime: Date, isEnabled: Bool = true) {
        self.days = days
        self.startTime = startTime
        self.isEnabled = isEnabled
    }
}

/// Policy for retaining backups
public struct RetentionPolicy: Codable, Hashable {
    /// Keep last n snapshots
    public let keepLast: Int?
    /// Keep hourly snapshots for n hours
    public let keepHourly: Int?
    /// Keep daily snapshots for n days
    public let keepDaily: Int?
    /// Keep weekly snapshots for n weeks
    public let keepWeekly: Int?
    /// Keep monthly snapshots for n months
    public let keepMonthly: Int?
    /// Keep yearly snapshots for n years
    public let keepYearly: Int?
    
    public init(
        keepLast: Int? = nil,
        keepHourly: Int? = nil,
        keepDaily: Int? = nil,
        keepWeekly: Int? = nil,
        keepMonthly: Int? = nil,
        keepYearly: Int? = nil
    ) {
        self.keepLast = keepLast
        self.keepHourly = keepHourly
        self.keepDaily = keepDaily
        self.keepWeekly = keepWeekly
        self.keepMonthly = keepMonthly
        self.keepYearly = keepYearly
    }
}

/// Progress information for a backup operation
public struct BackupProgress: Codable, Hashable {
    /// Total number of files to backup
    public let totalFiles: Int
    /// Number of files processed
    public let processedFiles: Int
    /// Total bytes to backup
    public let totalBytes: Int64
    /// Bytes processed
    public let processedBytes: Int64
    /// Current transfer speed in bytes per second
    public let currentSpeed: Int64
    /// Estimated time remaining in seconds
    public let estimatedTimeRemaining: TimeInterval
    
    public init(
        totalFiles: Int,
        processedFiles: Int,
        totalBytes: Int64,
        processedBytes: Int64,
        currentSpeed: Int64,
        estimatedTimeRemaining: TimeInterval
    ) {
        self.totalFiles = totalFiles
        self.processedFiles = processedFiles
        self.totalBytes = totalBytes
        self.processedBytes = processedBytes
        self.currentSpeed = currentSpeed
        self.estimatedTimeRemaining = estimatedTimeRemaining
    }
}

/// Entry in the backup history
public struct BackupHistoryEntry: Codable, Hashable {
    /// Unique identifier for the backup
    public let id: String
    /// When the backup started
    public let startTime: Date
    /// When the backup completed
    public let endTime: Date
    /// Type of backup performed
    public let type: BackupType
    /// Status of the backup
    public let status: BackupStatus
    /// Number of files backed up
    public let fileCount: Int
    /// Total bytes backed up
    public let totalBytes: Int64
    /// Any error that occurred
    public let error: String?
    
    public init(
        id: String,
        startTime: Date,
        endTime: Date,
        type: BackupType,
        status: BackupStatus,
        fileCount: Int,
        totalBytes: Int64,
        error: String? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.type = type
        self.status = status
        self.fileCount = fileCount
        self.totalBytes = totalBytes
        self.error = error
    }
}

/// Metrics for backup operations
public struct BackupMetrics: Codable, Hashable {
    /// Total number of successful backups
    public let successfulBackups: Int
    /// Total number of failed backups
    public let failedBackups: Int
    /// Total bytes backed up
    public let totalBytesBackedUp: Int64
    /// Average backup duration in seconds
    public let averageBackupDuration: TimeInterval
    /// Average backup size in bytes
    public let averageBackupSize: Int64
    
    public init(
        successfulBackups: Int,
        failedBackups: Int,
        totalBytesBackedUp: Int64,
        averageBackupDuration: TimeInterval,
        averageBackupSize: Int64
    ) {
        self.successfulBackups = successfulBackups
        self.failedBackups = failedBackups
        self.totalBytesBackedUp = totalBytesBackedUp
        self.averageBackupDuration = averageBackupDuration
        self.averageBackupSize = averageBackupSize
    }
}

/// Type of backup operation
public enum BackupType: String, Codable, Hashable {
    case full
    case incremental
    case differential
}

/// Status of a backup operation
public enum BackupStatus: String, Codable, Hashable {
    case idle
    case preparing
    case running
    case paused
    case cancelling
    case completed
    case failed
}

/// Day of the week for scheduling
public enum DayOfWeek: String, Codable, Hashable, CaseIterable {
    case sunday
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
}

/// Time period for querying backup history and metrics
public struct TimePeriod: Codable, Hashable {
    /// Start of the time period
    public let start: Date
    /// End of the time period
    public let end: Date
    
    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
}
