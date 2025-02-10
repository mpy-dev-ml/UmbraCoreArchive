//
// XPCConnectionManager.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

//
// XPCConnectionManager.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Manages XPC connection lifecycle and recovery
@available(macOS 13.0, *)
public actor XPCConnectionManager {
    // MARK: - Types

    /// Configuration for XPC connection
    public struct Configuration {
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
    }

    // MARK: - Properties

    /// The current state of the XPC connection
    private(set) var state: XPCConnectionState

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
        self.state = .disconnected
    }

    deinit {
        cleanup()
    }

    // MARK: - Public Methods

    /// Connect to XPC service
    /// - Throws: XPCError if connection fails
    public func connect() async throws {
        try await performanceMonitor.trackDuration(
            "xpc.connect"
        ) { [weak self] in
            guard let self = self else { return }

            // Validate current state
            guard state == .disconnected else {
                throw XPCError.invalidState(
                    "Cannot connect while in state: \(state)"
                )
            }

            // Update state
            state = .connecting

            // Create connection
            let connection = NSXPCConnection(
                serviceName: configuration.serviceName
            )

            // Configure connection
            self.configureConnection(connection)

            // Resume connection
            connection.resume()

            // Wait for connection
            try await self.waitForConnection(connection)

            // Update state
            self.connection = connection
            state = .connected

            logger.info(
                "Connected to XPC service",
                config: LogConfig(
                    metadata: [
                        "service": configuration.serviceName
                    ]
                )
            )

            // Start health checks
            self.startHealthChecks()
        }
    }

    /// Establish XPC connection
    public func establishConnection() async throws -> NSXPCConnection {
        if case .active = state, let connection = connection {
            return connection
        }

        updateState(.connecting)

        do {
            let newConnection = try await createConnection()
            self.connection = newConnection
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
        logger.warning("XPC connection interrupted", privacy: .public)
        updateState(.interrupted(Date()))
        startRecovery()
    }

    /// Handle connection invalidation
    public func handleInvalidation() {
        logger.error("XPC connection invalidated", privacy: .public)
        updateState(.invalidated(Date()))
        startRecovery()
    }

    // MARK: - Private Methods

    private func configureConnection(_ connection: NSXPCConnection) {
        connection.remoteObjectInterface = NSXPCInterface(with: configuration.interfaceProtocol)
        connection.exportedInterface = NSXPCInterface(with: configuration.interfaceProtocol)
        connection.auditSessionIdentifier = au_session_self()

        connection.interruptionHandler = { [weak self] in
            Task { await self?.handleInterruption() }
        }

        connection.invalidationHandler = { [weak self] in
            Task { await self?.handleInvalidation() }
        }
    }

    private func createConnection() async throws -> NSXPCConnection {
        let connection = NSXPCConnection(serviceName: configuration.serviceName)

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
            logger.error("Connection cannot be recovered in current state: \(state)", privacy: .public)
            return
        }

        recoveryTask?.cancel()
        recoveryTask = Task {
            var attempt = 1
            let startTime = Date()

            while !Task.isCancelled {
                guard Date().timeIntervalSince(startTime) < XPCConnectionState.recoveryTimeout else {
                    updateState(.failed(ResticXPCError.recoveryTimeout))
                    return
                }

                updateState(.recovering(attempt: attempt, since: startTime))

                do {
                    _ = try await establishConnection()
                    logger.info("Connection recovered after \(attempt) attempts", privacy: .public)
                    return
                } catch {
                    logger.error("Recovery attempt \(attempt) failed: \(error.localizedDescription)", privacy: .public)
                    attempt += 1

                    if attempt > XPCConnectionState.maxRecoveryAttempts {
                        updateState(.failed(ResticXPCError.recoveryFailed))
                        return
                    }

                    try? await Task.sleep(nanoseconds: UInt64(XPCConnectionState.recoveryDelay * 1_000_000_000))
                }
            }
        }
    }

    private func startHealthCheck() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task {
                await self?.performHealthCheck()
            }
        }
    }

    private func startHealthChecks() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: configuration.healthCheckInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.performHealthCheck()
            }
        }
    }

    private func performHealthCheck() async {
        guard case .active = state, let connection = connection else { return }

        do {
            let remote = connection.remoteObjectProxyWithErrorHandler { [weak self] error in
                Task { await self?.handleHealthCheckError(error) }
            } as? ResticXPCProtocol

            guard let remote = remote else {
                throw ResticXPCError.invalidRemoteObject
            }

            let isHealthy = try await remote.ping()
            if !isHealthy {
                logger.warning("Health check failed", privacy: .public)
                handleInterruption()
            }
        } catch {
            logger.error("Health check error: \(error.localizedDescription)", privacy: .public)
            handleHealthCheckError(error)
        }
    }

    private func handleHealthCheckError(_ error: Error) {
        logger.error("Health check error: \(error.localizedDescription)", privacy: .public)
        handleInterruption()
    }

    private func updateState(_ newState: XPCConnectionState) {
        let oldState = state
        state = newState
        delegate?.connectionStateDidChange(from: oldState, to: newState)

        NotificationCenter.default.post(
            name: .xpcConnectionStateChanged,
            object: nil,
            userInfo: [
                "oldState": oldState,
                "newState": newState
            ]
        )
    }

    private func waitForConnection(_ connection: NSXPCConnection) async throws {
        // Wait for connection
        let expectation = XCTestExpectation(description: "Wait for connection")
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
}
