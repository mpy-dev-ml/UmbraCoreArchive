@preconcurrency import Foundation

/// Represents different types of repository operations
@frozen
@objc
public enum RepositoryOperation: Int, Codable, CaseIterable, Sendable, CustomStringConvertible {
    /// Initialise a new repository
    case initialise
    /// Check repository integrity
    case check
    /// Backup operation
    case backup
    /// Restore operation
    case restore
    /// Prune old snapshots
    case prune
    /// List snapshots
    case list
    /// Mount repository
    case mount
    /// Unlock repository
    case unlock
    /// Maintenance operations
    case maintenance
    /// Stats operation
    case stats

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case rawValue
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(),
           let rawValue = try? container.decode(String.self) {
            // String-based decoding for backward compatibility
            switch rawValue.lowercased() {
            case "initialise", "initialize": self = .initialise
            case "check": self = .check
            case "backup": self = .backup
            case "restore": self = .restore
            case "prune": self = .prune
            case "list": self = .list
            case "mount": self = .mount
            case "unlock": self = .unlock
            case "maintenance": self = .maintenance
            case "stats": self = .stats

            default:
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid repository operation: \(rawValue)"
                )
            }
        } else {
            // Int-based decoding (preferred)
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let rawValue = try container.decode(Int.self, forKey: .rawValue)
            if let value = Self(rawValue: rawValue) {
                self = value
            } else {
                throw DecodingError.dataCorruptedError(
                    forKey: .rawValue,
                    in: container,
                    debugDescription: "Invalid repository operation raw value: \(rawValue)"
                )
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rawValue, forKey: .rawValue)
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        switch self {
        case .initialise: "initialise"
        case .check: "check"
        case .backup: "backup"
        case .restore: "restore"
        case .prune: "prune"
        case .list: "list"
        case .mount: "mount"
        case .unlock: "unlock"
        case .maintenance: "maintenance"
        case .stats: "stats"
        }
    }
}
