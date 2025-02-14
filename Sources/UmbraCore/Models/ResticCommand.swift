@preconcurrency import Foundation

/// Class representing a Restic command for XPC execution
///
/// This class encapsulates all necessary information to execute a Restic command
/// through XPC, including:
/// - Command and arguments
/// - Environment variables
/// - Working directory
/// - Security-scoped bookmarks
///
/// Example usage:
/// ```swift
/// let command = ResticCommand(
///     command: "restic",
///     arguments: ["backup", "/path/to/backup"],
///     environment: ["RESTIC_PASSWORD": "secret"],
///     workingDirectory: "/tmp",
///     bookmarks: [:]
/// )
/// ```
@Observable
@objc
public class ResticCommand: NSObject, Codable {
    // MARK: - Types
    
    private enum CodingKeys: String, CodingKey {
        case command
        case arguments
        case environment = "env"
        case workingDirectory = "working_dir"
        case bookmarks
    }
    
    // MARK: - Properties

    /// Command to execute (typically "restic")
    @objc public let command: String

    /// Array of command arguments
    @objc public let arguments: [String]

    /// Dictionary of environment variables
    @objc public let environment: [String: String]

    /// Optional working directory path
    @objc public let workingDirectory: String?

    /// Dictionary of security-scoped bookmarks
    @objc public let bookmarks: [String: NSData]

    // MARK: - Initialization

    /// Initialize a new Restic command
    /// - Parameters:
    ///   - command: Command to execute (typically "restic")
    ///   - arguments: Array of command arguments
    ///   - environment: Dictionary of environment variables
    ///   - workingDirectory: Optional working directory path
    ///   - bookmarks: Dictionary of security-scoped bookmarks
    @objc
    public init(
        command: String,
        arguments: [String],
        environment: [String: String],
        workingDirectory: String?,
        bookmarks: [String: NSData]
    ) {
        self.command = command
        self.arguments = arguments
        self.environment = environment
        self.workingDirectory = workingDirectory
        self.bookmarks = bookmarks
        super.init()
    }

    // MARK: - Codable Implementation

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        command = try container.decode(String.self, forKey: .command)
        arguments = try container.decode([String].self, forKey: .arguments)
        environment = try container.decode([String: String].self, forKey: .environment)
        workingDirectory = try container.decodeIfPresent(String.self, forKey: .workingDirectory)
        bookmarks = try container.decode([String: NSData].self, forKey: .bookmarks)
        super.init()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(command, forKey: .command)
        try container.encode(arguments, forKey: .arguments)
        try container.encode(environment, forKey: .environment)
        try container.encodeIfPresent(workingDirectory, forKey: .workingDirectory)
        try container.encode(bookmarks, forKey: .bookmarks)
    }

    // MARK: - NSSecureCoding Support

    public static var supportsSecureCoding: Bool { true }

    @objc
    public func encode(with coder: NSCoder) {
        coder.encode(command, forKey: CodingKeys.command.stringValue)
        coder.encode(arguments, forKey: CodingKeys.arguments.stringValue)
        coder.encode(environment, forKey: CodingKeys.environment.stringValue)
        coder.encode(workingDirectory, forKey: CodingKeys.workingDirectory.stringValue)
        coder.encode(bookmarks, forKey: CodingKeys.bookmarks.stringValue)
    }

    @objc
    public required init?(coder: NSCoder) {
        guard let command = coder.decodeObject(of: NSString.self, forKey: CodingKeys.command.stringValue) as String?,
              let arguments = coder.decodeObject(of: [NSString].self, forKey: CodingKeys.arguments.stringValue) as [String]?,
              let environment = coder.decodeObject(of: [NSString: NSString].self, forKey: CodingKeys.environment.stringValue) as [String: String]?,
              let bookmarks = coder.decodeObject(of: [NSString: NSData].self, forKey: CodingKeys.bookmarks.stringValue) as [String: NSData]?
        else {
            return nil
        }

        self.command = command
        self.arguments = arguments
        self.environment = environment
        workingDirectory = coder.decodeObject(of: NSString.self, forKey: CodingKeys.workingDirectory.stringValue) as String?
        self.bookmarks = bookmarks
        super.init()
    }
}
