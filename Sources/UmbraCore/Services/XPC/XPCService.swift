import Foundation
import Logging

// MARK: - XPCService

/// XPC service class for managing XPC connections
@Observable
@MainActor
public final class XPCService {
    // MARK: - Types

    /// Error reasons specific to XPC operations
    @frozen
    @Error
    public enum ServiceError: LocalizedError, CustomDebugStringConvertible {
        @ErrorCase("Service instance was deallocated")
        case serviceInstanceDeallocated

        @ErrorCase("Cannot connect while in state: {state}")
        case invalidConnectionState(state: XPCConnectionState)

        @ErrorCase("No active connection available")
        case noActiveConnection

        @ErrorCase("Failed to cast proxy to type: {type}")
        case invalidProxyType(type: Any.Type)

        @ErrorCase("Maximum retry attempts exceeded")
        case maxRetryAttemptsExceeded

        @ErrorCase("Operation timed out after {seconds} seconds")
        case operationTimeout(seconds: TimeInterval)

        @ErrorCase("Connection validation failed: {reason}")
        case validationFailed(reason: String)

        @ErrorCase("Connection was interrupted")
        case connectionInterrupted

        @ErrorCase("Connection was invalidated")
        case connectionInvalidated

        public var errorDescription: String? {
            switch self {
            case .serviceInstanceDeallocated:
                "The XPC service instance was deallocated"

            case let .invalidConnectionState(state):
                "Cannot perform operation while in state: \(state)"

            case .noActiveConnection:
                "No active XPC connection available"

            case let .invalidProxyType(type):
                "Failed to cast proxy to type: \(type)"

            case .maxRetryAttemptsExceeded:
                "Maximum connection retry attempts exceeded"

            case let .operationTimeout(seconds):
                "Operation timed out after \(seconds) seconds"

            case let .validationFailed(reason):
                "Connection validation failed: \(reason)"

            case .connectionInterrupted:
                "XPC connection was interrupted"

            case .connectionInvalidated:
                "XPC connection was invalidated"
            }
        }

        public var debugDescription: String {
            "XPCServiceError: \(errorDescription ?? "Unknown error")"
        }

        /// Whether the error is recoverable
        public var isRecoverable: Bool {
            switch self {
            case .serviceInstanceDeallocated, .maxRetryAttemptsExceeded:
                false
            case .invalidConnectionState, .noActiveConnection,
                 .invalidProxyType, .operationTimeout,
                 .validationFailed, .connectionInterrupted,
                 .connectionInvalidated:
                true
            }
        }

        /// Log level for the error
        public var logLevel: Logger.Level {
            switch self {
            case .serviceInstanceDeallocated, .maxRetryAttemptsExceeded:
                .critical

            case .invalidConnectionState, .noActiveConnection,
                 .invalidProxyType, .operationTimeout,
                 .validationFailed:
                .error

            case .connectionInterrupted, .connectionInvalidated:
                .warning
            }
        }
    }

    // MARK: - Properties

    /// Current connection state
    @Published
    private(set) var connectionState: XPCConnectionState = .disconnected {
        didSet {
            if oldValue != connectionState {
                logStateChange(oldValue, connectionState)
            }
        }
    }

    /// Number of retry attempts made
    @Published
    private(set) var retryCount: Int = 0

    /// Whether the service is connected
    public var isConnected: Bool {
        connectionState == .connected
    }

    /// Whether the service is attempting to connect
    public var isConnecting: Bool {
        connectionState == .connecting
    }

    /// Whether the service can attempt reconnection
    public var canReconnect: Bool {
        configuration.autoReconnect && retryCount < configuration.maxRetryAttempts
    }

    // MARK: - Private Properties

    private let configuration: XPCConfiguration
    private let queue: DispatchQueue
    private let logger: any LoggerProtocol
    private let healthMonitor: XPCHealthMonitor

    private var connection: NSXPCConnection?
    private var connectionTask: Task<Void, Error>?

    // MARK: - Initialization

    public init(
        configuration: XPCConfiguration,
        queue: DispatchQueue = .main,
        logger: any LoggerProtocol = Logger(label: "dev.mpy.umbra.xpc-service")
    ) {
        precondition(configuration.isValid, "Invalid XPC configuration")
        self.configuration = configuration
        self.queue = queue
        self.logger = logger
        healthMonitor = XPCHealthMonitor(logger: logger)
    }

    deinit {
        disconnect()
    }

    // MARK: - Public Methods

    /// Connect to the XPC service
    /// - Throws: ServiceError if connection fails
    public func connect() async throws {
        try await performConnect()
    }

    /// Disconnect from the XPC service
    public func disconnect() {
        performDisconnect()
    }

    /// Get remote proxy object
    /// - Returns: Remote proxy of type T
    /// - Throws: ServiceError if proxy creation fails
    public func remoteProxy<T>() async throws -> T {
        try await createRemoteProxy()
    }

    /// Reset connection state and retry count
    public func reset() {
        connectionTask?.cancel()
        connectionTask = nil
        connection = nil
        connectionState = .disconnected
        retryCount = 0
        healthMonitor.stopMonitoring()
    }
}

// MARK: - Connection Management

extension XPCService {
    /// Perform connection setup and validation
    private func performConnect() async throws {
        guard !Task.isCancelled else {
            throw ServiceError.serviceInstanceDeallocated
        }

        try validateConnectionState()

        connectionTask = Task {
            try await setupConnection()
        }

        try await connectionTask?.value
        retryCount = 0
    }

    /// Setup and establish connection
    private func setupConnection() async throws {
        connectionState = .connecting

        let connection = try createConnection()
        try await validateConnection(connection)

        self.connection = connection
        connectionState = .connected

        healthMonitor.startMonitoring(connection)
        logConnectionEstablished()
    }

    /// Validate current connection state
    private func validateConnectionState() throws {
        guard connectionState == .disconnected else {
            throw ServiceError.invalidConnectionState(state: connectionState)
        }
    }

    /// Create and configure a new XPC connection
    private func createConnection() throws -> NSXPCConnection {
        let connection = NSXPCConnection(serviceName: configuration.serviceName)
        configureConnection(connection)
        connection.resume()
        return connection
    }

    /// Configure connection settings and handlers
    private func configureConnection(_ connection: NSXPCConnection) {
        configureAuditSession(connection)
        configureInterface(connection)
        configureHandlers(connection)
    }

    /// Configure audit session if needed
    private func configureAuditSession(_ connection: NSXPCConnection) {
        if configuration.validateAuditSession {
            connection.auditSessionIdentifier = au_session_self()
        }
    }

    /// Configure remote object interface
    private func configureInterface(_ connection: NSXPCConnection) {
        connection.remoteObjectInterface = NSXPCInterface(
            with: configuration.interfaceProtocol
        )
    }

    /// Configure connection handlers
    private func configureHandlers(_ connection: NSXPCConnection) {
        connection.interruptionHandler = { [weak self] in
            Task { @MainActor [weak self] in
                self?.handleInterruption()
            }
        }

        connection.invalidationHandler = { [weak self] in
            Task { @MainActor [weak self] in
                self?.handleInvalidation()
            }
        }
    }

    /// Validate connection is working
    private func validateConnection(_ connection: NSXPCConnection) async throws {
        try await withTimeout(configuration.connectionTimeout) {
            guard let proxy = connection.remoteObjectProxy as? XPCServiceProtocol else {
                throw ServiceError.validationFailed(reason: "Failed to create proxy")
            }

            try await proxy.ping()
            return true
        }
    }

    /// Perform disconnection cleanup
    private func performDisconnect() {
        guard connectionState == .connected else { return }

        connectionState = .disconnecting
        cleanupConnection()
        connectionState = .disconnected
    }

    /// Cleanup connection resources
    private func cleanupConnection() {
        healthMonitor.stopMonitoring()
        connection?.invalidate()
        connection = nil
        connectionTask?.cancel()
        connectionTask = nil
        logDisconnection()
    }

    /// Create remote proxy object
    private func createRemoteProxy<T>() async throws -> T {
        guard !Task.isCancelled else {
            throw ServiceError.serviceInstanceDeallocated
        }

        try validateProxyCreation()

        let errorHandler = { [weak self] (error: Error) in
            Task { @MainActor [weak self] in
                self?.handleConnectionError(error)
            }
        }

        guard let proxy = connection?.remoteObjectProxyWithErrorHandler(
            errorHandler
        ) as? T else {
            throw ServiceError.invalidProxyType(type: T.self)
        }

        return proxy
    }

    /// Validate connection state for proxy creation
    private func validateProxyCreation() throws {
        guard let connection,
              connectionState == .connected
        else {
            throw ServiceError.noActiveConnection
        }
    }
}

// MARK: - Error Handling

extension XPCService {
    /// Handle connection interruption
    private func handleInterruption() {
        logInterruption()
        if configuration.autoReconnect {
            Task {
                try await reconnect()
            }
        } else {
            cleanupConnection()
            throw ServiceError.connectionInterrupted
        }
    }

    /// Handle connection invalidation
    private func handleInvalidation() {
        logInvalidation()
        cleanupConnection()
        throw ServiceError.connectionInvalidated
    }

    /// Handle connection errors
    private func handleConnectionError(_ error: Error) {
        logConnectionError(error)
        if configuration.autoReconnect {
            Task {
                try await reconnect()
            }
        } else {
            cleanupConnection()
        }
    }

    /// Attempt to reconnect to the service
    private func reconnect() async throws {
        guard canReconnect else {
            throw ServiceError.maxRetryAttemptsExceeded
        }

        retryCount += 1
        logReconnectionAttempt()

        try await Task.sleep(for: .seconds(configuration.retryDelay))
        try await connect()
    }
}

// MARK: - Logging

extension XPCService {
    /// Log successful connection
    private func logConnectionEstablished() {
        logger.info(
            "Connected to XPC service",
            metadata: createConnectionMetadata()
        )
    }

    /// Log disconnection
    private func logDisconnection() {
        logger.info(
            "Disconnected from XPC service",
            metadata: createConnectionMetadata()
        )
    }

    /// Log connection interruption
    private func logInterruption() {
        logger.warning(
            "XPC connection interrupted",
            metadata: createInterruptionMetadata()
        )
    }

    /// Log connection invalidation
    private func logInvalidation() {
        logger.error(
            "XPC connection invalidated",
            metadata: createConnectionMetadata()
        )
    }

    /// Log connection error
    private func logConnectionError(_ error: Error) {
        logger.error(
            "XPC connection error",
            metadata: createErrorMetadata(error)
        )
    }

    /// Log reconnection attempt
    private func logReconnectionAttempt() {
        logger.info(
            "Attempting to reconnect to XPC service",
            metadata: createReconnectionMetadata()
        )
    }

    /// Create base connection metadata
    private func createConnectionMetadata() -> Logger.Metadata {
        [
            "service": .string(configuration.serviceName),
            "state": .string(connectionState.description),
            "retry_count": .string(String(retryCount)),
            "auto_reconnect": .string(String(configuration.autoReconnect))
        ]
    }

    /// Create interruption metadata
    private func createInterruptionMetadata() -> Logger.Metadata {
        createConnectionMetadata().merging([
            "can_reconnect": .string(String(canReconnect))
        ]) { $1 }
    }

    /// Create error metadata
    private func createErrorMetadata(_ error: Error) -> Logger.Metadata {
        createConnectionMetadata().merging([
            "error": .string(String(describing: error)),
            "error_type": .string(String(describing: type(of: error)))
        ]) { $1 }
    }

    /// Create reconnection metadata
    private func createReconnectionMetadata() -> Logger.Metadata {
        createConnectionMetadata().merging([
            "attempt": .string(String(retryCount)),
            "max_attempts": .string(String(configuration.maxRetryAttempts)),
            "retry_delay": .string(String(configuration.retryDelay))
        ]) { $1 }
    }
}

// MARK: - State Management

extension XPCService {
    /// Log state change
    private func logStateChange(
        _ oldState: XPCConnectionState,
        _ newState: XPCConnectionState
    ) {
        logger.debug(
            "XPC connection state changed",
            metadata: createStateChangeMetadata(oldState, newState)
        )
        notifyStateChange(oldState, newState)
    }

    /// Notify observers of state change
    private func notifyStateChange(
        _ oldState: XPCConnectionState,
        _ newState: XPCConnectionState
    ) {
        NotificationCenter.default.post(
            name: .xpcConnectionStateChanged,
            object: self,
            userInfo: createStateChangeUserInfo(oldState, newState)
        )
    }

    /// Create state change metadata
    private func createStateChangeMetadata(
        _ oldState: XPCConnectionState,
        _ newState: XPCConnectionState
    ) -> Logger.Metadata {
        createConnectionMetadata().merging([
            "old_state": .string(oldState.description),
            "new_state": .string(newState.description)
        ]) { $1 }
    }

    /// Create state change notification user info
    private func createStateChangeUserInfo(
        _ oldState: XPCConnectionState,
        _ newState: XPCConnectionState
    ) -> [String: Any] {
        [
            "old_state": oldState,
            "new_state": newState,
            "service": configuration.serviceName,
            "retry_count": retryCount,
            "can_reconnect": canReconnect,
            "timestamp": Date()
        ]
    }
}

// MARK: - Timeout Utility

extension XPCService {
    /// Execute task with timeout
    private func withTimeout<T>(
        _ seconds: TimeInterval,
        operation: () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask { try await self.timeoutTask(seconds) }

            let result = try await group.next()
            group.cancelAll()

            return try result ?? {
                throw ServiceError.operationTimeout(seconds: seconds)
            }()
        }
    }

    /// Create timeout task
    private func timeoutTask<T>(_ seconds: TimeInterval) async throws -> T {
        try await Task.sleep(for: .seconds(seconds))
        throw ServiceError.operationTimeout(seconds: seconds)
    }
}

// MARK: - Notifications

public extension Notification.Name {
    /// Posted when XPC connection state changes
    static let xpcConnectionStateChanged = Notification.Name(
        "dev.mpy.umbra.xpc.connectionStateChanged"
    )
}
