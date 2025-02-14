import Foundation

/// Configuration store for maintenance service
@objc @unchecked public final class MaintenanceConfigurationStore: NSObject, Sendable {
    // MARK: - Properties
    
    /// Whether maintenance is enabled
    @MainActor public private(set) var isEnabled: Bool
    
    /// Maximum duration in minutes
    @MainActor public private(set) var maxDuration: Int
    
    /// Tasks to run
    @MainActor public private(set) var tasks: Set<MaintenanceTask>
    
    // MARK: - Initialization
    
    /// Initialize configuration store
    /// - Parameters:
    ///   - isEnabled: Whether maintenance is enabled
    ///   - maxDuration: Maximum duration in minutes
    ///   - tasks: Tasks to run
    public init(
        isEnabled: Bool = true,
        maxDuration: Int = 120,
        tasks: Set<MaintenanceTask> = Set(MaintenanceTask.allCases)
    ) {
        self.isEnabled = isEnabled
        self.maxDuration = maxDuration
        self.tasks = tasks
        super.init()
    }
    
    // MARK: - Configuration Management
    
    /// Update enabled state
    /// - Parameter enabled: New state
    @MainActor public func updateEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
    
    /// Update maximum duration
    /// - Parameter duration: New duration in minutes
    @MainActor public func updateMaxDuration(_ duration: Int) {
        maxDuration = duration
    }
    
    /// Update tasks
    /// - Parameter tasks: New tasks
    @MainActor public func updateTasks(_ tasks: Set<MaintenanceTask>) {
        self.tasks = tasks
    }
}
