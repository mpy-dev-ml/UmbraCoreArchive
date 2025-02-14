import Foundation

// MARK: - MaintenanceSchedule

/// Configuration for repository maintenance scheduling
public struct MaintenanceSchedule: Codable, CustomStringConvertible, Equatable {
    // MARK: Lifecycle

    public init(
        days: Set<MaintenanceDay> = [.sunday],
        hour: Int = 2, // 2 AM default
        minute: Int = 0,
        isEnabled: Bool = true,
        maxDuration: Int = 120,
        tasks: Set<MaintenanceTask> = MaintenanceTask.allCases
    ) {
        self.days = days
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
        self.isEnabled = isEnabled
        self.maxDuration = max(maxDuration, 30)
        self.tasks = tasks
    }

    // MARK: Public

    /// Days of the week to run maintenance
    public let days: Set<MaintenanceDay>

    /// Hour of the day to start maintenance (0-23)
    public let hour: Int

    /// Minute of the hour to start maintenance (0-59)
    public let minute: Int

    /// Whether maintenance should run automatically
    public let isEnabled: Bool

    /// Maximum duration in minutes before maintenance is considered stuck
    public let maxDuration: Int

    /// Tasks to perform during maintenance
    public let tasks: Set<MaintenanceTask>

    /// String representation of the maintenance schedule
    public var description: String {
        let timeString = String(format: "%02d:%02d", hour, minute)
        let daysString = days.map { $0.description }.sorted().joined(separator: ", ")
        let tasksString = tasks.isEmpty ? "None" : tasks.map { String(describing: $0) }.sorted().joined(separator: ", ")
        
        return """
        Maintenance Schedule:
        - Days: \(daysString)
        - Time: \(timeString)
        - Enabled: \(isEnabled ? "Yes" : "No")
        - Max Duration: \(maxDuration) minutes
        - Tasks: \(tasksString)
        """
    }

    // MARK: Equatable

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.days == rhs.days &&
        lhs.hour == rhs.hour &&
        lhs.minute == rhs.minute &&
        lhs.isEnabled == rhs.isEnabled &&
        lhs.maxDuration == rhs.maxDuration &&
        lhs.tasks == rhs.tasks
    }
}

// MARK: - MaintenanceResult

/// Result of a maintenance run
public struct MaintenanceResult: Codable, CustomStringConvertible, Equatable {
    /// When the maintenance run started
    public let startTime: Date

    /// When the maintenance run completed
    public let endTime: Date

    /// Tasks that were completed successfully
    public let completedTasks: Set<MaintenanceTask>

    /// Tasks that failed
    public let failedTasks: [MaintenanceTask: Error]

    /// Whether the maintenance run was successful overall
    public var isSuccessful: Bool {
        failedTasks.isEmpty
    }

    /// Duration of the maintenance run in seconds
    public var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    /// String representation of the maintenance result
    public var description: String {
        """
        Maintenance Run:
        - Started: \(startTime)
        - Ended: \(endTime)
        - Duration: \(String(format: "%.2f", duration))s
        - Completed Tasks: \(completedTasks.count)
        - Failed Tasks: \(failedTasks.count)
        - Overall Status: \(isSuccessful ? "Successful" : "Failed")
        """
    }

    /// Create a new maintenance result
    /// - Parameters:
    ///   - startTime: When the maintenance run started
    ///   - endTime: When the maintenance run completed
    ///   - completedTasks: Tasks that were completed successfully
    ///   - failedTasks: Tasks that failed
    public init(
        startTime: Date,
        endTime: Date,
        completedTasks: Set<MaintenanceTask>,
        failedTasks: [MaintenanceTask: Error]
    ) {
        self.startTime = startTime
        self.endTime = endTime
        self.completedTasks = completedTasks
        self.failedTasks = failedTasks
    }
}
