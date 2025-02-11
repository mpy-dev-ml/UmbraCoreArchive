// MARK: - XPCCommandConfig

/// Configuration for XPC command execution
///
/// This class encapsulates all necessary configuration for executing a command
/// through XPC, including command details, environment setup, and security settings.
///
/// Example usage:
/// ```swift
/// let config = XPCCommandConfig(
///     command: "restic",
///     arguments: ["backup", "/path/to/backup"],
///     environment: ["RESTIC_PASSWORD": "secret"],
///     workingDirectory: "/tmp"
/// )
/// ```
@objc
public class XPCCommandConfig: NSObject {
    // MARK: - Public Types

    /// Type alias for environment variables dictionary
    public typealias Environment = [String: String]

    /// Type alias for security bookmarks dictionary
    public typealias Bookmarks = [String: NSData]

    // MARK: - Public Properties

    /// Command to execute (typically "restic")
    @objc public let command: String

    /// Array of command arguments
    @objc public let arguments: [String]

    /// Dictionary of environment variables
    @objc public let environment: Environment

    /// Directory to execute command from
    @objc public let workingDirectory: String

    /// Dictionary mapping paths to security-scoped bookmarks
    @objc public let bookmarks: Bookmarks

    /// Maximum execution time in seconds (0 = no timeout)
    @objc public let timeout: TimeInterval

    /// Session identifier for security auditing
    @objc public let auditSessionID: au_asid_t

    // MARK: - Initialization

    /// Initialize with command configuration
    /// - Parameters:
    ///   - command: Command to execute
    ///   - arguments: Command arguments
    ///   - environment: Environment variables
    ///   - workingDirectory: Working directory
    ///   - bookmarks: Security-scoped bookmarks
    ///   - timeout: Maximum execution time
    ///   - auditSessionID: Security audit session ID
    @objc
    public init(
        command: String,
        arguments: [String] = [],
        environment: Environment = [:],
        workingDirectory: String = FileManager.default.currentDirectoryPath,
        bookmarks: Bookmarks = [:],
        timeout: TimeInterval = 0,
        auditSessionID: au_asid_t = 0
    ) {
        self.command = command
        self.arguments = arguments
        self.environment = environment
        self.workingDirectory = workingDirectory
        self.bookmarks = bookmarks
        self.timeout = timeout
        self.auditSessionID = auditSessionID
        super.init()
    }
}

// MARK: - NSSecureCoding

extension XPCCommandConfig: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    /// Initialize from decoder
    @objc
    public required init?(coder: NSCoder) {
        guard let values = Self.decodeRequiredValues(from: coder) else {
            return nil
        }

        command = values.command
        arguments = values.arguments
        environment = values.environment
        workingDirectory = values.workingDirectory
        bookmarks = values.bookmarks
        timeout = values.timeout
        auditSessionID = values.auditSessionID
        super.init()
    }

    /// Encode to coder
    @objc
    public func encode(with coder: NSCoder) {
        coder.encode(command, forKey: CodingKeys.command)
        coder.encode(arguments, forKey: CodingKeys.arguments)
        coder.encode(environment, forKey: CodingKeys.environment)
        coder.encode(workingDirectory, forKey: CodingKeys.workingDirectory)
        coder.encode(bookmarks, forKey: CodingKeys.bookmarks)
        coder.encode(timeout, forKey: CodingKeys.timeout)
        coder.encode(Int32(auditSessionID), forKey: CodingKeys.auditSessionID)
    }
}

// MARK: - Private Extensions

private extension XPCCommandConfig {
    /// Structure to hold decoded values
    struct DecodedValues {
        let command: String
        let arguments: [String]
        let environment: Environment
        let workingDirectory: String
        let bookmarks: Bookmarks
        let timeout: TimeInterval
        let auditSessionID: au_asid_t
    }

    /// Decode required values from the coder
    static func decodeRequiredValues(from coder: NSCoder) -> DecodedValues? {
        // Decode required command
        guard let command = decodeString(from: coder, forKey: .command) else {
            return nil
        }

        // Decode required working directory
        guard let workingDirectory = decodeString(
            from: coder,
            forKey: .workingDirectory
        ) else {
            return nil
        }

        // Decode optional values with defaults
        let arguments = decodeStringArray(from: coder) ?? []
        let environment = decodeEnvironment(from: coder) ?? [:]
        let bookmarks = decodeBookmarks(from: coder) ?? [:]
        let timeout = coder.decodeDouble(forKey: CodingKeys.timeout.rawValue)
        let auditSessionID = au_asid_t(
            coder.decodeInt32(forKey: CodingKeys.auditSessionID.rawValue)
        )

        return DecodedValues(
            command: command,
            arguments: arguments,
            environment: environment,
            workingDirectory: workingDirectory,
            bookmarks: bookmarks,
            timeout: timeout,
            auditSessionID: auditSessionID
        )
    }

    /// Decode a string value from the coder
    static func decodeString(
        from coder: NSCoder,
        forKey key: CodingKeys
    ) -> String? {
        coder.decodeObject(of: NSString.self, forKey: key.rawValue) as String?
    }

    /// Decode string array from the coder
    static func decodeStringArray(from coder: NSCoder) -> [String]? {
        let types = [NSArray.self, NSString.self]
        return coder.decodeObject(of: types, forKey: CodingKeys.arguments.rawValue)
            as? [String]
    }

    /// Decode environment dictionary from the coder
    static func decodeEnvironment(from coder: NSCoder) -> Environment? {
        let types = [NSDictionary.self, NSString.self]
        return coder.decodeObject(of: types, forKey: CodingKeys.environment.rawValue)
            as? Environment
    }

    /// Decode bookmarks dictionary from the coder
    static func decodeBookmarks(from coder: NSCoder) -> Bookmarks? {
        let types = [NSDictionary.self, NSString.self, NSData.self]
        return coder.decodeObject(of: types, forKey: CodingKeys.bookmarks.rawValue)
            as? Bookmarks
    }
}

// MARK: - CodingKeys

private extension XPCCommandConfig {
    enum CodingKeys: String {
        case command
        case arguments
        case environment
        case workingDirectory
        case bookmarks
        case timeout
        case auditSessionID
    }
}
