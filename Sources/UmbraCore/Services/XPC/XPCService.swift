@preconcurrency import Foundation
import os.log

// MARK: - XPCService

/// XPC service class for managing XPC connections
class XPCService {
    // MARK: Lifecycle

    init(
        configuration: XPCConfiguration,
        queue: DispatchQueue = .main,
        logger: Logger = Logger(subsystem: "com.umbra.core", category: "XPCService")
    ) {
        self.configuration = configuration
        self.queue = queue
        self.logger = logger
        healthMonitor = XPCHealthMonitor(logger: logger)
    }

    deinit {
        disconnect()
    }

    // MARK: Internal

    /// Connect to the XPC service
    func connect() async throws {
        try await performConnect()
    }

    /// Disconnect from the XPC service
    func disconnect() {
        performDisconnect()
    }

    /// Get remote proxy object
    func remoteProxy<T>() throws -> T {
        try createRemoteProxy()
    }

    // MARK: Private

    private let configuration: XPCConfiguration
    private let queue: DispatchQueue
    private let logger: Logger
    private let healthMonitor: XPCHealthMonitor

    private var connection: NSXPCConnection?
    private var retryCount: Int = 0

    private var connectionState: XPCConnectionState = .disconnected {
        willSet {
            handleConnectionStateChange(from: connectionState, to: newValue)
        }
    }
}

// MARK: - Connection Management

private extension XPCService {
    /// Perform connection setup and validation
    func performConnect() async throws {
        guard let self else {
            throw XPCError.serviceUnavailable(
                reason: .serviceInstanceDeallocated
            )
        }

        try validateConnectionState()
        try await setupConnection()
        retryCount = 0
    }

    /// Setup and establish connection
    private func setupConnection() async throws {
        connectionState = .connecting

        let connection = try createConnection()
        try await waitForConnection(connection)

        self.connection = connection
        connectionState = .connected

        healthMonitor.startMonitoring(connection)
        logConnectionEstablished()
    }

    /// Validate current connection state
    func validateConnectionState() throws {
        guard connectionState == .disconnected else {
            throw XPCError.invalidState(
                reason: .invalidConnectionState(connectionState)
            )
        }
    }

    /// Create and configure a new XPC connection
    func createConnection() throws -> NSXPCConnection {
        let connection = NSXPCConnection(
            serviceName: configuration.serviceName
        )

        configureConnection(connection)
        connection.resume()

        return connection
    }

    /// Configure connection settings and handlers
    func configureConnection(_ connection: NSXPCConnection) {
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
            self?.handleInterruption()
        }

        connection.invalidationHandler = { [weak self] in
            self?.handleInvalidation()
        }
    }

    /// Wait for connection to establish
    func waitForConnection(
        _: NSXPCConnection
    ) async throws {
        try await withTimeout(configuration.connectionTimeout) {
            // Implement connection verification
            // This could ping the service or check a status
            true
        }
    }

    /// Perform disconnection cleanup
    func performDisconnect() {
        guard let self,
              connectionState == .connected
        else {
            return
        }

        connectionState = .disconnecting
        cleanupConnection()
        connectionState = .disconnected
    }

    /// Cleanup connection resources
    private func cleanupConnection() {
        healthMonitor.stopMonitoring()

        connection?.invalidate()
        connection = nil

        logDisconnection()
    }

    /// Create remote proxy object
    func createRemoteProxy<T>() throws -> T {
        guard let self else {
            throw XPCError.serviceUnavailable(
                reason: .serviceInstanceDeallocated
            )
        }

        try validateProxyCreation()

        let errorHandler = { [weak self] (error: Error) in
            self?.handleConnectionError(error)
        }

        guard let proxy = connection?.remoteObjectProxyWithErrorHandler(
            errorHandler
        ) as? T else {
            throw XPCError.invalidProxy(
                reason: .invalidProxyType(T.self)
            )
        }

        return proxy
    }

    /// Validate connection state for proxy creation
    func validateProxyCreation() throws {
        guard let connection,
              connectionState == .connected
        else {
            throw XPCError.notConnected(
                reason: .noActiveConnection
            )
        }
    }
}

// MARK: - Error Handling

private extension XPCService {
    /// Handle connection interruption
    func handleInterruption() {
        queue.async { [weak self] in
            guard let self else {
                return
            }
            logInterruption()
            if configuration.autoReconnect {
                Task { try await self.reconnect() }
            }
        }
    }

    /// Handle connection invalidation
    func handleInvalidation() {
        queue.async { [weak self] in
            guard let self else {
                return
            }
            logInvalidation()
            connection = nil
            connectionState = .disconnected
        }
    }

    /// Handle connection errors
    func handleConnectionError(_ error: Error) {
        queue.async { [weak self] in
            guard let self else {
                return
            }
            logConnectionError(error)
            if configuration.autoReconnect {
                Task { try await self.reconnect() }
            }
        }
    }

    /// Attempt to reconnect to the service
    func reconnect() async throws {
        guard retryCount < configuration.maxRetryAttempts else {
            throw XPCError.reconnectionFailed(
                reason: .maxRetryAttemptsExceeded
            )
        }

        retryCount += 1
        logReconnectionAttempt()

        try await Task.sleep(
            nanoseconds: UInt64(configuration.retryDelay * 1_000_000_000)
        )

        try await connect()
    }
}

// MARK: - Logging

private extension XPCService {
    /// Log successful connection
    func logConnectionEstablished() {
        logger.info(
            "Connected to XPC service",
            metadata: createConnectionMetadata()
        )
    }

    /// Log disconnection
    func logDisconnection() {
        logger.info(
            "Disconnected from XPC service",
            metadata: createConnectionMetadata()
        )
    }

    /// Log connection interruption
    func logInterruption() {
        logger.warning(
            "XPC connection interrupted",
            metadata: createInterruptionMetadata()
        )
    }

    /// Log connection invalidation
    func logInvalidation() {
        logger.error(
            "XPC connection invalidated",
            metadata: createConnectionMetadata()
        )
    }

    /// Log connection error
    func logConnectionError(_ error: Error) {
        logger.error(
            "XPC connection error",
            metadata: createErrorMetadata(error)
        )
    }

    /// Log reconnection attempt
    func logReconnectionAttempt() {
        logger.info(
            "Attempting to reconnect to XPC service",
            metadata: createReconnectionMetadata()
        )
    }

    /// Create base connection metadata
    func createConnectionMetadata() -> [String: String] {
        [
            "service": configuration.serviceName,
            "state": connectionState.description
        ]
    }

    /// Create interruption metadata
    func createInterruptionMetadata() -> [String: String] {
        [
            "service": configuration.serviceName,
            "retry_count": String(retryCount)
        ]
    }

    /// Create error metadata
    func createErrorMetadata(_ error: Error) -> [String: String] {
        [
            "service": configuration.serviceName,
            "error": String(describing: error)
        ]
    }

    /// Create reconnection metadata
    func createReconnectionMetadata() -> [String: String] {
        [
            "service": configuration.serviceName,
            "attempt": String(retryCount),
            "max_attempts": String(configuration.maxRetryAttempts)
        ]
    }
}

// MARK: - State Management

private extension XPCService {
    /// Handle connection state changes
    func handleConnectionStateChange(
        from oldState: XPCConnectionState,
        to newState: XPCConnectionState
    ) {
        logStateChange(oldState, newState)
        notifyStateChange(oldState, newState)
    }

    /// Log state change
    func logStateChange(
        _ oldState: XPCConnectionState,
        _ newState: XPCConnectionState
    ) {
        logger.debug(
            "XPC connection state changed",
            metadata: createStateChangeMetadata(oldState, newState)
        )
    }

    /// Notify observers of state change
    func notifyStateChange(
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
    func createStateChangeMetadata(
        _ oldState: XPCConnectionState,
        _ newState: XPCConnectionState
    ) -> [String: String] {
        [
            "old_state": oldState.description,
            "new_state": newState.description,
            "service": configuration.serviceName
        ]
    }

    /// Create state change notification user info
    func createStateChangeUserInfo(
        _ oldState: XPCConnectionState,
        _ newState: XPCConnectionState
    ) -> [String: Any] {
        [
            "old_state": oldState,
            "new_state": newState,
            "service": configuration.serviceName
        ]
    }
}

// MARK: - Timeout Utility

private extension XPCService {
    /// Execute task with timeout
    func withTimeout<T>(
        _ seconds: TimeInterval,
        operation: () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask { try await self.timeoutTask(seconds) }

            let result = try await group.next()
            group.cancelAll()

            return try result ?? {
                throw XPCError.timeout(
                    reason: .operationTimeout(seconds)
                )
            }()
        }
    }

    /// Create timeout task
    func timeoutTask<T>(_ seconds: TimeInterval) async throws -> T {
        try await Task.sleep(
            nanoseconds: UInt64(seconds * 1_000_000_000)
        )
        throw XPCError.timeout(
            reason: .operationTimeout(seconds)
        )
    }
}

// MARK: - XPCError.Reason

extension XPCError {
    enum Reason {
        case serviceInstanceDeallocated
        case invalidConnectionState(XPCConnectionState)
        case noActiveConnection
        case invalidProxyType(Any.Type)
        case maxRetryAttemptsExceeded
        case operationTimeout(TimeInterval)

        // MARK: Internal

        var description: String {
            switch self {
            case .serviceInstanceDeallocated:
                "Service instance was deallocated"
            case let .invalidConnectionState(state):
                "Cannot connect while in state: \(state.description)"
            case .noActiveConnection:
                "No active connection available"
            case let .invalidProxyType(type):
                "Failed to cast proxy to type: \(type)"
            case .maxRetryAttemptsExceeded:
                "Maximum retry attempts exceeded"
            case let .operationTimeout(seconds):
                "Operation timed out after \(seconds) seconds"
            }
        }
    }
}

// MARK: - Notifications

public extension Notification.Name {
    /// Posted when XPC connection state changes
    static let xpcConnectionStateChanged = Notification.Name(
        "dev.mpy.umbra.xpc.connectionStateChanged"
    )
}
