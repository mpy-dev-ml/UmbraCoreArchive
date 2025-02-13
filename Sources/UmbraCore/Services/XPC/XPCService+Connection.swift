@preconcurrency import Foundation
import os.log

// MARK: - Connection Management

extension XPCService {
    /// Perform connection setup and validation
    func performConnect() async throws {
        guard let self else {
            throw XPCError.serviceUnavailable(
                reason: .serviceInstanceDeallocated
            )
        }

        try validateConnectionState()
        connectionState = .connecting

        let connection = try createConnection()
        try await waitForConnection(connection)

        self.connection = connection
        connectionState = .connected
        retryCount = 0

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
        if configuration.validateAuditSession {
            connection.auditSessionIdentifier = au_session_self()
        }

        connection.remoteObjectInterface = NSXPCInterface(
            with: configuration.interfaceProtocol
        )

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
        healthMonitor.stopMonitoring()

        connection?.invalidate()
        connection = nil

        connectionState = .disconnected
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

// MARK: - State Management

extension XPCService {
    /// Handle connection state changes
    func handleConnectionStateChange(
        from oldState: XPCConnectionState,
        to newState: XPCConnectionState
    ) {
        logStateChange(oldState, newState)
        notifyStateChange(oldState, newState)
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
}

// MARK: - Timeout Utility

extension XPCService {
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
