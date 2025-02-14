@preconcurrency import Foundation

// MARK: - MaintenanceDay

/// Represents a day of the week for maintenance scheduling
public enum MaintenanceDay: Int, Codable, Sendable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
}

// MARK: - MaintenanceSchedule

/// Represents a maintenance schedule configuration
public struct MaintenanceSchedule: Codable, Sendable {
    // MARK: - Properties
    
    /// Days when maintenance is scheduled
    public let days: Set<MaintenanceDay>
    
    /// Hour of the day to start maintenance (0-23)
    public let hour: Int
    
    /// Minute of the hour to start maintenance (0-59)
    public let minute: Int
    
    /// Duration in minutes
    public let duration: Int
    
    /// Whether the schedule is enabled
    public let isEnabled: Bool
    
    private enum CodingKeys: String, CodingKey {
        case days
        case hour
        case minute
        case duration
        case isEnabled = "enabled"
    }
    
    // MARK: - Initialization
    
    public init(
        days: Set<MaintenanceDay>,
        hour: Int,
        minute: Int,
        duration: Int,
        isEnabled: Bool = true
    ) {
        self.days = days
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
        self.duration = max(duration, 0)
        self.isEnabled = isEnabled
    }
    
    // MARK: - Public Methods
    
    /// Check if maintenance is scheduled for a given date
    /// - Parameter date: Date to check
    /// - Returns: True if maintenance is scheduled for the date
    public func isScheduled(for date: Date) -> Bool {
        guard isEnabled else { return false }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday, .hour, .minute], from: date)
        
        guard let weekday = components.weekday,
              let currentHour = components.hour,
              let currentMinute = components.minute else {
            return false
        }
        
        // Convert weekday to MaintenanceDay (Calendar uses 1=Sunday, 7=Saturday)
        let maintenanceDay = MaintenanceDay(rawValue: weekday)
        
        guard let day = maintenanceDay, days.contains(day) else {
            return false
        }
        
        // Check if we're within the maintenance window
        if currentHour < hour {
            return false
        }
        
        if currentHour == hour && currentMinute < minute {
            return false
        }
        
        let endHour = hour + (minute + duration) / 60
        let endMinute = (minute + duration) % 60
        
        if currentHour > endHour {
            return false
        }
        
        if currentHour == endHour && currentMinute >= endMinute {
            return false
        }
        
        return true
    }
}

// MARK: - MaintenanceTask

/// Tasks that can be performed during maintenance
public enum MaintenanceTask: String, Codable, CaseIterable {
    case healthCheck = "health_check"
    case prune
    case rebuildIndex = "rebuild_index"
    case checkIntegrity = "check_integrity"
    case removeStaleSnapshots = "remove_stale_snapshots"
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
}

public var description: String {
    String(describing: self)
}
