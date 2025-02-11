import Foundation
import os.log
import Security

// MARK: - ResticXPCService

/// Service for managing Restic operations through XPC
@objc
public final class ResticXPCService: NSObject {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Creates a new Restic XPC service
    /// - Parameters:
    ///   - logger: Logger for operations
    ///   - securityService: Security service
    ///   - metrics: Metrics recorder
    public init(
        logger: LoggerProtocol,
        securityService: SecurityServiceProtocol,
        metrics: SecurityMetrics
    ) {
        // Store dependencies
        self.logger = logger
        self.securityService = securityService
        metricsRecorder = metrics

        // Initialize state
        isHealthy = false
        activeBookmarks = [:]

        // Initialize core components
        queue = Self.createDispatchQueue()
        messageQueue = XPCMessageQueue(logger: logger)
        connectionManager = Self.createConnectionManager(
            logger: logger,
            securityService: securityService
        )
        healthMonitor = Self.createHealthMonitor(
            connectionManager: connectionManager,
            logger: logger
        )

        super.init()

        // Configure components
        configureComponents()

        // Start services
        startServices()
    }

    deinit {
        stopServices()
    }

    // MARK: Internal

    // MARK: - Public Properties

    /// Current health state of the service
    @objc private(set) dynamic var isHealthy: Bool

    // MARK: Private

    // MARK: - Private Properties

    /// XPC connection manager
    private let connectionManager: XPCConnectionManager

    /// Queue for synchronizing operations
    private let queue: DispatchQueue

    /// Active security-scoped bookmarks
    private var activeBookmarks: [String: NSData]

    /// Logger for service operations
    private let logger: LoggerProtocol

    /// Security service for permissions
    private let securityService: SecurityServiceProtocol

    /// Message queue for XPC commands
    private let messageQueue: XPCMessageQueue

    /// Task for queue processing
    private var queueProcessor: Task<Void, Never>?

    /// Health monitor for service
    private let healthMonitor: XPCHealthMonitor

    /// Operation metrics recorder
    private let metricsRecorder: SecurityMetrics
}

// MARK: - Private Initialization Helpers

private extension ResticXPCService {
    /// Creates the dispatch queue for operations
    static func createDispatchQueue() -> DispatchQueue {
        DispatchQueue(
            label: "com.umbra.core.resticXPC",
            qos: .userInitiated,
            attributes: .concurrent
        )
    }

    /// Creates the XPC connection manager
    static func createConnectionManager(
        logger: LoggerProtocol,
        securityService: SecurityServiceProtocol
    ) -> XPCConnectionManager {
        XPCConnectionManager(
            logger: logger,
            securityService: securityService
        )
    }

    /// Creates the health monitor
    static func createHealthMonitor(
        connectionManager: XPCConnectionManager,
        logger: LoggerProtocol
    ) -> XPCHealthMonitor {
        XPCHealthMonitor(
            connectionManager: connectionManager,
            logger: logger,
            checkInterval: 30
        )
    }

    /// Configures service components
    func configureComponents() {
        connectionManager.delegate = self
        healthMonitor.delegate = self
    }
}

// MARK: - Service Lifecycle

private extension ResticXPCService {
    /// Starts all service components
    func startServices() {
        queue.async { [weak self] in
            guard let self else {
                return
            }
            startServiceComponents()
            logger.info("ResticXPCService started successfully")
        }
    }

    /// Starts individual service components
    func startServiceComponents() {
        connectionManager.start()
        healthMonitor.start()
        startQueueProcessor()
    }

    /// Stops all service components
    func stopServices() {
        queue.async { [weak self] in
            guard let self else {
                return
            }
            stopServiceComponents()
            cleanupResources()
            logger.info("ResticXPCService stopped successfully")
        }
    }

    /// Stops individual service components
    func stopServiceComponents() {
        healthMonitor.stop()
        queueProcessor?.cancel()
        queueProcessor = nil
        connectionManager.stop()
    }

    /// Starts the queue processor
    func startQueueProcessor() {
        queueProcessor = Task { [weak self] in
            guard let self else {
                return
            }
            await processMessageQueue()
        }
    }

    /// Processes messages from the queue
    func processMessageQueue() async {
        do {
            try await messageQueue.process { [weak self] message in
                guard let self else {
                    return
                }
                try await handleMessage(message)
            }
        } catch {
            handleQueueProcessingError(error)
        }
    }

    /// Handles queue processing errors
    func handleQueueProcessingError(_ error: Error) {
        let errorMessage = error.localizedDescription
        logger.error("Queue processor failed: \(errorMessage)")
        metricsRecorder.recordXPC(
            success: false,
            error: errorMessage
        )
    }

    /// Cleans up service resources
    func cleanupResources() {
        releaseBookmarks()
        messageQueue.clear()
    }

    /// Releases active security-scoped bookmarks
    func releaseBookmarks() {
        for bookmark in activeBookmarks.values {
            autoreleasepool {
                bookmark.stopAccessingSecurityScopedResource()
            }
        }
        activeBookmarks.removeAll()
    }
}

// MARK: XPCConnectionStateDelegate

extension ResticXPCService: XPCConnectionStateDelegate {
    public func connectionStateDidChange(_ state: XPCConnectionState) {
        queue.async { [weak self] in
            guard let self else {
                return
            }
            handleConnectionState(state)
        }
    }

    private func handleConnectionState(_ state: XPCConnectionState) {
        switch state {
        case .connected:
            handleConnectedState()
        case .disconnected:
            handleDisconnectedState()
        case .invalid:
            handleInvalidState()
        case .interrupted:
            handleInterruptedState()
        }
    }

    private func handleConnectedState() {
        isHealthy = true
        logger.info("XPC connection established")
        recordConnectionMetrics(
            success: true,
            state: "connected"
        )
    }

    private func handleDisconnectedState() {
        isHealthy = false
        logger.warning("XPC connection lost")
        recordConnectionMetrics(
            success: false,
            error: "Connection lost",
            state: "disconnected"
        )
    }

    private func handleInvalidState() {
        isHealthy = false
        logger.error("XPC connection invalid")
        recordConnectionMetrics(
            success: false,
            error: "Invalid connection",
            state: "invalid"
        )
    }

    private func handleInterruptedState() {
        isHealthy = false
        logger.warning("XPC connection interrupted")
        recordConnectionMetrics(
            success: false,
            error: "Connection interrupted",
            state: "interrupted"
        )
    }

    private func recordConnectionMetrics(
        success: Bool,
        error: String? = nil,
        state: String
    ) {
        var metadata = ["state": state]
        if let error {
            metricsRecorder.recordXPC(
                success: success,
                error: error,
                metadata: metadata
            )
        } else {
            metricsRecorder.recordXPC(
                success: success,
                metadata: metadata
            )
        }
    }
}

// MARK: XPCHealthMonitorDelegate

extension ResticXPCService: XPCHealthMonitorDelegate {
    public func healthCheckFailed(_ error: Error) {
        queue.async { [weak self] in
            guard let self else {
                return
            }
            handleHealthCheckFailure(error)
        }
    }

    public func healthCheckPassed() {
        queue.async { [weak self] in
            guard let self else {
                return
            }
            handleHealthCheckSuccess()
        }
    }

    private func handleHealthCheckFailure(_ error: Error) {
        isHealthy = false
        let errorMessage = error.localizedDescription
        logger.error("Health check failed: \(errorMessage)")
        metricsRecorder.recordXPC(
            success: false,
            error: errorMessage,
            metadata: ["type": "health_check"]
        )

        // Attempt recovery
        connectionManager.reconnect()
    }

    private func handleHealthCheckSuccess() {
        isHealthy = true
        logger.debug("Health check passed")
        metricsRecorder.recordXPC(
            success: true,
            metadata: ["type": "health_check"]
        )
    }
}
