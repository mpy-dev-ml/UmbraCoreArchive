import Foundation
import Logging

// MARK: - XPCServiceProtocol

/// Protocol defining the XPC service interface
/// All methods must be marked @objc and return values must conform to NSSecureCoding
@objc
public protocol XPCServiceProtocol: Sendable {
    // MARK: - Health Check

    /// Ping service to check health
    /// - Throws: XPCServiceError if service is unhealthy
    @objc
    func ping() async throws

    /// Validate service state
    /// - Returns: True if service is valid
    /// - Throws: XPCServiceError if validation fails
    @objc
    func validate() async throws -> Bool

    // MARK: - Service Information

    /// Get service version
    /// - Returns: Version string
    /// - Throws: XPCServiceError if retrieval fails
    @objc
    func getVersion() async throws -> String

    /// Get service capabilities
    /// - Returns: Dictionary of capabilities
    /// - Throws: XPCServiceError if retrieval fails
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
    /// - Throws: XPCServiceError if execution fails
    @objc
    func executeCommand(
        _ command: String,
        arguments: [String],
        environment: [String: String],
        workingDirectory: String?
    ) async throws -> XPCServiceResponse

    /// Cancel running command
    /// - Parameter identifier: Command identifier
    /// - Throws: XPCServiceError if cancellation fails
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
    /// - Throws: XPCServiceError if read fails
    @objc
    func readFile(
        at path: String,
        bookmark: Data?
    ) async throws -> XPCServiceResponse

    /// Write data to file
    /// - Parameters:
    ///   - data: Data to write
    ///   - path: File path
    ///   - bookmark: Security-scoped bookmark
    /// - Throws: XPCServiceError if write fails
    @objc
    func writeFile(
        _ data: Data,
        to path: String,
        bookmark: Data?
    ) async throws -> XPCServiceResponse

    // MARK: - Security Operations

    /// Validate permissions for operation
    /// - Parameters:
    ///   - operation: Operation to validate
    ///   - path: Path to validate
    /// - Returns: True if permitted
    /// - Throws: XPCServiceError if validation fails
    @objc
    func validatePermissions(
        for operation: String,
        at path: String
    ) async throws -> Bool

    /// Create security-scoped bookmark
    /// - Parameter path: Path to bookmark
    /// - Returns: Bookmark data
    /// - Throws: XPCServiceError if creation fails
    @objc
    func createBookmark(
        for path: String
    ) async throws -> Data

    // MARK: - Resource Management

    /// Get resource usage
    /// - Returns: Dictionary of resource usage
    /// - Throws: XPCServiceError if retrieval fails
    @objc
    func getResourceUsage() async throws -> [String: Double]

    /// Release resources
    /// - Parameter identifier: Resource identifier
    /// - Throws: XPCServiceError if release fails
    @objc
    func releaseResources(
        identifier: String
    ) async throws
}

// MARK: - XPCServiceOperation

/// Represents an XPC service operation
@frozen
@Observable
@objc
public final class XPCServiceOperation: NSObject, NSSecureCoding, Sendable {
    // MARK: - Types

    /// Operation type
    @frozen
    public enum OperationType: String, Sendable, CaseIterable, Comparable {
        case command
        case fileRead
        case fileWrite
        case security
        case resource

        /// Whether the operation requires a path
        public var requiresPath: Bool {
            switch self {
            case .fileRead, .fileWrite, .security:
                true

            case .command, .resource:
                false
            }
        }

        /// Whether the operation supports cancellation
        public var supportsCancellation: Bool {
            switch self {
            case .command, .fileRead, .fileWrite:
                true

            case .security, .resource:
                false
            }
        }

        /// Priority level for the operation
        public var priority: Int {
            switch self {
            case .security:
                3 // Critical
            case .command:
                2 // High
            case .fileRead, .fileWrite:
                1 // Normal
            case .resource:
                0 // Low
            }
        }

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.priority < rhs.priority
        }
    }

    // MARK: - Properties

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

    // MARK: - Computed Properties

    /// Operation type as enum
    public var operationType: OperationType? {
        OperationType(rawValue: type)
    }

    /// Whether operation is valid
    public var isValid: Bool {
        guard let operationType else { return false }
        if operationType.requiresPath, path == nil { return false }
        return true
    }

    /// Priority level for the operation
    public var priority: Int {
        operationType?.priority ?? -1
    }

    /// Whether operation supports cancellation
    public var supportsCancellation: Bool {
        operationType?.supportsCancellation ?? false
    }

    /// Operation metadata for logging
    public var loggingMetadata: Logger.Metadata {
        [
            "identifier": .string(identifier),
            "type": .string(type),
            "path": .string(path ?? "none"),
            "arguments": .string(arguments.joined(separator: " ")),
            "timestamp": .string(timestamp.description),
            "priority": .string(String(priority))
        ]
    }

    // MARK: - Initialization

    /// Initialize with values
    /// - Parameters:
    ///   - identifier: Operation identifier
    ///   - type: Operation type
    ///   - path: Operation path
    ///   - arguments: Operation arguments
    ///   - environment: Operation environment
    public init(
        identifier: String = UUID().uuidString,
        type: OperationType,
        path: String? = nil,
        arguments: [String] = [],
        environment: [String: String] = [:]
    ) {
        precondition(
            !type.requiresPath || path != nil,
            "Path is required for operation type \(type)"
        )

        self.identifier = identifier
        self.type = type.rawValue
        self.path = path
        self.arguments = arguments
        self.environment = environment
        timestamp = Date()
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard
            let identifier = coder.decodeObject(
    of: String.self,
    forKey: CodingKeys.identifier.rawValue
) as String?,
    
            let type = coder.decodeObject(
    of: String.self,
    forKey: CodingKeys.type.rawValue
) as String?,
    
            let arguments = coder.decodeObject(
    of: [Array.self,
    String.self],
    forKey: CodingKeys.arguments.rawValue
) as? [String],
    
            let environment = coder.decodeObject(
    of: [Dictionary.self,
    String.self],
    forKey: CodingKeys.environment.rawValue
) as? [String: String],
    
            let timestamp = coder.decodeObject(
    of: Date.self,
    forKey: CodingKeys.timestamp.rawValue
) as Date?
        else {
            return nil
        }

        self.identifier = identifier
        self.type = type
        path = coder.decodeObject(of: String.self, forKey: CodingKeys.path.rawValue) as String?
        self.arguments = arguments
        self.environment = environment
        self.timestamp = timestamp
        super.init()
    }

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

    private enum CodingKeys: String {
        case identifier
        case type
        case path
        case arguments
        case environment
        case timestamp
    }

    public func encode(with coder: NSCoder) {
        coder.encode(identifier, forKey: CodingKeys.identifier.rawValue)
        coder.encode(type, forKey: CodingKeys.type.rawValue)
        coder.encode(path, forKey: CodingKeys.path.rawValue)
        coder.encode(arguments, forKey: CodingKeys.arguments.rawValue)
        coder.encode(environment, forKey: CodingKeys.environment.rawValue)
        coder.encode(timestamp, forKey: CodingKeys.timestamp.rawValue)
    }
}

// MARK: - CustomStringConvertible

extension XPCServiceOperation: CustomStringConvertible {
    public var description: String {
        "\(type) operation [\(identifier)] at \(path ?? "none")"
    }
}

// MARK: - CustomDebugStringConvertible

extension XPCServiceOperation: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        XPCServiceOperation(
            identifier: \(identifier),
            type: \(type),
            path: \(path ?? "none"),
            arguments: [\(arguments.joined(separator: ", "))],
            environment: \(environment),
            timestamp: \(timestamp)
        )
        """
    }
}

// MARK: - XPCServiceResponse

/// Represents an XPC service operation result
@frozen
@Observable
@objc
public final class XPCServiceResponse: NSObject, NSSecureCoding, Sendable {
    // MARK: - Types

    /// Result status
    @frozen
    public enum Status: String, Sendable, CaseIterable, Comparable {
        case success
        case failure
        case cancelled

        /// Whether the status represents completion
        public var isComplete: Bool {
            switch self {
            case .success, .failure, .cancelled:
                true
            }
        }

        /// Whether the status represents success
        public var isSuccess: Bool {
            self == .success
        }

        /// Log level for status
        public var logLevel: Logger.Level {
            switch self {
            case .success:
                .info

            case .failure:
                .error

            case .cancelled:
                .warning
            }
        }

        /// Priority level for status
        public var priority: Int {
            switch self {
            case .success:
                0

            case .cancelled:
                1

            case .failure:
                2
            }
        }

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.priority < rhs.priority
        }
    }

    // MARK: - Properties

    /// Operation identifier
    @objc public let identifier: String

    /// Result data
    @objc public let data: Data

    /// Result error if any
    @objc public let error: Error?

    /// Result status
    @objc public let status: String

    /// Result timestamp
    @objc public let timestamp: Date

    // MARK: - Computed Properties

    /// Status as enum
    public var resultStatus: Status? {
        Status(rawValue: status)
    }

    /// Whether result represents success
    public var isSuccess: Bool {
        resultStatus?.isSuccess ?? false
    }

    /// Whether result is complete
    public var isComplete: Bool {
        resultStatus?.isComplete ?? false
    }

    /// Priority level for the result
    public var priority: Int {
        resultStatus?.priority ?? -1
    }

    /// Logging metadata
    public var loggingMetadata: Logger.Metadata {
        [
            "identifier": .string(identifier),
            "status": .string(status),
            "error": .string(error?.localizedDescription ?? "none"),
            "timestamp": .string(timestamp.description),
            "data_size": .string(String(data.count)),
            "priority": .string(String(priority))
        ]
    }

    // MARK: - Initialization

    /// Initialize with values
    /// - Parameters:
    ///   - identifier: Operation identifier
    ///   - data: Result data
    ///   - error: Result error
    ///   - status: Result status
    public init(
        identifier: String,
        data: Data = Data(),
        error: Error? = nil,
        status: Status = .success
    ) {
        self.identifier = identifier
        self.data = data
        self.error = error
        self.status = status.rawValue
        timestamp = Date()
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard
            let identifier = coder.decodeObject(
    of: String.self,
    forKey: CodingKeys.identifier.rawValue
) as String?,
    
            let data = coder.decodeObject(
    of: Data.self,
    forKey: CodingKeys.data.rawValue
) as Data?,
    
            let status = coder.decodeObject(
    of: String.self,
    forKey: CodingKeys.status.rawValue
) as String?,
    
            let timestamp = coder.decodeObject(
    of: Date.self,
    forKey: CodingKeys.timestamp.rawValue
) as Date?
        else {
            return nil
        }

        self.identifier = identifier
        self.data = data
        self.status = status
        if let errorString = coder.decodeObject(
    of: String.self,
    forKey: CodingKeys.error.rawValue
) as String? {
            error = XPCServiceError.operationFailed(reason: errorString)
        } else {
            error = nil
        }
        self.timestamp = timestamp
        super.init()
    }

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

    private enum CodingKeys: String {
        case identifier
        case data
        case error
        case status
        case timestamp
    }

    public func encode(with coder: NSCoder) {
        coder.encode(identifier, forKey: CodingKeys.identifier.rawValue)
        coder.encode(data, forKey: CodingKeys.data.rawValue)
        coder.encode(error?.localizedDescription, forKey: CodingKeys.error.rawValue)
        coder.encode(status, forKey: CodingKeys.status.rawValue)
        coder.encode(timestamp, forKey: CodingKeys.timestamp.rawValue)
    }
}

// MARK: - CustomStringConvertible

extension XPCServiceResponse: CustomStringConvertible {
    public var description: String {
        "\(status) result [\(identifier)] with \(data.count) bytes"
    }
}

// MARK: - CustomDebugStringConvertible

extension XPCServiceResponse: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        XPCServiceResponse(
            identifier: \(identifier),
            status: \(status),
            data: \(data.count) bytes,
            error: \(error?.localizedDescription ?? "none"),
            timestamp: \(timestamp)
        )
        """
    }
}
