@preconcurrency import Foundation

/// Days of the week for maintenance scheduling
@objc
public enum MaintenanceDay: Int, Codable, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    // MARK: - CustomStringConvertible

    public var description: String {
        switch self {
        case .sunday: "Sunday"
        case .monday: "Monday"
        case .tuesday: "Tuesday"
        case .wednesday: "Wednesday"
        case .thursday: "Thursday"
        case .friday: "Friday"
        case .saturday: "Saturday"
        }
    }

    // MARK: Public

    /// Convert from Calendar.Component.weekday
    public static func from(weekday: Int) -> MaintenanceDay? {
        MaintenanceDay(rawValue: weekday)
    }

    /// Get the next occurrence of this day
    public func nextOccurrence(after date: Date = Date()) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .weekday], from: date)

        // Calculate days until next occurrence
        let currentWeekday = components.weekday ?? 1
        let daysToAdd = (rawValue - currentWeekday + 7) % 7

        // If it's the same day and we want next occurrence, add 7 days
        let adjustedDaysToAdd = daysToAdd == 0 ? 7 : daysToAdd

        components.day! += adjustedDaysToAdd

        return calendar.date(from: components) ?? date
    }
}
