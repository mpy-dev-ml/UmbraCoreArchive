import Foundation

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
@objc
public class ResticCommand: NSObject, NSSecureCoding {
    // MARK: Lifecycle

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

    /// Decodes and initializes a command from secure storage
    /// - Parameter coder: The coder to read from
    /// - Returns: A new ResticCommand instance, or nil if decoding fails
    @objc
    public required init?(coder: NSCoder) {
        guard
            let command = coder.decodeObject(
                of: NSString.self,
                forKey: "command"
            ) as String?,
            let arguments = coder.decodeObject(
                of: NSArray.self,
                forKey: "arguments"
            ) as? [String],
            let environment = coder.decodeObject(
                of: NSDictionary.self,
                forKey: "environment"
            ) as? [String: String],
            let bookmarks = coder.decodeObject(
                of: NSDictionary.self,
                forKey: "bookmarks"
            ) as? [String: NSData]
        else {
            return nil
        }

        self.command = command
        self.arguments = arguments
        self.environment = environment
        workingDirectory = coder.decodeObject(
            of: NSString.self,
            forKey: "workingDirectory"
        ) as String?
        self.bookmarks = bookmarks
        super.init()
    }

    // MARK: Public

    // MARK: - NSSecureCoding

    /// Indicates that this class supports secure coding
    public static var supportsSecureCoding: Bool { true }

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
    @objc public let environment: [String: String]

    /// Working directory
    ///
    /// Optional directory from which to execute the command.
    /// If nil, uses the default working directory.
    @objc public let workingDirectory: String?

    /// Security-scoped bookmarks
    ///
    /// Dictionary mapping paths to their security-scoped bookmarks.
    /// Used to maintain file access across app launches.
    @objc public let bookmarks: [String: NSData]

    /// Encodes the command for secure transmission
    /// - Parameter coder: The coder to write to
    @objc
    public func encode(with coder: NSCoder) {
        coder.encode(command, forKey: "command")
        coder.encode(arguments, forKey: "arguments")
        coder.encode(environment, forKey: "environment")
        coder.encode(workingDirectory, forKey: "workingDirectory")
        coder.encode(bookmarks, forKey: "bookmarks")
    }
}
