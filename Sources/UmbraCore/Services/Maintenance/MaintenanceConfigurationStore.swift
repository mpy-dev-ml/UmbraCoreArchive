import Foundation

/// Configuration store for maintenance service
@MainActor
public final class MaintenanceConfigurationStore: @unchecked Sendable {
    // MARK: - Properties
    
    /// Whether maintenance is enabled
    private var isEnabled: Bool
    
    /// Maximum duration in minutes
    private var maxDuration: Int
    
    /// Tasks to run
    private var tasks: Set<MaintenanceTask>
    
    /// Maintenance schedule
    private var schedule: MaintenanceSchedule
    
    /// Task priorities
    private var priorities: [String: MaintenanceTaskPriority]
    
    // MARK: - Initialization
    
    /// Initialize configuration store
    /// - Parameters:
    ///   - isEnabled: Whether maintenance is enabled
    ///   - maxDuration: Maximum duration in minutes
    ///   - tasks: Tasks to run
    ///   - schedule: Initial maintenance schedule
    ///   - priorities: Initial task priorities
    public init(
        isEnabled: Bool = true,
        maxDuration: Int = 120,
        tasks: Set<MaintenanceTask> = Set(MaintenanceTask.allCases),
        schedule: MaintenanceSchedule = MaintenanceSchedule(),
        priorities: [String: MaintenanceTaskPriority] = [:]
    ) {
        self.isEnabled = isEnabled
        self.maxDuration = maxDuration
        self.tasks = tasks
        self.schedule = schedule
        self.priorities = priorities
    }
    
    // MARK: - Configuration Management
    
    /// Update enabled state
    /// - Parameter enabled: New state
    public func updateEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
    
    /// Update maximum duration
    /// - Parameter duration: New duration in minutes
    public func updateMaxDuration(_ duration: Int) {
        maxDuration = duration
    }
    
    /// Update tasks
    /// - Parameter tasks: New tasks
    public func updateTasks(_ tasks: Set<MaintenanceTask>) {
        self.tasks = tasks
    }
    
    // MARK: - Schedule Management
    
    /// Get the maintenance schedule
    /// - Returns: Current maintenance schedule
    public func getSchedule() -> MaintenanceSchedule {
        return schedule
    }
    
    /// Update the maintenance schedule
    /// - Parameter schedule: New maintenance schedule
    public func updateSchedule(_ schedule: MaintenanceSchedule) {
        self.schedule = schedule
    }
    
    // MARK: - Priority Management
    
    /// Get priority for a task
    /// - Parameter taskId: Task identifier
    /// - Returns: Task priority if found
    public func getPriority(for taskId: String) -> MaintenanceTaskPriority? {
        return priorities[taskId]
    }
    
    /// Set priority for a task
    /// - Parameters:
    ///   - priority: Task priority
    ///   - taskId: Task identifier
    public func setPriority(_ priority: MaintenanceTaskPriority, for taskId: String) {
        priorities[taskId] = priority
    }
    
    /// Remove priority for a task
    /// - Parameter taskId: Task identifier
    public func removePriority(for taskId: String) {
        priorities.removeValue(forKey: taskId)
    }
    
    /// Get all task priorities
    /// - Returns: Dictionary of task priorities
    public func getAllPriorities() -> [String: MaintenanceTaskPriority] {
        return priorities
    }
    
    /// Clear all task priorities
    public func clearPriorities() {
        priorities.removeAll()
    }
}
