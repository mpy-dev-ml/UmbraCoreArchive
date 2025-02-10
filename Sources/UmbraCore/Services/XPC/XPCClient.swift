import Foundation

// MARK: - XPCClient

/// Client for communicating with XPC service
public final class XPCClient {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with configuration
    /// - Parameters:
    ///   - configuration: Client configuration
    ///   - logger: Operation logger
    ///   - performanceMonitor: Performance tracking
    public init(
        configuration: Configuration = .default,
        logger: LoggerProtocol,
        performanceMonitor: PerformanceMonitor
    ) {
        self.configuration = configuration
        self.logger = logger
        self.performanceMonitor = performanceMonitor
    }

    deinit {
        disconnect()
    }

    // MARK: Public

    // MARK: - Types

    /// Configuration for XPC client
    public struct Configuration {
        // MARK: Lifecycle

        /// Initialize with values
        /// - Parameters:
        ///   - serviceName: Name of service
        ///   - interfaceProtocol: Interface protocol
        ///   - connectionTimeout: Connection timeout
        ///   - validateAuditSession: Validate sessions
        public init(
            serviceName: String,
            interfaceProtocol: Protocol,
            connectionTimeout: TimeInterval = 30,
            validateAuditSession: Bool = true
        ) {
            self.serviceName = serviceName
            self.interfaceProtocol = interfaceProtocol
            self.connectionTimeout = connectionTimeout
            self.validateAuditSession = validateAuditSession
        }

        // MARK: Public

        /// Default configuration
        public static let `default`: Configuration = .init(
            serviceName: "dev.mpy.umbra.xpc-service",
            interfaceProtocol: XPCServiceProtocol.self,
            connectionTimeout: 30,
            validateAuditSession: true
        )

        /// Service name
        public let serviceName: String

        /// Interface protocol
        public let interfaceProtocol: Protocol

        /// Connection timeout
        public let connectionTimeout: TimeInterval

        /// Whether to validate audit sessions
        public let validateAuditSession: Bool
    }

    // MARK: - Public Methods

    /// Connect to service
    public func connect() async throws {
        try await queue.sync(flags: .barrier) {
            guard connection == nil else {
                return
            }

            // Create connection
            let connection = NSXPCConnection(
                machServiceName: configuration.serviceName
            )

            // Configure connection
            connection.remoteObjectInterface = NSXPCInterface(
                with: configuration.interfaceProtocol
            )

            if configuration.validateAuditSession {
                connection.auditSessionIdentifier = au_session_self()
            }

            // Set up handlers
            connection.invalidationHandler = { [weak self] in
                self?.handleConnectionInvalidation()
            }

            connection.interruptionHandler = { [weak self] in
                self?.handleConnectionInterruption()
            }

            // Resume connection
            connection.resume()

            self.connection = connection

            logger.info(
                "Connected to XPC service",
                config: LogConfig(
                    metadata: ["service": configuration.serviceName]
                )
            )

            // Validate connection
            try await validateConnection()
        }
    }

    /// Disconnect from service
    public func disconnect() {
        queue.sync(flags: .barrier) {
            connection?.invalidate()
            connection = nil

            logger.info(
                "Disconnected from XPC service",
                config: LogConfig(
                    metadata: ["service": configuration.serviceName]
                )
            )
        }
    }

    /// Execute command
    /// - Parameters:
    ///   - command: Command to execute
    ///   - arguments: Command arguments
    ///   - environment: Environment variables
    ///   - workingDirectory: Working directory
    /// - Returns: Command result data
    public func executeCommand(
        _ command: String,
        arguments: [String] = [],
        environment: [String: String] = [:],
        workingDirectory: String
    ) async throws -> Data {
        try await performanceMonitor.trackDuration(
            "xpc_command_execution",
            metadata: [
                "command": command,
                "working_directory": workingDirectory,
            ]
        ) {
            guard let proxy = try await serviceProxy else {
                throw XPCError.connectionInvalid(
                    reason: "No service proxy available"
                )
            }

            return try await proxy.executeCommand(
                command,
                arguments: arguments,
                environment: environment,
                workingDirectory: workingDirectory
            )
        }
    }

    /// Read file
    /// - Parameters:
    ///   - path: File path
    ///   - bookmark: Security bookmark
    /// - Returns: File data
    public func readFile(
        at path: String,
        bookmark: Data? = nil
    ) async throws -> Data {
        try await performanceMonitor.trackDuration(
            "xpc_file_read",
            metadata: ["path": path]
        ) {
            guard let proxy = try await serviceProxy else {
                throw XPCError.connectionInvalid(
                    reason: "No service proxy available"
                )
            }

            return try await proxy.readFile(
                at: path,
                bookmark: bookmark
            )
        }
    }

    /// Write file
    /// - Parameters:
    ///   - data: Data to write
    ///   - path: File path
    ///   - bookmark: Security bookmark
    public func writeFile(
        _ data: Data,
        to path: String,
        bookmark: Data? = nil
    ) async throws {
        try await performanceMonitor.trackDuration(
            "xpc_file_write",
            metadata: ["path": path]
        ) {
            guard let proxy = try await serviceProxy else {
                throw XPCError.connectionInvalid(
                    reason: "No service proxy available"
                )
            }

            try await proxy.writeFile(
                data,
                to: path,
                bookmark: bookmark
            )
        }
    }

    // MARK: Private

    /// Client configuration
    private let configuration: Configuration

    /// Logger for operations
    private let logger: LoggerProtocol

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    /// Connection to service
    private var connection: NSXPCConnection?

    /// Queue for synchronising access
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbra.xpc-client",
        attributes: .concurrent
    )

    /// Service proxy
    private var serviceProxy: XPCServiceProtocol? {
        get async throws {
            try await withCheckedThrowingContinuation { continuation in
                queue.async { [weak self] in
                    guard let self else {
                        continuation.resume(
                            throwing: XPCError.connectionInvalid(
                                reason: "Client deallocated"
                            )
                        )
                        return
                    }

                    do {
                        let proxy = try getServiceProxy()
                        continuation.resume(returning: proxy)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}

// MARK: - Private Methods

private extension XPCClient {
    /// Get service proxy
    /// - Returns: Service proxy
    func getServiceProxy() throws -> XPCServiceProtocol? {
        guard let connection else {
            throw XPCError.connectionInvalid(
                reason: "No connection available"
            )
        }

        return connection.remoteObjectProxy as? XPCServiceProtocol
    }

    /// Validate connection
    func validateConnection() async throws {
        guard let proxy = try await serviceProxy else {
            throw XPCError.connectionInvalid(
                reason: "No service proxy available"
            )
        }

        try await proxy.validate()
    }

    /// Handle connection invalidation
    func handleConnectionInvalidation() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else {
                return
            }

            connection = nil

            logger.warning(
                "XPC connection invalidated",
                config: LogConfig(
                    metadata: ["service": configuration.serviceName]
                )
            )
        }
    }

    /// Handle connection interruption
    func handleConnectionInterruption() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else {
                return
            }

            connection = nil

            logger.warning(
                "XPC connection interrupted",
                config: LogConfig(
                    metadata: ["service": configuration.serviceName]
                )
            )
        }
    }
}
