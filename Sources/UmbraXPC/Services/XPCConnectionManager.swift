import Foundation

// MARK: - XPCConnectionManager

/// Manages XPC connection lifecycle and recovery
@available(macOS 13.0, *)
public actor XPCConnectionManager {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize XPC connection manager
    /// - Parameters:
    ///   - configuration: Connection configuration
    ///   - logger: Logger for connection events
    ///   - securityService: Security service for validation
    ///   - delegate: Delegate for state changes
    public init(
        configuration: Configuration,
        logger: LoggerProtocol,
        securityService: SecurityServiceProtocol,
        delegate: XPCConnectionStateDelegate? = nil
    ) {
        self.configuration = configuration
        self.logger = logger
        self.securityService = securityService
        self.delegate = delegate
        state = .disconnected
    }

    deinit {
        cleanup()
    }

    // MARK: Public

    // MARK: - Types

    /// Configuration for XPC connection
    public struct Configuration {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            serviceName: String,
            interfaceProtocol: Protocol,
            maxRetryAttempts: Int = 3,
            retryDelay: TimeInterval = 1.0,
            healthCheckInterval: TimeInterval = 30.0
        ) {
            self.serviceName = serviceName
            self.interfaceProtocol = interfaceProtocol
            self.maxRetryAttempts = maxRetryAttempts
            self.retryDelay = retryDelay
            self.healthCheckInterval = healthCheckInterval
        }

        // MARK: Public

        /// Service name
        public let serviceName: String
        /// Interface protocol
        public let interfaceProtocol: Protocol
        /// Maximum retry attempts
        public let maxRetryAttempts: Int
        /// Retry delay in seconds
        public let retryDelay: TimeInterval
        /// Health check interval in seconds
        public let healthCheckInterval: TimeInterval
    }

    // MARK: - Public Methods

    /// Connect to XPC service
    /// - Throws: XPCError if connection fails
    public func connect() async throws {
        try await performanceMonitor.trackDuration(
            "xpc.connect"
        ) { [weak self] in
            guard let self else {
                return
            }

            // Validate current state
            guard state == .disconnected else {
                let message = """
                Cannot connect while in state: \
                \(state)
                """
                throw XPCError.invalidState(message)
            }

            // Update state
            state = .connecting

            // Create connection
            let connection = NSXPCConnection(
                serviceName: configuration.serviceName
            )

            // Configure connection
            configureConnection(connection)

            // Resume connection
            connection.resume()

            // Wait for connection
            try await waitForConnection(connection)

            // Update state
            self.connection = connection
            state = .connected

            // Log success
            let metadata = ["service": configuration.serviceName]
            let config = LogConfig(metadata: metadata)
            let message = "Connected to XPC service"
            logger.info(message, config: config)

            // Start health checks
            startHealthChecks()
        }
    }

    /// Establish XPC connection
    public func establishConnection() async throws -> NSXPCConnection {
        if case .active = state, let connection {
            return connection
        }

        updateState(.connecting)

        do {
            let newConnection = try await createConnection()
            connection = newConnection
            updateState(.active)
            startHealthCheck()
            return newConnection
        } catch {
            updateState(.failed(error))
            throw error
        }
    }

    /// Handle connection interruption
    public func handleInterruption() {
        let message = "XPC connection interrupted"
        logger.warning(message, privacy: .public)
        updateState(.interrupted(Date()))
        startRecovery()
    }

    /// Handle connection invalidation
    public func handleInvalidation() {
        let message = "XPC connection invalidated"
        logger.error(message, privacy: .public)
        updateState(.invalidated(Date()))
        startRecovery()
    }

    // MARK: Internal

    /// The current state of the XPC connection
    private(set) var state: XPCConnectionState

    // MARK: Private

    /// The active XPC connection instance
    private var connection: NSXPCConnection?

    /// Logger for connection events
    private let logger: LoggerProtocol

    /// Security service for connection validation
    private let securityService: SecurityServiceProtocol

    /// Configuration for connection management
    private let configuration: Configuration

    /// Delegate for connection state changes
    private weak var delegate: XPCConnectionStateDelegate?

    /// Task for connection recovery
    private var recoveryTask: Task<Void, Never>?

    /// Timer for health checks
    private var healthCheckTimer: Timer?

    // MARK: - Private Methods

    private func configureConnection(_ connection: NSXPCConnection) {
        let interface = configuration.interfaceProtocol
        connection.remoteObjectInterface = NSXPCInterface(with: interface)
        connection.exportedInterface = NSXPCInterface(with: interface)
        connection.auditSessionIdentifier = au_session_self()

        connection.interruptionHandler = { [weak self] in
            Task { await self?.handleInterruption() }
        }

        connection.invalidationHandler = { [weak self] in
            Task { await self?.handleInvalidation() }
        }
    }

    private func createConnection() async throws -> NSXPCConnection {
        let connection = NSXPCConnection(
            serviceName: configuration.serviceName
        )

        // Configure interfaces
        configureConnection(connection)

        // Validate connection
        guard await securityService.validateXPCConnection(connection) else {
            throw ResticXPCError.connectionValidationFailed
        }

        connection.resume()
        return connection
    }

    private func startRecovery() {
        guard state.canRecover else {
            let message = """
            Connection cannot be recovered in current state: \
            \(state)
            """
            logger.error(message, privacy: .public)
            return
        }

        recoveryTask?.cancel()
        recoveryTask = Task {
            var attempt = 1
            let startTime = Date()

            while !Task.isCancelled {
                let timeElapsed = Date().timeIntervalSince(startTime)
                guard timeElapsed < XPCConnectionState.recoveryTimeout else {
                    updateState(.failed(ResticXPCError.recoveryTimeout))
                    return
                }

                let recoveryState = RecoveryState(
                    attempt: attempt,
                    since: startTime
                )
                updateState(.recovering(recoveryState))

                do {
                    _ = try await establishConnection()
                    let message = """
                    Connection recovered after \
                    \(attempt) attempts
                    """
                    logger.info(message, privacy: .public)
                    return
                } catch {
                    let message = """
                    Recovery attempt \(attempt) failed: \
                    \(error.localizedDescription)
                    """
                    logger.error(message, privacy: .public)
                    attempt += 1

                    if attempt > XPCConnectionState.maxRecoveryAttempts {
                        updateState(.failed(ResticXPCError.recoveryFailed))
                        return
                    }

                    let delay = XPCConnectionState.recoveryDelay
                    let nanoseconds = delay * 1_000_000_000
                    try? await Task.sleep(nanoseconds: UInt64(nanoseconds))
                }
            }
        }
    }

    private func startHealthCheck() {
        healthCheckTimer?.invalidate()
        let interval = 30.0
        healthCheckTimer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { [weak self] _ in
            Task {
                await self?.performHealthCheck()
            }
        }
    }

    private func startHealthChecks() {
        healthCheckTimer?.invalidate()
        let interval = configuration.healthCheckInterval
        healthCheckTimer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { [weak self] _ in
            Task {
                await self?.performHealthCheck()
            }
        }
    }

    private func performHealthCheck() async {
        guard case .active = state, let connection else {
            return
        }

        do {
            let errorHandler = { [weak self] (error: Error) in
                Task { await self?.handleHealthCheckError(error) }
            }
            let remote =
                connection.remoteObjectProxyWithErrorHandler(
                    errorHandler
                ) as? ResticXPCProtocol

            guard let remote else {
                throw ResticXPCError.invalidRemoteObject
            }

            let isHealthy = try await remote.ping()
            if !isHealthy {
                let message = "Health check failed"
                logger.warning(message, privacy: .public)
                handleInterruption()
            }
        } catch {
            let message = """
            Health check error: \
            \(error.localizedDescription)
            """
            logger.error(message, privacy: .public)
            handleHealthCheckError(error)
        }
    }

    private func handleHealthCheckError(_ error: Error) {
        let message = """
        Health check error: \
        \(error.localizedDescription)
        """
        logger.error(message, privacy: .public)
        handleInterruption()
    }

    private func updateState(_ newState: XPCConnectionState) {
        let oldState = state
        state = newState
        delegate?.connectionStateDidChange(from: oldState, to: newState)

        let userInfo: [String: Any] = [
            "oldState": oldState,
            "newState": newState
        ]
        NotificationCenter.default.post(
            name: .xpcConnectionStateChanged,
            object: nil,
            userInfo: userInfo
        )
    }

    private func waitForConnection(
        _ connection: NSXPCConnection
    ) async throws {
        // Wait for connection
        let description = "Wait for connection"
        let expectation = XCTestExpectation(description: description)
        connection.remoteObjectProxyWithErrorHandler { _ in
            expectation.fulfill()
        }
        wait(for: expectation, timeout: 10)
    }

    private func cleanup() {
        recoveryTask?.cancel()
        recoveryTask = nil
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
        connection?.invalidate()
        connection = nil
    }

    private func validateConnection() throws {
        let validStates = [
            XPCConnectionState.connected,
            XPCConnectionState.active,
            XPCConnectionState.ready
        ]

        guard let currentState = connectionState,
              validStates.contains(currentState)
        else {
            throw XPCError.invalidConnectionState
        }
    }

    private func handleConnectionError(_ error: Error) {
        let recoverySteps = [
            "Check XPC service status",
            "Verify connection parameters",
            "Restart XPC service if needed"
        ]

        logger.error(
            "XPC connection error: \(error.localizedDescription)",
            category: "XPCConnection",
            metadata: ["recoverySteps": recoverySteps]
        )
    }
}

extension XPCConnectionManager {
    func handleConnectionError(
        _ error: Error,
        for message: XPCMessage
    ) {
        let errorInfo: [String: Any] = [
            "messageId": message.id,
            "error": error
        ]

        NotificationCenter.default.post(
            name: .xpcConnectionError,
            object: self,
            userInfo: errorInfo
        )

        logger.error(
            "XPC connection error: \(error.localizedDescription)",
            metadata: ["message_id": message.id]
        )
    }

    func handleDisconnection(
        for connection: NSXPCConnection,
        with error: Error?
    ) {
        let errorInfo: [String: Any] = [
            "connection": connection,
            "error": error as Any
        ]

        NotificationCenter.default.post(
            name: .xpcConnectionDisconnected,
            object: self,
            userInfo: errorInfo
        )

        if let error {
            logger.error(
                "XPC connection disconnected with error: \(error.localizedDescription)",
                metadata: ["connection": connection.description]
            )
        } else {
            logger.info(
                "XPC connection disconnected normally",
                metadata: ["connection": connection.description]
            )
        }
    }

    func handleReconnection(
        for connection: NSXPCConnection
    ) {
        let connectionInfo: [String: Any] = [
            "connection": connection
        ]

        NotificationCenter.default.post(
            name: .xpcConnectionReconnected,
            object: self,
            userInfo: connectionInfo
        )

        logger.info(
            "XPC connection reestablished",
            metadata: ["connection": connection.description]
        )
    }
}
