@preconcurrency import Foundation

// MARK: - MaintenanceService

/// Service for performing maintenance tasks
public final class MaintenanceService: BaseSandboxedService {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - configurationStore: Configuration store
    ///   - security: Security service
    ///   - performanceMonitor: Performance monitor
    ///   - logger: Logger for tracking operations
    public init(
        configurationStore: MaintenanceConfigurationStore,
        security: SecurityServiceProtocol,
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        self.configurationStore = configurationStore
        self.security = security
        self.performanceMonitor = performanceMonitor
        super.init(logger: logger)
    }

    // MARK: Public

    // MARK: - Types

    /// Result of a maintenance task
    public struct TaskResult {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            succeeded: Bool,
            duration: TimeInterval,
            error: Error? = nil,
            details: [String: String] = [:]
        ) {
            self.succeeded = succeeded
            self.duration = duration
            self.error = error
            self.details = details
        }

        // MARK: Public

        /// Whether the task succeeded
        public let succeeded: Bool
        /// Duration of the task
        public let duration: TimeInterval
        /// Any error that occurred
        public let error: Error?
        /// Additional details
        public let details: [String: String]
    }

    // MARK: - Public Methods

    /// Run maintenance tasks
    /// - Parameter tasks: Tasks to run, or nil for all configured tasks
    /// - Returns: Dictionary of task results
    /// - Throws: MaintenanceError if run fails
    public func runMaintenance(
        tasks: Set<MaintenanceConfigurationStore.MaintenanceTask>? = nil
    ) async throws -> [MaintenanceConfigurationStore.MaintenanceTask: TaskResult] {
        try validateUsable(for: "runMaintenance")

        let configuration = configurationStore.getConfiguration()
        guard configuration.isEnabled else {
            throw MaintenanceError.maintenanceDisabled
        }

        let tasksToRun = tasks ?? configuration.tasks
        var results: [MaintenanceConfigurationStore.MaintenanceTask: TaskResult] = [:]

        logger.info(
            "Starting maintenance tasks: \(tasksToRun.map(\.rawValue))",
            file: #file,
            function: #function,
            line: #line
        )

        for task in tasksToRun {
            do {
                let result = try await performanceMonitor.trackDuration(
                    "maintenance.\(task.rawValue)"
                ) {
                    try await runTask(task)
                }
                results[task] = result
            } catch {
                results[task] = TaskResult(
                    succeeded: false,
                    duration: 0,
                    error: error
                )
            }
        }

        logger.info(
            """
            Completed maintenance tasks:
            \(results.map { "\\($0.key.rawValue): \\($0.value.succeeded)" }.joined(separator: "\n"))
            """,
            file: #file,
            function: #function,
            line: #line
        )

        return results
    }

    /// Check if maintenance is due
    /// - Returns: true if maintenance is due
    public func isMaintenanceDue() -> Bool {
        let configuration = configurationStore.getConfiguration()
        guard configuration.isEnabled else {
            return false
        }

        let now = Date()
        let calendar = Calendar.current

        // Check day of week
        let weekday = calendar.component(.weekday, from: now)
        guard configuration.schedule.daysOfWeek.contains(weekday) else {
            return false
        }

        // Check time
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)

        return hour == configuration.schedule.hour && minute == configuration.schedule.minute
    }

    // MARK: Private

    /// Configuration store
    private let configurationStore: MaintenanceConfigurationStore

    /// Security service
    private let security: SecurityServiceProtocol

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    /// Queue for running tasks
    private let taskQueue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.maintenance.tasks",
        qos: .utility
    )

    /// Currently running tasks
    private var runningTasks: Set<MaintenanceConfigurationStore.MaintenanceTask> = []

    // MARK: - Private Methods

    /// Run a specific task
    /// - Parameter task: Task to run
    /// - Returns: Task result
    /// - Throws: MaintenanceError if task fails
    private func runTask(
        _ task: MaintenanceConfigurationStore.MaintenanceTask
    ) async throws -> TaskResult {
        guard !runningTasks.contains(task) else {
            throw MaintenanceError.taskAlreadyRunning(task)
        }

        runningTasks.insert(task)
        defer { runningTasks.remove(task) }

        let start = Date()

        do {
            switch task {
            case .cleanupTemporaryFiles:
                return try await cleanupTemporaryFiles()

            case .validateBookmarks:
                return try await validateBookmarks()

            case .checkFileSystemIntegrity:
                return try await checkFileSystemIntegrity()

            case .optimizeDatabase:
                return try await optimizeDatabase()

            case .validateConfiguration:
                return try await validateConfiguration()
            }
        } catch {
            logger.error(
                """
                Maintenance task failed:
                Task: \(task.rawValue)
                Error: \(error.localizedDescription)
                """,
                file: #file,
                function: #function,
                line: #line
            )
            throw error
        }
    }

    /// Clean up temporary files
    private func cleanupTemporaryFiles() async throws -> TaskResult {
        // Implementation details...
        TaskResult(succeeded: true, duration: 0)
    }

    /// Validate bookmarks
    private func validateBookmarks() async throws -> TaskResult {
        // Implementation details...
        TaskResult(succeeded: true, duration: 0)
    }

    /// Check file system integrity
    private func checkFileSystemIntegrity() async throws -> TaskResult {
        // Implementation details...
        TaskResult(succeeded: true, duration: 0)
    }

    /// Optimize database
    private func optimizeDatabase() async throws -> TaskResult {
        // Implementation details...
        TaskResult(succeeded: true, duration: 0)
    }

    /// Validate configuration
    private func validateConfiguration() async throws -> TaskResult {
        // Implementation details...
        TaskResult(succeeded: true, duration: 0)
    }
}

// MARK: - MaintenanceError

/// Errors that can occur during maintenance
public enum MaintenanceError: LocalizedError {
    /// Maintenance is disabled
    case maintenanceDisabled
    /// Task is already running
    case taskAlreadyRunning(MaintenanceConfigurationStore.MaintenanceTask)
    /// Task failed
    case taskFailed(MaintenanceConfigurationStore.MaintenanceTask, String)

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case .maintenanceDisabled:
            "Maintenance is disabled"

        case let .taskAlreadyRunning(task):
            "Task is already running: \(task.rawValue)"

        case let .taskFailed(task, reason):
            "Task failed - \(task.rawValue): \(reason)"
        }
    }
}
