@preconcurrency import Foundation

// MARK: - XPCServiceProtocol

/// Protocol defining the XPC service interface
/// All methods must be marked @objc and return values must conform to NSSecureCoding
@objc
public protocol XPCServiceProtocol {
    // MARK: - Health Check

    /// Ping service to check health
    /// - Throws: XPCError if service is unhealthy
    @objc
    func ping() async throws

    /// Validate service state
    /// - Returns: True if service is valid
    /// - Throws: XPCError if validation fails
    @objc
    func validate() async throws -> Bool

    // MARK: - Service Information

    /// Get service version
    /// - Returns: Version string
    /// - Throws: XPCError if retrieval fails
    @objc
    func getVersion() async throws -> String

    /// Get service capabilities
    /// - Returns: Dictionary of capabilities
    /// - Throws: XPCError if retrieval fails
    @objc
    func getCapabilities() async throws -> [String: Bool]

    // MARK: - Command Execution

    /// Execute command with arguments
    /// - Parameters:
    ///   - command: Command to execute
    ///   - arguments: Command arguments
    ///   - environment: Environment variables
    ///   - workingDirectory: Working directory
    /// - Returns: Command result data
    /// - Throws: XPCError if execution fails
    @objc
    func executeCommand(
        _ command: String,
        arguments: [String],
        environment: [String: String],
        workingDirectory: String
    ) async throws -> Data

    /// Cancel running command
    /// - Parameter identifier: Command identifier
    /// - Throws: XPCError if cancellation fails
    @objc
    func cancelCommand(
        identifier: String
    ) async throws

    // MARK: - File Operations

    /// Read file at path
    /// - Parameters:
    ///   - path: File path
    ///   - bookmark: Security-scoped bookmark
    /// - Returns: File data
    /// - Throws: XPCError if read fails
    @objc
    func readFile(
        at path: String,
        bookmark: Data?
    ) async throws -> Data

    /// Write data to file
    /// - Parameters:
    ///   - data: Data to write
    ///   - path: File path
    ///   - bookmark: Security-scoped bookmark
    /// - Throws: XPCError if write fails
    @objc
    func writeFile(
        _ data: Data,
        to path: String,
        bookmark: Data?
    ) async throws

    // MARK: - Security Operations

    /// Validate permissions for operation
    /// - Parameters:
    ///   - operation: Operation to validate
    ///   - path: Path to validate
    /// - Returns: True if permitted
    /// - Throws: XPCError if validation fails
    @objc
    func validatePermissions(
        for operation: String,
        at path: String
    ) async throws -> Bool

    /// Create security-scoped bookmark
    /// - Parameter path: Path to bookmark
    /// - Returns: Bookmark data
    /// - Throws: XPCError if creation fails
    @objc
    func createBookmark(
        for path: String
    ) async throws -> Data

    // MARK: - Resource Management

    /// Get resource usage
    /// - Returns: Dictionary of resource usage
    /// - Throws: XPCError if retrieval fails
    @objc
    func getResourceUsage() async throws -> [String: Double]

    /// Release resources
    /// - Parameter identifier: Resource identifier
    /// - Throws: XPCError if release fails
    @objc
    func releaseResources(
        identifier: String
    ) async throws
}

// MARK: - XPCServiceOperation

/// Represents an XPC service operation
@objc
public class XPCServiceOperation: NSObject, NSSecureCoding {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with values
    /// - Parameters:
    ///   - identifier: Operation identifier
    ///   - type: Operation type
    ///   - path: Operation path
    ///   - arguments: Operation arguments
    ///   - environment: Operation environment
    public init(
        identifier: String,
        type: String,
        path: String?,
        arguments: [String],
        environment: [String: String]
    ) {
        self.identifier = identifier
        self.type = type
        self.path = path
        self.arguments = arguments
        self.environment = environment
        timestamp = Date()
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard
            let identifier = coder.decodeObject(
                of: NSString.self,
                forKey: "identifier"
            ) as String?,
            let type = coder.decodeObject(
                of: NSString.self,
                forKey: "type"
            ) as String?,
            let arguments = coder.decodeObject(
                of: [NSArray.self, NSString.self],
                forKey: "arguments"
            ) as? [String],
            let environment = coder.decodeObject(
                of: [NSDictionary.self, NSString.self],
                forKey: "environment"
            ) as? [String: String],
            let timestamp = coder.decodeObject(
                of: NSDate.self,
                forKey: "timestamp"
            ) as Date?
        else {
            return nil
        }

        self.identifier = identifier
        self.type = type
        path = coder.decodeObject(
            of: NSString.self,
            forKey: "path"
        ) as String?
        self.arguments = arguments
        self.environment = environment
        self.timestamp = timestamp
        super.init()
    }

    // MARK: Public

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool {
        true
    }

    /// Operation identifier
    @objc public let identifier: String

    /// Operation type
    @objc public let type: String

    /// Operation path if applicable
    @objc public let path: String?

    /// Operation arguments
    @objc public let arguments: [String]

    /// Operation environment
    @objc public let environment: [String: String]

    /// Operation timestamp
    @objc public let timestamp: Date

    public func encode(with coder: NSCoder) {
        coder.encode(identifier, forKey: "identifier")
        coder.encode(type, forKey: "type")
        coder.encode(path, forKey: "path")
        coder.encode(arguments, forKey: "arguments")
        coder.encode(environment, forKey: "environment")
        coder.encode(timestamp, forKey: "timestamp")
    }
}

// MARK: - XPCServiceResult

/// Represents an XPC service operation result
@objc
public class XPCServiceResult: NSObject, NSSecureCoding {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with values
    /// - Parameters:
    ///   - identifier: Operation identifier
    ///   - data: Result data
    ///   - error: Result error
    public init(
        identifier: String,
        data: Data,
        error: Error? = nil
    ) {
        self.identifier = identifier
        self.data = data
        self.error = error
        timestamp = Date()
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard
            let identifier = coder.decodeObject(
                of: NSString.self,
                forKey: "identifier"
            ) as String?,
            let data = coder.decodeObject(
                of: NSData.self,
                forKey: "data"
            ) as Data?,
            let timestamp = coder.decodeObject(
                of: NSDate.self,
                forKey: "timestamp"
            ) as Date?
        else {
            return nil
        }

        self.identifier = identifier
        self.data = data
        if let errorString = coder.decodeObject(
            of: NSString.self,
            forKey: "error"
        ) as String? {
            error = XPCError.operationFailed(
                reason: errorString
            )
        } else {
            error = nil
        }
        self.timestamp = timestamp
        super.init()
    }

    // MARK: Public

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool {
        true
    }

    /// Operation identifier
    @objc public let identifier: String

    /// Result data
    @objc public let data: Data

    /// Result error if any
    @objc public let error: Error?

    /// Result timestamp
    @objc public let timestamp: Date

    public func encode(with coder: NSCoder) {
        coder.encode(identifier, forKey: "identifier")
        coder.encode(data, forKey: "data")
        if let error {
            coder.encode(
                String(describing: error),
                forKey: "error"
            )
        }
        coder.encode(timestamp, forKey: "timestamp")
    }
}
