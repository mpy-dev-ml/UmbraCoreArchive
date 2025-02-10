import Foundation

// MARK: - KeychainCredentials

/// Represents credentials stored in the Keychain
public struct KeychainCredentials: Codable, CustomStringConvertible {
    // MARK: Lifecycle

    public init(username: String, password: String, metadata: [String: String]? = nil) {
        self.username = username
        self.password = password
        self.metadata = metadata
    }

    // MARK: Public

    /// The username or account name
    public let username: String

    /// The password or secret
    public let password: String

    /// Additional metadata if needed
    public let metadata: [String: String]?
}

public var description: String {
    String(describing: self)
}
