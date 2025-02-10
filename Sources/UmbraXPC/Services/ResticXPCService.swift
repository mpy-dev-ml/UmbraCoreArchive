//
// ResticXPCService.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

//
// ResticXPCService.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation
import Security

/// Service for managing Restic operations through XPC
///
/// The ResticXPCService provides a secure interface for executing Restic commands
/// through XPC communication. It handles:
/// - Connection management
/// - Security-scoped resource access
/// - Error handling and recovery
/// - Operation tracking
///
/// Key features:
/// - Secure XPC communication
/// - Resource cleanup
/// - Error handling
/// - Operation monitoring
@objc
public final class ResticXPCService: NSObject, ResticServiceProtocol, XPCConnectionStateDelegate {
    // MARK: - Properties

    /// XPC connection manager
    private let connectionManager: XPCConnectionManager

    /// Serial queue for synchronizing operations
    private let queue = DispatchQueue(
        label: "dev.mpy.rBUM.resticXPC",
        qos: .userInitiated,
        attributes: .concurrent
    )

    /// Current health state of the service
    private(set) var isHealthy: Bool

    /// Currently active security-scoped bookmarks
    private var activeBookmarks: [String: NSData]

    /// Logger for service operations
    private let logger: LoggerProtocol

    /// Security service for handling permissions
    private let securityService: SecurityServiceProtocol

    /// Message queue for handling XPC commands
    private let messageQueue: XPCMessageQueue

    /// Task for processing the message queue
    private var queueProcessor: Task<Void, Never>?

    /// Health monitor for service status
    private let healthMonitor: XPCHealthMonitor

    // MARK: - Initialization

    /// Initialize ResticXPCService
    /// - Parameters:
    ///   - logger: Logger for service operations
    ///   - securityService: Security service for handling permissions
    public init(
        logger: LoggerProtocol,
        securityService: SecurityServiceProtocol
    ) {
        self.logger = logger
        self.securityService = securityService
        self.queue = DispatchQueue(
            label: "dev.mpy.rBUM.resticXPC",
            qos: .userInitiated,
            attributes: .concurrent
        )
        self.isHealthy = false
        self.activeBookmarks = [:]
        self.messageQueue = XPCMessageQueue(logger: logger)

        // Initialize connection manager
        self.connectionManager = XPCConnectionManager(
            logger: logger,
            securityService: securityService
        )

        // Initialize health monitor
        self.healthMonitor = XPCHealthMonitor(
            connectionManager: connectionManager,
            logger: logger
        )

        super.init()

        // Set up connection manager delegate
        Task {
            await connectionManager.setDelegate(self)
            try await establishConnection()
            await healthMonitor.startMonitoring()
        }
    }

    deinit {
        Task {
            await healthMonitor.stopMonitoring()
        }
    }

    // MARK: - Connection Management

    private func establishConnection() async throws {
        _ = try await connectionManager.establishConnection()
        self.isHealthy = true
    }

    // MARK: - XPCConnectionStateDelegate

    func connectionStateDidChange(from oldState: XPCConnectionState, to newState: XPCConnectionState) {
        switch newState {
        case .active:
            self.isHealthy = true
            startQueueProcessor()
            Task {
                await healthMonitor.startMonitoring()
            }
        case .failed:
            self.isHealthy = false
            stopQueueProcessor()
            Task {
                await healthMonitor.stopMonitoring()
            }
        default:
            self.isHealthy = false
        }

        logger.info("XPC connection state changed: \(oldState) -> \(newState)", privacy: .public)
    }

    // MARK: - Command Execution

    private func executeCommand(_ config: XPCCommandConfig) async throws -> ProcessResult {
        let connection = try await connectionManager.establishConnection()

        guard let remote = connection.remoteObjectProxyWithErrorHandler({ error in
            self.logger.error("Remote proxy error: \(error.localizedDescription)", privacy: .public)
        }) as? ResticXPCProtocol else {
            throw ResticXPCError.invalidRemoteObject
        }

        return try await remote.execute(config: config, progress: ProgressTracker())
    }

    // MARK: - ResticServiceProtocol Implementation

    /// Initialize repository at the specified URL
    /// - Parameters:
    ///   - url: URL to initialize the repository at
    @objc
    public func initializeRepository(at url: URL) async throws {
        try await validateConnection()
        try await validatePermissions(for: url)

        let result = try await executeCommand(
            XPCCommandConfig(
                command: "init",
                arguments: ["--repository", url.path],
                workingDirectory: url
            )
        )

        guard result.status == 0 else {
            throw ResticError.initializationFailed(result.error ?? "Unknown error")
        }
    }

    /// Backup files from source to destination
    /// - Parameters:
    ///   - source: Source URL to backup
    ///   - destination: Destination URL for backup
    @objc
    public func backup(
        from source: URL,
        to destination: URL
    ) async throws {
        try await validateConnection()
        try await validatePermissions(for: [source, destination])

        let config = XPCCommandConfig(
            command: "backup",
            arguments: ["--repository", destination.path, source.path],
            workingDirectory: source
        )

        try await performanceMonitor.trackDuration(
            "restic.backup"
        ) { [weak self] in
            guard let self = self else { return }

            try await self.executeCommand(config)

            self.logger.info(
                "Backup completed successfully",
                config: LogConfig(
                    metadata: [
                        "source": source.path,
                        "destination": destination.path
                    ]
                )
            )
        }
    }

    /// List snapshots
    /// - Returns: Array of snapshot IDs
    @objc
    public func listSnapshots() async throws -> [String] {
        try await validateConnection()

        let result = try await executeCommand(
            XPCCommandConfig(
                command: "snapshots",
                arguments: ["--json"],
                workingDirectory: nil
            )
        )

        guard result.status == 0 else {
            throw ResticError.snapshotListFailed(result.error ?? "Unknown error")
        }

        return try parseSnapshots(from: result.output)
    }

    /// Restore files from source to destination
    /// - Parameters:
    ///   - source: Source URL to restore from
    ///   - destination: Destination URL to restore to
    @objc
    public func restore(
        from source: URL,
        to destination: URL
    ) async throws {
        try await validateConnection()
        try await validatePermissions(for: [source, destination])

        let result = try await executeCommand(
            XPCCommandConfig(
                command: "restore",
                arguments: ["latest", "--target", destination.path, "--repository", source.path],
                workingDirectory: destination
            )
        )

        guard result.status == 0 else {
            throw ResticError.restoreFailed(result.error ?? "Unknown error")
        }
    }
}

// MARK: - Errors

/// Errors that can occur during XPC operations
public enum ResticXPCError: LocalizedError {
    case connectionNotEstablished
    case connectionInterrupted
    case invalidBookmark(path: String)
    case staleBookmark(path: String)
    case accessDenied(path: String)
    case missingServiceName
    case serviceUnavailable
    case operationTimeout
    case operationCancelled
    case invalidResponse
    case invalidArguments
    case invalidRemoteObject

    public var errorDescription: String? {
        switch self {
        case .connectionNotEstablished:
            return "XPC connection not established"
        case .connectionInterrupted:
            return "XPC connection interrupted"
        case .invalidBookmark(let path):
            return "Invalid security-scoped bookmark for path: \(path)"
        case .staleBookmark(let path):
            return "Stale security-scoped bookmark for path: \(path)"
        case .accessDenied(let path):
            return "Access denied to path: \(path)"
        case .missingServiceName:
            return "XPC service name not found in Info.plist"
        case .serviceUnavailable:
            return "XPC service is not available"
        case .operationTimeout:
            return "Operation timed out"
        case .operationCancelled:
            return "Operation was cancelled"
        case .invalidResponse:
            return "Invalid response from XPC service"
        case .invalidArguments:
            return "Invalid arguments provided to XPC service"
        case .invalidRemoteObject:
            return "Invalid remote object"
        }
    }
}
