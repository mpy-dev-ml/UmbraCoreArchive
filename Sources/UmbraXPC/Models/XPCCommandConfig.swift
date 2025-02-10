import Foundation

// MARK: - XPCCommandConfig

/// Configuration for XPC command execution
///
/// This class encapsulates all necessary configuration for executing a command
/// through XPC, including:
/// - Command and arguments
/// - Environment variables
/// - Working directory
/// - Security-scoped bookmarks
/// - Timeout settings
/// - Audit session information
///
/// Example usage:
/// ```swift
/// let config = XPCCommandConfig(
///     command: "restic",
///     arguments: ["backup", "/path/to/backup"],
///     environment: ["RESTIC_PASSWORD": "secret"],
///     workingDirectory: "/tmp",
///     bookmarks: [:],
///     timeout: 300,
///     auditSessionId: au_session_self()
/// )
/// ```
@objc
public class XPCCommandConfig: NSObject {
    // MARK: - Types

    /// Type alias for environment variables dictionary
    public typealias Environment = [String: String]

    /// Type alias for security bookmarks dictionary
    public typealias Bookmarks = [String: NSData]

    // MARK: - Properties

    /// Command to execute
    ///
    /// The main command to be executed, typically "restic"
    @objc public let command: String

    /// Command arguments
    ///
    /// Array of arguments to pass to the command, such as:
    /// - Operation type (backup, restore, etc.)
    /// - Target paths
    /// - Configuration options
    @objc public let arguments: [String]

    /// Environment variables
    ///
    /// Dictionary of environment variables required for the command:
    /// - RESTIC_PASSWORD: Repository password
    /// - RESTIC_REPOSITORY: Repository location
    /// - Custom configuration variables
    @objc public let environment: Environment

    /// Working directory
    ///
    /// Directory from which to execute the command
    @objc public let workingDirectory: String

    /// Security-scoped bookmarks
    ///
    /// Dictionary mapping paths to their security-scoped bookmarks.
    /// Used to maintain file access across app launches.
    @objc public let bookmarks: Bookmarks

    /// Command timeout
    ///
    /// Maximum time (in seconds) to wait for command completion.
    /// A value of 0 means no timeout.
    @objc public let timeout: TimeInterval

    /// Audit session identifier
    ///
    /// Used for security auditing and process tracking
    @objc public let auditSessionID: au_asid_t

    // MARK: - Initialization

    /// Initialize with command configuration
    /// - Parameters:
    ///   - command: Command to execute (typically "restic")
    ///   - arguments: Array of command arguments
    ///   - environment: Dictionary of environment variables
    ///   - workingDirectory: Directory to execute command from
    ///   - bookmarks: Dictionary of security-scoped bookmarks
    ///   - timeout: Maximum execution time in seconds (0 = no timeout)
    ///   - auditSessionId: Session identifier for security auditing
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
    /// - Parameter coder: Decoder to read from
    /// - Returns: A new XPCCommandConfig instance, or nil if decoding fails
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
    /// - Parameter coder: Coder to write to
    @objc
    public func encode(with coder: NSCoder) {
        coder.encode(command, forKey: CodingKeys.command)
        coder.encode(arguments, forKey: CodingKeys.arguments)
        coder.encode(environment, forKey: CodingKeys.environment)
        coder.encode(
            workingDirectory,
            forKey: CodingKeys.workingDirectory
        )
        coder.encode(bookmarks, forKey: CodingKeys.bookmarks)
        coder.encode(timeout, forKey: CodingKeys.timeout)
        coder.encode(
            Int32(auditSessionID),
            forKey: CodingKeys.auditSessionID
        )
    }
}

// MARK: - Decoding Support

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
    /// - Parameter coder: The decoder to read from
    /// - Returns: The decoded values, or nil if decoding fails
    static func decodeRequiredValues(
        from coder: NSCoder
    ) -> DecodedValues? {
        // Decode required command
        guard let command = decodeString(
            from: coder,
            forKey: .command
        ) else {
            return nil
        }

        // Decode optional values with defaults
        let arguments = decodeStringArray(from: coder) ?? []
        let environment = decodeEnvironment(from: coder) ?? [:]

        // Decode required working directory
        guard let workingDirectory = decodeString(
            from: coder,
            forKey: .workingDirectory
        ) else {
            return nil
        }

        // Decode remaining values
        let bookmarks = decodeBookmarks(from: coder) ?? [:]
        let timeout = coder.decodeDouble(
            forKey: CodingKeys.timeout.rawValue
        )
        let auditSessionID = au_asid_t(
            coder.decodeInt32(
                forKey: CodingKeys.auditSessionID.rawValue
            )
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
    /// - Parameters:
    ///   - coder: The decoder to read from
    ///   - key: The coding key to read
    /// - Returns: The decoded string, or nil if decoding fails
    static func decodeString(
        from coder: NSCoder,
        forKey key: CodingKeys
    ) -> String? {
        coder.decodeObject(
            of: NSString.self,
            forKey: key.rawValue
        ) as String?
    }

    /// Decode string array from the coder
    /// - Parameter coder: The decoder to read from
    /// - Returns: The decoded string array, or nil if decoding fails
    static func decodeStringArray(
        from coder: NSCoder
    ) -> [String]? {
        let allowedTypes = [NSArray.self, NSString.self]
        return coder.decodeObject(
            of: allowedTypes,
            forKey: CodingKeys.arguments.rawValue
        ) as? [String]
    }

    /// Decode environment dictionary from the coder
    /// - Parameter coder: The decoder to read from
    /// - Returns: The decoded environment dictionary, or nil if decoding fails
    static func decodeEnvironment(
        from coder: NSCoder
    ) -> Environment? {
        let allowedTypes = [NSDictionary.self, NSString.self]
        return coder.decodeObject(
            of: allowedTypes,
            forKey: CodingKeys.environment.rawValue
        ) as? Environment
    }

    /// Decode bookmarks dictionary from the coder
    /// - Parameter coder: The decoder to read from
    /// - Returns: The decoded bookmarks dictionary, or nil if decoding fails
    static func decodeBookmarks(
        from coder: NSCoder
    ) -> Bookmarks? {
        let allowedTypes = [
            NSDictionary.self,
            NSString.self,
            NSData.self
        ]
        return coder.decodeObject(
            of: allowedTypes,
            forKey: CodingKeys.bookmarks.rawValue
        ) as? Bookmarks
    }
}

// MARK: - Coding Keys

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
