import Foundation

/// Types of maintenance tasks that can be performed on a repository
public enum MaintenanceTask: Int, Codable, CaseIterable, CustomStringConvertible {
    /// Check repository integrity
    case check
    /// Remove unused data
    case prune
    /// Rebuild index
    case rebuildIndex
    /// Pack files for optimisation
    case pack
    /// Check for stale locks
    case checkLocks
    /// Verify data integrity
    case verify

    // MARK: - CustomStringConvertible

    public var description: String {
        switch self {
        case .check: "Check Repository"
        case .prune: "Remove Unused Data"
        case .rebuildIndex: "Rebuild Index"
        case .pack: "Pack Files"
        case .checkLocks: "Check Locks"
        case .verify: "Verify Data"
        }
    }

    // MARK: Public

    /// Get the estimated duration in minutes for this task
    public var estimatedDuration: Int {
        switch self {
        case .checkLocks: 5
        case .check: 15
        case .verify: 60
        case .prune: 30
        case .rebuildIndex: 45
        case .pack: 45
        }
    }

    /// Check if this task can run in parallel with others
    public var canRunParallel: Bool {
        switch self {
        case .check, .verify: true
        case .checkLocks, .prune, .rebuildIndex, .pack: false
        }
    }

    /// Get dependencies that must be run before this task
    public var dependencies: Set<Self> {
        switch self {
        case .pack: [.prune]
        case .rebuildIndex: [.check]
        case .verify: [.check]
        case .check, .prune, .checkLocks: []
        }
    }
}
