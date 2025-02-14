@preconcurrency import Foundation

// MARK: - BackupServiceProtocol

/// Protocol defining the core backup service functionality
public protocol BackupServiceProtocol: Sendable {
    /// The delegate to receive backup operation updates
    var delegate: BackupServiceDelegate? { get set }

    // Core backup operations

    /// Starts a backup operation with the specified configuration
    /// - Parameter configuration: The configuration for the backup operation
    /// - Returns: A boolean indicating whether the backup was started successfully
    func startBackup(with configuration: Services.Backup.BackupConfiguration) async throws -> Bool

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
    func setConfiguration(_ configuration: Services.Backup.BackupConfiguration) throws

    /// Gets the current backup configuration
    /// - Returns: The current backup configuration
    /// - Throws: BackupError if the configuration cannot be retrieved
    func getConfiguration() throws -> Services.Backup.BackupConfiguration

    /// Updates the backup schedule
    /// - Parameter schedule: The new backup schedule
    /// - Throws: BackupError if the schedule cannot be updated
    func updateSchedule(_ schedule: BackupSchedule) throws

    /// Gets the current backup schedule
    /// - Returns: The current backup schedule
    /// - Throws: BackupError if the schedule cannot be retrieved
    func getSchedule() throws -> BackupSchedule

    // History and statistics

    /// Gets the backup history
    /// - Parameter filter: Optional filter criteria for history entries
    /// - Returns: Array of backup history entries
    /// - Throws: BackupError if history cannot be retrieved
    func getHistory(filter: BackupHistoryFilter?) throws -> [BackupHistoryEntry]

    /// Gets backup statistics
    /// - Returns: Current backup statistics
    /// - Throws: BackupError if statistics cannot be retrieved
    func getStatistics() throws -> BackupStatistics

    // Maintenance

    /// Verifies backup integrity
    /// - Parameter options: Optional verification options
    /// - Returns: Boolean indicating verification success
    /// - Throws: BackupError if verification fails
    func verifyBackup(options: BackupVerificationOptions?) async throws -> Bool

    /// Performs backup maintenance
    /// - Parameter options: Optional maintenance options
    /// - Returns: Boolean indicating maintenance success
    /// - Throws: BackupError if maintenance fails
    func performMaintenance(options: BackupMaintenanceOptions?) async throws -> Bool
}

// MARK: - BackupServiceDelegate

/// Delegate for backup service events
public protocol BackupServiceDelegate: AnyObject, Sendable {
    /// Called when backup progress is updated
    /// - Parameter progress: Current progress
    func backupProgressDidUpdate(_ progress: Double)
    
    /// Called when backup state changes
    /// - Parameter state: New state
    func backupStateDidChange(_ state: BackupState)
    
    /// Called when backup encounters an error
    /// - Parameter error: The error that occurred
    func backupDidEncounterError(_ error: Error)
}

// MARK: - BackupHistoryEntry

/// Represents a backup history entry
public struct BackupHistoryEntry: Codable, Hashable, Sendable {
    /// Unique identifier for the entry
    public let id: String
    /// Start time of the backup
    public let startTime: Date
    /// End time of the backup
    public let endTime: Date
    /// Status of the backup
    public let status: BackupStatus
    /// Size of the backup in bytes
    public let size: Int64
    /// Number of files backed up
    public let fileCount: Int
    /// Any error that occurred
    public let error: Error?
    /// Custom metadata
    public let metadata: [String: String]

    public init(
        id: String,
        startTime: Date,
        endTime: Date,
        status: BackupStatus,
        size: Int64,
        fileCount: Int,
        error: Error? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.size = size
        self.fileCount = fileCount
        self.error = error
        self.metadata = metadata
    }
}

// MARK: - BackupStatistics

/// Statistics for backup operations
public struct BackupStatistics: Codable, Hashable {
    /// Total size of all backups in bytes
    public let totalSize: Int64
    /// Total number of files backed up
    public let totalFiles: Int
    /// Number of successful backups
    public let successfulBackups: Int
    /// Number of failed backups
    public let failedBackups: Int
    /// Average backup duration in seconds
    public let averageDuration: TimeInterval
    /// Last successful backup time
    public let lastSuccessfulBackup: Date?
    /// Last failed backup time
    public let lastFailedBackup: Date?
    /// Custom metrics
    public let metrics: [String: Double]

    public init(
        totalSize: Int64,
        totalFiles: Int,
        successfulBackups: Int,
        failedBackups: Int,
        averageDuration: TimeInterval,
        lastSuccessfulBackup: Date? = nil,
        lastFailedBackup: Date? = nil,
        metrics: [String: Double] = [:]
    ) {
        self.totalSize = totalSize
        self.totalFiles = totalFiles
        self.successfulBackups = successfulBackups
        self.failedBackups = failedBackups
        self.averageDuration = averageDuration
        self.lastSuccessfulBackup = lastSuccessfulBackup
        self.lastFailedBackup = lastFailedBackup
        self.metrics = metrics
    }
}

// MARK: - BackupStatus

/// Status of a backup operation
public enum BackupStatus: String, Codable {
    case idle
    case preparing
    case running
    case paused
    case cancelling
    case completed
    case failed
}

// MARK: - BackupHistoryFilter

/// Filter criteria for backup history
public struct BackupHistoryFilter: Codable, Hashable {
    /// Start date for filtering
    public let startDate: Date?
    /// End date for filtering
    public let endDate: Date?
    /// Status to filter by
    public let status: BackupStatus?
    /// Minimum size in bytes
    public let minSize: Int64?
    /// Maximum size in bytes
    public let maxSize: Int64?
    /// Custom metadata filters
    public let metadata: [String: String]

    public init(
        startDate: Date? = nil,
        endDate: Date? = nil,
        status: BackupStatus? = nil,
        minSize: Int64? = nil,
        maxSize: Int64? = nil,
        metadata: [String: String] = [:]
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.minSize = minSize
        self.maxSize = maxSize
        self.metadata = metadata
    }
}

// MARK: - BackupVerificationOptions

/// Options for backup verification
public struct BackupVerificationOptions: Codable, Hashable {
    /// Whether to verify file contents
    public let verifyContents: Bool
    /// Whether to verify metadata
    public let verifyMetadata: Bool
    /// Whether to verify file permissions
    public let verifyPermissions: Bool
    /// Custom verification options
    public let options: [String: String]

    public init(
        verifyContents: Bool = true,
        verifyMetadata: Bool = true,
        verifyPermissions: Bool = true,
        options: [String: String] = [:]
    ) {
        self.verifyContents = verifyContents
        self.verifyMetadata = verifyMetadata
        self.verifyPermissions = verifyPermissions
        self.options = options
    }
}

// MARK: - BackupMaintenanceOptions

/// Options for backup maintenance
public struct BackupMaintenanceOptions: Codable, Hashable {
    /// Whether to clean up old backups
    public let cleanupOldBackups: Bool
    /// Whether to optimize storage
    public let optimizeStorage: Bool
    /// Whether to verify repository
    public let verifyRepository: Bool
    /// Custom maintenance options
    public let options: [String: String]

    public init(
        cleanupOldBackups: Bool = true,
        optimizeStorage: Bool = true,
        verifyRepository: Bool = true,
        options: [String: String] = [:]
    ) {
        self.cleanupOldBackups = cleanupOldBackups
        self.optimizeStorage = optimizeStorage
        self.verifyRepository = verifyRepository
        self.options = options
    }
}

// MARK: - BackupSchedule

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

// MARK: - DayOfWeek

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
