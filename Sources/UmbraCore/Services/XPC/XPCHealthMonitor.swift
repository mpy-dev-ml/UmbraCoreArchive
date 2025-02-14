import Foundation
import Logging

// MARK: - XPCHealthMonitor

/// Monitor for tracking XPC connection health and performance
@Observable
@MainActor
public final class XPCHealthMonitor {
    // MARK: - Types

    /// Health check result
    @frozen
    @Error
    public enum HealthCheckError: LocalizedError, CustomDebugStringConvertible {
        /// No connection available
        case noConnection
        /// Service ping failed
        case pingFailed(Error)
        /// High latency detected
        case highLatency(responseTime: TimeInterval)
        /// Connection invalidated
        case connectionInvalidated

        public var errorDescription: String? {
            switch self {
            case .noConnection:
                "No XPC connection available"

            case let .pingFailed(error):
                "XPC service ping failed: \(error.localizedDescription)"

            case let .highLatency(time):
                "High XPC latency detected: \(time) seconds"

            case .connectionInvalidated:
                "XPC connection was invalidated"
            }
        }

        public var debugDescription: String {
            "XPCHealthCheckError: \(errorDescription ?? "Unknown error")"
        }
    }

    /// Health check result
    @frozen
    public enum HealthCheckResult: Sendable, CustomStringConvertible {
        /// Connection is healthy
        case healthy(responseTime: TimeInterval)
        /// Connection is degraded
        case degraded(error: HealthCheckError)
        /// Connection is unhealthy
        case unhealthy(error: HealthCheckError)

        /// Whether the connection is considered functional
        public var isFunctional: Bool {
            switch self {
            case .healthy, .degraded:
                true

            case .unhealthy:
                false
            }
        }

        /// Response time if available
        public var responseTime: TimeInterval? {
            switch self {
            case let .healthy(time):
                time

            case .degraded, .unhealthy:
                nil
            }
        }

        public var description: String {
            switch self {
            case let .healthy(time):
                "healthy (response time: \(time)s)"

            case let .degraded(error):
                "degraded: \(error.localizedDescription)"

            case let .unhealthy(error):
                "unhealthy: \(error.localizedDescription)"
            }
        }

        var metadata: Logger.Metadata {
            switch self {
            case let .healthy(time):
                [
                    "status": "healthy",
                    "response_time": .string(String(time))
                ]

            case let .degraded(error):
                [
                    "status": "degraded",
                    "error": .string(error.localizedDescription)
                ]

            case let .unhealthy(error):
                [
                    "status": "unhealthy",
                    "error": .string(error.localizedDescription)
                ]
            }
        }
    }

    /// Health check configuration
    @frozen
    public struct Configuration: Sendable, Equatable {
        // MARK: - Properties

        /// Default configuration
        public static let `default` = Self()

        /// Minimal configuration for testing
        public static let minimal = Self(
            checkInterval: 1.0,
            maxResponseTime: 0.5,
            failureThreshold: 1,
            autoRecovery: false
        )

        /// Aggressive configuration for critical services
        public static let aggressive = Self(
            checkInterval: 1.0,
            maxResponseTime: 0.1,
            failureThreshold: 2,
            autoRecovery: true
        )

        /// Interval between health checks in seconds
        public let checkInterval: TimeInterval

        /// Maximum allowed response time in seconds
        public let maxResponseTime: TimeInterval

        /// Number of consecutive failures before marking unhealthy
        public let failureThreshold: Int

        /// Whether to automatically attempt recovery
        public let autoRecovery: Bool

        // MARK: - Computed Properties

        /// Whether the configuration is valid
        public var isValid: Bool {
            checkInterval > 0 &&
                maxResponseTime > 0 &&
                failureThreshold > 0
        }

        // MARK: - Initialization

        /// Initialize with custom values
        /// - Parameters:
        ///   - checkInterval: Interval between checks
        ///   - maxResponseTime: Maximum response time
        ///   - failureThreshold: Failure threshold
        ///   - autoRecovery: Auto recovery enabled
        public init(
            checkInterval: TimeInterval = 5.0,
            maxResponseTime: TimeInterval = 1.0,
            failureThreshold: Int = 3,
            autoRecovery: Bool = true
        ) {
            self.checkInterval = checkInterval
            self.maxResponseTime = maxResponseTime
            self.failureThreshold = failureThreshold
            self.autoRecovery = autoRecovery
        }
    }

    // MARK: - Properties

    /// Current health status
    @Published
    private(set) var healthStatus: HealthCheckResult = .healthy(responseTime: 0)

    /// Current connection state
    @Published
    private(set) var connectionState: XPCConnectionState = .disconnected

    /// Count of consecutive failures
    @Published
    private(set) var consecutiveFailures: Int = 0

    /// Last health check timestamp
    @Published
    private(set) var lastCheckTimestamp: Date?

    // MARK: - Computed Properties

    /// Whether the connection is considered functional
    public var isConnectionFunctional: Bool {
        healthStatus.isFunctional && connectionState == .connected
    }

    /// Latest response time if available
    public var latestResponseTime: TimeInterval? {
        healthStatus.responseTime
    }

    // MARK: - Private Properties

    /// Logger for operations
    private let logger: any LoggerProtocol

    /// Monitor configuration
    private let configuration: Configuration

    /// Connection being monitored
    private weak var connection: NSXPCConnection?

    /// Queue for synchronising operations
    private let queue = DispatchQueue(
        label: "dev.mpy.umbra.xpc-health-monitor",
        qos: .utility
    )

    /// Timer for health checks
    private var healthCheckTimer: DispatchSourceTimer?

    /// Task for current health check
    private var currentHealthCheck: Task<Void, Never>?

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - logger: Logger for operations
    ///   - configuration: Monitor configuration
    public init(
        logger: any LoggerProtocol,
        configuration: Configuration = .default
    ) {
        precondition(configuration.isValid, "Invalid health monitor configuration")
        self.logger = logger
        self.configuration = configuration
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public Methods

    /// Start monitoring connection health
    /// - Parameter connection: Connection to monitor
    public func startMonitoring(_ connection: NSXPCConnection) {
        queue.async { [weak self] in
            guard let self else { return }

            // Cancel any existing monitoring
            stopMonitoring()

            // Store connection
            self.connection = connection
            Task { @MainActor in
                self.connectionState = .connected
            }

            // Create and start timer
            let timer = DispatchSource.makeTimerSource(queue: queue)
            timer.schedule(
                deadline: .now() + configuration.checkInterval,
                repeating: configuration.checkInterval
            )

            timer.setEventHandler { [weak self] in
                guard let self else { return }

                // Cancel any existing check
                currentHealthCheck?.cancel()

                // Start new check
                currentHealthCheck = Task {
                    await performHealthCheck()
                }
            }

            timer.resume()
            healthCheckTimer = timer

            logger.info(
                "Started XPC health monitoring",
                metadata: [
                    "check_interval": .string(String(configuration.checkInterval)),
                    "max_response_time": .string(String(configuration.maxResponseTime)),
                    "failure_threshold": .string(String(configuration.failureThreshold)),
                    "auto_recovery": .string(String(configuration.autoRecovery))
                ]
            )
        }
    }

    /// Stop monitoring connection health
    public func stopMonitoring() {
        queue.async { [weak self] in
            guard let self else { return }

            // Cancel health check
            currentHealthCheck?.cancel()
            currentHealthCheck = nil

            // Cancel timer
            healthCheckTimer?.cancel()
            healthCheckTimer = nil

            // Clear state
            connection = nil
            Task { @MainActor in
                self.connectionState = .disconnected
                self.consecutiveFailures = 0
                self.lastCheckTimestamp = nil
            }

            logger.info("Stopped XPC health monitoring")
        }
    }

    // MARK: - Private Methods

    /// Perform health check on connection
    private func performHealthCheck() async {
        guard let connection else {
            await updateHealthStatus(.unhealthy(error: .noConnection))
            return
        }

        do {
            // Measure response time
            let startTime = DispatchTime.now()

            // Attempt to ping service
            if let proxy = connection.remoteObjectProxy as? XPCServiceProtocol {
                try await proxy.ping()
            }

            let endTime = DispatchTime.now()
            let responseTime = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000

            // Update timestamp
            await updateLastCheckTimestamp()

            // Check response time
            if responseTime > configuration.maxResponseTime {
                let error = HealthCheckError.highLatency(responseTime: responseTime)
                await updateHealthStatus(.degraded(error: error))
                await incrementFailures()
            } else {
                await updateHealthStatus(.healthy(responseTime: responseTime))
                await resetFailures()
            }
        } catch {
            await incrementFailures()
            await updateHealthStatus(.unhealthy(error: .pingFailed(error)))
        }
    }

    /// Update health status and notify observers
    @MainActor
    private func updateHealthStatus(_ newStatus: HealthCheckResult) {
        healthStatus = newStatus

        // Log result with metadata
        switch newStatus {
        case .healthy:
            logger.debug(
                "XPC connection health check passed",
                metadata: newStatus.metadata
            )

        case .degraded:
            logger.warning(
                "XPC connection health check degraded",
                metadata: newStatus.metadata
            )

        case .unhealthy:
            logger.error(
                "XPC connection health check failed",
                metadata: newStatus.metadata.merging([
                    "consecutive_failures": .string(String(consecutiveFailures))
                ]) { $1 }
            )
        }

        // Check failure threshold
        if consecutiveFailures >= configuration.failureThreshold {
            handleUnhealthyConnection()
        }

        // Notify observers
        NotificationCenter.default.post(
            name: .xpcHealthStatusChanged,
            object: self,
            userInfo: [
                "result": newStatus,
                "consecutive_failures": consecutiveFailures,
                "timestamp": lastCheckTimestamp as Any
            ]
        )
    }

    /// Handle unhealthy connection
    @MainActor
    private func handleUnhealthyConnection() {
        guard configuration.autoRecovery else { return }

        logger.warning(
            "Attempting to recover unhealthy XPC connection",
            metadata: [
                "consecutive_failures": .string(String(consecutiveFailures))
            ]
        )

        // Invalidate current connection
        connection?.invalidate()
        connection = nil
        connectionState = .disconnected

        // Notify for recovery
        NotificationCenter.default.post(
            name: .xpcConnectionNeedsRecovery,
            object: self,
            userInfo: [
                "last_status": healthStatus,
                "consecutive_failures": consecutiveFailures,
                "timestamp": lastCheckTimestamp as Any
            ]
        )
    }

    /// Update last check timestamp
    @MainActor
    private func updateLastCheckTimestamp() {
        lastCheckTimestamp = Date()
    }

    /// Increment consecutive failures
    @MainActor
    private func incrementFailures() {
        consecutiveFailures += 1
    }

    /// Reset consecutive failures
    @MainActor
    private func resetFailures() {
        consecutiveFailures = 0
    }
}

// MARK: - Notifications

public extension Notification.Name {
    /// Posted when XPC connection health status changes
    static let xpcHealthStatusChanged = Notification.Name(
        "dev.mpy.umbra.xpc.healthStatusChanged"
    )

    /// Posted when XPC connection needs recovery
    static let xpcConnectionNeedsRecovery = Notification.Name(
        "dev.mpy.umbra.xpc.connectionNeedsRecovery"
    )
}
