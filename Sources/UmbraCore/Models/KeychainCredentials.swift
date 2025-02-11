import Foundation

// MARK: - KeychainCredentials

/// Represents secure credentials stored in the Keychain
///
/// This type provides a secure way to handle authentication credentials,
/// ensuring sensitive data is properly managed and protected.
@frozen
public struct KeychainCredentials:
    Codable,
    Hashable,
    Sendable
{
    // MARK: - Properties

    /// Account identifier or username
    public let username: String

    /// Account password or secret token
    /// - Note: This value is securely stored in the Keychain
    public let password: String

    /// Optional contextual information
    /// - Note: Do not store sensitive data in metadata
    public let metadata: [String: String]?

    // MARK: - Computed Properties

    /// Whether additional metadata is available
    public var hasMetadata: Bool {
        metadata?.isEmpty == false
    }

    /// Safe description that excludes sensitive data
    public var description: String {
        "KeychainCredentials(username: \(username), metadata: \(metadata?.description ?? "nil"))"
    }

    // MARK: - Initialisation

    /// Creates new keychain credentials
    /// - Parameters:
    ///   - username: Account identifier
    ///   - password: Secret value
    ///   - metadata: Optional context
    public init(
        username: String,
        password: String,
        metadata: [String: String]? = nil
    ) {
        self.username = username
        self.password = password
        self.metadata = metadata
    }
}

// MARK: - CustomStringConvertible

extension KeychainCredentials: CustomStringConvertible {
    // Implementation moved to computed property
}

// MARK: - Hashable

public extension KeychainCredentials {
    func hash(into hasher: inout Hasher) {
        hasher.combine(username)
        // Intentionally exclude password from hash for security
        hasher.combine(metadata)
    }
}

// MARK: - Equatable

public extension KeychainCredentials {
    static func == (lhs: KeychainCredentials, rhs: KeychainCredentials) -> Bool {
        lhs.username == rhs.username &&
            lhs.password == rhs.password &&
            lhs.metadata == rhs.metadata
    }
}
