//
// XPCService.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Service for managing XPC connections and communication
@objc
public class XPCService: NSObject {
    // MARK: - Types

    /// Connection configuration
    public struct Configuration {
        /// Service name
        public let serviceName: String
        /// Interface protocol
        public let interfaceProtocol: Protocol
        /// Maximum retry attempts
        public let maxRetryAttempts: Int
        /// Retry delay in seconds
        public let retryDelay: TimeInterval
        /// Connection timeout in seconds
        public let connectionTimeout: TimeInterval

        /// Initialize with values
        public init(
            serviceName: String,
            interfaceProtocol: Protocol,
            maxRetryAttempts: Int = 3,
            retryDelay: TimeInterval = 1.0,
            connectionTimeout: TimeInterval = 30.0
        ) {
            self.serviceName = serviceName
            self.interfaceProtocol = interfaceProtocol
            self.maxRetryAttempts = maxRetryAttempts
            self.retryDelay = retryDelay
            self.connectionTimeout = connectionTimeout
        }
    }

    // MARK: - Properties

    /// Logger for tracking operations
    private let logger: LoggerProtocol

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    /// Connection configuration
    private let configuration: Configuration

    /// Active connection
    private var connection: NSXPCConnection?

    /// Connection state
    private var connectionState: XPCConnectionState = .disconnected {
        didSet {
            logger.debug(
                "XPC connection state changed",
                config: LogConfig(
                    metadata: [
                        "old_state": String(describing: oldValue),
                        "new_state": String(describing: connectionState)
                    ]
                )
            )
        }
    }

    /// Queue for synchronizing operations
    private let queue = DispatchQueue(
        label: "dev.mpy.umbra.xpc-service",
        qos: .userInitiated,
        attributes: .concurrent
    )

    /// Connection retry count
    private var retryCount = 0

    // MARK: - Initialization

    /// Initialize with dependencies
    @objc
    public init(
        configuration: Configuration,
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        self.configuration = configuration
        self.performanceMonitor = performanceMonitor
        self.logger = logger
        super.init()
    }

    // MARK: - Public Methods

    /// Connect to XPC service
    @objc
    public func connect() async throws {
        try await performanceMonitor.trackDuration(
            "xpc.connect"
        ) {
            try await queue.sync { [weak self] in
                guard let self = self else {
                    throw XPCError.notConnected
                }

                guard self.connectionState == .disconnected else {
                    throw XPCError.invalidState(
                        "Cannot connect while in state: \(self.connectionState)"
                    )
                }

                self.connectionState = .connecting

                // Create connection
                let connection = NSXPCConnection(
                    serviceName: self.configuration.serviceName
                )

                // Configure connection
                self.configureConnection(connection)

                // Resume connection
                connection.resume()

                // Wait for connection
                try await self.waitForConnection(connection)

                self.connection = connection
                self.connectionState = .connected
                self.retryCount = 0

                self.logger.info(
                    "Connected to XPC service",
                    config: LogConfig(
                        metadata: [
                            "service": self.configuration.serviceName
                        ]
                    )
                )
            }
        }
    }

    /// Disconnect from XPC service
    @objc
    public func disconnect() {
        queue.sync { [weak self] in
            guard let self = self else {
                return
            }

            guard self.connectionState == .connected else {
                return
            }

            self.connectionState = .disconnecting

            self.connection?.invalidate()
            self.connection = nil

            self.connectionState = .disconnected

            self.logger.info(
                "Disconnected from XPC service",
                config: LogConfig(
                    metadata: [
                        "service": self.configuration.serviceName
                    ]
                )
            )
        }
    }

    /// Get remote proxy object
    @objc
    public func remoteProxy<T>() throws -> T {
        try queue.sync { [weak self] in
            guard let self = self else {
                throw XPCError.notConnected
            }

            guard
                let connection = self.connection,
                self.connectionState == .connected
            else {
                throw XPCError.notConnected
            }

            guard let proxy = connection.remoteObjectProxyWithErrorHandler({ error in
                self.handleConnectionError(error)
            }) as? T else {
                throw XPCError.invalidProxy(
                    "Failed to cast proxy to type: \(T.self)"
                )
            }

            return proxy
        }
    }

    // MARK: - Private Methods

    /// Configure XPC connection
    private func configureConnection(
        _ connection: NSXPCConnection
    ) {
        // Set interface
        connection.remoteObjectInterface = NSXPCInterface(
            with: self.configuration.interfaceProtocol
        )

        // Set audit session
        connection.auditSessionIdentifier = au_session_self()

        // Set interruption handler
        connection.interruptionHandler = { [weak self] in
            self?.handleInterruption()
        }

        // Set invalidation handler
        connection.invalidationHandler = { [weak self] in
            self?.handleInvalidation()
        }
    }

    /// Wait for connection
    private func waitForConnection(
        _ connection: NSXPCConnection
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let timeout = DispatchTime.now() + self.configuration.connectionTimeout

            DispatchQueue.global().asyncAfter(deadline: timeout) {
                continuation.resume(throwing: XPCError.timeout)
            }

            // Ping service to verify connection
            guard let proxy = connection.remoteObjectProxy as? XPCProtocol else {
                continuation.resume(throwing: XPCError.invalidProxy(
                    "Failed to cast proxy to XPCProtocol"
                ))
                return
            }

            Task {
                do {
                    try await proxy.ping()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Handle connection interruption
    private func handleInterruption() {
        queue.async { [weak self] in
            guard let self = self else { return }

            self.connectionState = .interrupted

            // Attempt to reconnect
            if self.retryCount < self.configuration.maxRetryAttempts {
                self.retryCount += 1

                self.logger.warning(
                    "XPC connection interrupted, attempting to reconnect",
                    config: LogConfig(
                        metadata: [
                            "service": self.configuration.serviceName,
                            "attempt": String(self.retryCount),
                            "max_attempts": String(self.configuration.maxRetryAttempts)
                        ]
                    )
                )

                Task {
                    try? await Task.sleep(
                        nanoseconds: UInt64(
                            self.configuration.retryDelay * 1_000_000_000
                        )
                    )
                    try? await self.connect()
                }
            } else {
                self.logger.error(
                    "XPC connection interrupted, max retry attempts reached",
                    config: LogConfig(
                        metadata: [
                            "service": self.configuration.serviceName,
                            "max_attempts": String(self.configuration.maxRetryAttempts)
                        ]
                    )
                )
            }
        }
    }

    /// Handle connection invalidation
    private func handleInvalidation() {
        queue.async { [weak self] in
            guard let self = self else { return }

            self.connection = nil
            self.connectionState = .invalidated

            self.logger.error(
                "XPC connection invalidated",
                config: LogConfig(
                    metadata: [
                        "service": self.configuration.serviceName
                    ]
                )
            )
        }
    }

    /// Handle connection error
    private func handleConnectionError(_ error: Error) {
        logger.error(
            "XPC connection error",
            config: LogConfig(
                metadata: [
                    "service": configuration.serviceName,
                    "error": String(describing: error)
                ]
            )
        )
    }
}

extension XPCService {
    @objc
    func getService() throws -> XPCServiceProtocol {
        guard let service = NSXPCConnection.current()?.exportedObject as? XPCServiceProtocol else {
            throw XPCError.invalidService
        }
        return service
    }

    @objc
    func getConnection() throws -> XPCServiceProtocol {
        guard let connection = NSXPCConnection.current()?.remoteObjectProxy as? XPCServiceProtocol else {
            throw XPCError.invalidConnection
        }
        return connection
    }
}
