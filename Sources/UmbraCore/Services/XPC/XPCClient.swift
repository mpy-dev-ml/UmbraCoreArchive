import Foundation
import Logging

// MARK: - XPCClient

/// Client for communicating with XPC service
public actor XPCClient {
    // MARK: - Types

    /// Configuration for XPC client
    @frozen
    public struct Configuration: Sendable {
        /// Default configuration
        public static let `default`: Configuration = .init(
            serviceName: "dev.mpy.umbra.xpc-service",
            interfaceProtocol: XPCServiceProtocol.self,
            connectionTimeout: 30,
            validateAuditSession: true,
            maxRetries: 3
        )

        /// Service name
        public let serviceName: String
        /// Interface protocol
        public let interfaceProtocol: Protocol
        /// Connection timeout
        public let connectionTimeout: TimeInterval
        /// Whether to validate audit sessions
        public let validateAuditSession: Bool
        /// Maximum number of retries
        public let maxRetries: Int

        /// Initialize with values
        /// - Parameters:
        ///   - serviceName: Name of service
        ///   - interfaceProtocol: Interface protocol
        ///   - connectionTimeout: Connection timeout
        ///   - validateAuditSession: Validate sessions
        ///   - maxRetries: Maximum retries
        public init(
            serviceName: String,
            interfaceProtocol: Protocol,
            connectionTimeout: TimeInterval = 30,
            validateAuditSession: Bool = true,
            maxRetries: Int = 3
        ) {
            self.serviceName = serviceName
            self.interfaceProtocol = interfaceProtocol
            self.connectionTimeout = connectionTimeout
            self.validateAuditSession = validateAuditSession
            self.maxRetries = maxRetries
        }
    }

    // MARK: - Properties

    /// Client configuration
    private let configuration: Configuration
    /// Logger for operations
    private let logger: LoggerProtocol
    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor
    /// Connection to service
    private var connection: NSXPCConnection?
    /// Connection state
    @Published private(set) var connectionState: XPCConnectionState = .disconnected
    /// Retry count
    private var retryCount: Int = 0

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
        Task { await disconnect() }
    }

    // MARK: - Public Methods

    /// Connect to service
    /// - Throws: XPCError if connection fails
    public func connect() async throws {
        guard connection == nil else { return }

        connectionState = .connecting

        do {
            // Create connection
            let connection = NSXPCConnection(
                machServiceName: configuration.serviceName
            )

            // Configure connection
            connection.remoteObjectInterface = NSXPCInterface(
                with: configuration.interfaceProtocol
            )

            if configuration.validateAuditSession {
                try await configureAuditSession(for: connection)
            }

            // Set up handlers
            connection.invalidationHandler = { [weak self] in
                Task { await self?.handleConnectionInvalidation() }
            }

            connection.interruptionHandler = { [weak self] in
                Task { await self?.handleConnectionInterruption() }
            }

            // Resume connection
            connection.resume()

            self.connection = connection
            connectionState = .connected
            retryCount = 0

            logger.info(
                "Connected to XPC service",
                metadata: [
                    "service": .string(configuration.serviceName),
                    "state": .string(connectionState.description)
                ]
            )

            // Validate connection
            try await validateConnection()
        } catch {
            connectionState = .error
            throw XPCError.serviceUnavailable(reason: error.localizedDescription)
        }
    }

    /// Disconnect from service
    public func disconnect() {
        connectionState = .disconnecting

        connection?.invalidate()
        connection = nil

        connectionState = .disconnected

        logger.info(
            "Disconnected from XPC service",
            metadata: [
                "service": .string(configuration.serviceName),
                "state": .string(connectionState.description)
            ]
        )
    }

    /// Execute command
    /// - Parameters:
    ///   - command: Command to execute
    ///   - arguments: Command arguments
    ///   - environment: Environment variables
    ///   - workingDirectory: Working directory
    /// - Returns: Command result data
    /// - Throws: XPCError if command execution fails
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
                "state": connectionState.description
            ]
        ) {
            let proxy = try await getServiceProxy()
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
    /// - Throws: XPCError if file read fails
    public func readFile(
        at path: String,
        bookmark: Data? = nil
    ) async throws -> Data {
        try await performanceMonitor.trackDuration(
            "xpc_file_read",
            metadata: [
                "path": path,
                "state": connectionState.description
            ]
        ) {
            let proxy = try await getServiceProxy()
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
    /// - Throws: XPCError if file write fails
    public func writeFile(
        _ data: Data,
        to path: String,
        bookmark: Data? = nil
    ) async throws {
        try await performanceMonitor.trackDuration(
            "xpc_file_write",
            metadata: [
                "path": path,
                "state": connectionState.description
            ]
        ) {
            let proxy = try await getServiceProxy()
            try await proxy.writeFile(
                data,
                to: path,
                bookmark: bookmark
            )
        }
    }

    // MARK: - Private Methods

    /// Configure audit session for connection
    /// - Parameter connection: XPC connection
    /// - Throws: XPCError if configuration fails
    private func configureAuditSession(
        for connection: NSXPCConnection
    ) async throws {
        // Get current audit session ID from process
        let sessionId = getpid()

        // Create an audit session identifier
        var auditToken = audit_token_t()
        withUnsafeMutableBytes(of: &auditToken) { tokenBytes in
            tokenBytes[5] = UInt32(sessionId)
        }

        connection.auditSessionIdentifier = auditToken

        logger.debug(
            "Configured audit session",
            metadata: ["session_id": .string(String(sessionId))]
        )
    }

    /// Handle connection invalidation
    private func handleConnectionInvalidation() {
        connection = nil
        connectionState = .invalidated

        logger.error(
            "XPC connection invalidated",
            metadata: ["service": .string(configuration.serviceName)]
        )
    }

    /// Handle connection interruption
    private func handleConnectionInterruption() {
        connectionState = .interrupted

        logger.warning(
            "XPC connection interrupted",
            metadata: ["service": .string(configuration.serviceName)]
        )

        Task {
            await attemptReconnection()
        }
    }

    /// Attempt to reconnect to service
    private func attemptReconnection() async {
        guard retryCount < configuration.maxRetries else {
            connectionState = .invalidated
            logger.error("Max reconnection attempts reached")
            return
        }

        retryCount += 1

        logger.info(
            "Attempting reconnection",
            metadata: ["attempt": .string(String(retryCount))]
        )

        do {
            try await connect()
        } catch {
            logger.error(
                "Reconnection failed",
                metadata: ["error": .string(error.localizedDescription)]
            )

            if retryCount < configuration.maxRetries {
                try? await Task.sleep(nanoseconds: UInt64(1_000_000_000))
                await attemptReconnection()
            }
        }
    }

    /// Get service proxy
    /// - Returns: Service proxy
    /// - Throws: XPCError if proxy unavailable
    private func getServiceProxy() async throws -> XPCServiceProtocol {
        guard let connection else {
            throw XPCError.notConnected(reason: "No active connection")
        }

        guard let proxy = connection.remoteObjectProxy as? XPCServiceProtocol else {
            throw XPCError.invalidProxy(reason: "Invalid proxy object")
        }

        return proxy
    }

    /// Validate connection
    /// - Throws: XPCError if validation fails
    private func validateConnection() async throws {
        guard let connection else {
            throw XPCError.notConnected(reason: "No active connection")
        }

        guard connection.isValid else {
            throw XPCError.invalidState(reason: "Connection is invalid")
        }
    }
}

// MARK: - XPCConnectionState

public enum XPCConnectionState: String, CaseIterable {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case interrupted
    case invalidated
    case error

    public var description: String {
        switch self {
        case .disconnected:
            "Disconnected"

        case .connecting:
            "Connecting"

        case .connected:
            "Connected"

        case .disconnecting:
            "Disconnecting"

        case .interrupted:
            "Interrupted"

        case .invalidated:
            "Invalidated"

        case .error:
            "Error"
        }
    }
}
