@preconcurrency import Foundation

/// Represents a sidebar navigation item
public enum SidebarItem: String, CaseIterable, Identifiable {
    case repositories = "Repositories"
    case backups = "Backups"
    case settings = "Settings"

    // MARK: Public

    public var id: String { rawValue }

    /// Icon name for the item
    public var iconName: String {
        switch self {
        case .repositories:
            "folder"
        case .backups:
            "arrow.clockwise"
        case .settings:
            "gear"
        }
    }
}
