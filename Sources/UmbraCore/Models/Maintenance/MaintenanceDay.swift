import Foundation

/// Days of the week for maintenance scheduling
public enum MaintenanceDay: Int, Codable, CaseIterable, CustomStringConvertible {
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

    /// Convert to Calendar.Component.weekday
    public var weekday: Int {
        rawValue
    }

    /// Convert from Calendar.Component.weekday
    public static func from(weekday: Int) -> Self? {
        Self(rawValue: weekday)
    }
}
