@preconcurrency import Foundation

// MARK: - XPCHealthMonitor

/// Monitor for tracking XPC connection health and performance
final class XPCHealthMonitor {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - logger: Logger for operations
    ///   - checkInterval: Interval between checks
    init(
        logger: LoggerProtocol,
        checkInterval: TimeInterval
    ) {
        self.logger = logger
        configuration = Configuration(checkInterval: checkInterval)
    }

    deinit {
        stopMonitoring()
    }

    // MARK: Internal

    // MARK: - Types

    /// Health check result
    enum HealthCheckResult {
        /// Connection is healthy
        case healthy
        /// Connection is degraded
        case degraded(reason: String)
        /// Connection is unhealthy
        case unhealthy(reason: String)
    }

    /// Health check configuration
    struct Configuration {
        // MARK: Lifecycle

        /// Initialize with custom values
        /// - Parameters:
        ///   - checkInterval: Interval between checks
        ///   - maxResponseTime: Maximum response time
        ///   - failureThreshold: Failure threshold
        ///   - autoRecovery: Auto recovery enabled
        init(
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

        // MARK: Internal

        /// Default configuration
        static let `default`: Configuration = .init(
            checkInterval: 5.0,
            maxResponseTime: 1.0,
            failureThreshold: 3,
            autoRecovery: true
        )

        /// Interval between health checks in seconds
        let checkInterval: TimeInterval
        /// Maximum allowed response time in seconds
        let maxResponseTime: TimeInterval
        /// Number of consecutive failures before marking unhealthy
        let failureThreshold: Int
        /// Whether to automatically attempt recovery
        let autoRecovery: Bool
    }

    // MARK: - Public Methods

    /// Start monitoring connection health
    /// - Parameter connection: Connection to monitor
    func startMonitoring(_ connection: NSXPCConnection) {
        queue.async { [weak self] in
            guard let self else {
                return
            }

            // Store connection
            self.connection = connection
            connectionState = .connected

            // Create and start timer
            let timer = DispatchSource.makeTimerSource(queue: queue)
            timer.schedule(
                deadline: .now() + configuration.checkInterval,
                repeating: configuration.checkInterval
            )

            timer.setEventHandler { [weak self] in
                guard let self else {
                    return
                }
                Task {
                    await self.performHealthCheck()
                }
            }

            timer.resume()
            healthCheckTimer = timer

            logger.info(
                "Started XPC health monitoring",
                metadata: [
                    "check_interval": String(configuration.checkInterval),
                    "max_response_time": String(configuration.maxResponseTime)
                ]
            )
        }
    }

    /// Stop monitoring connection health
    func stopMonitoring() {
        queue.async { [weak self] in
            guard let self else {
                return
            }

            // Cancel timer
            healthCheckTimer?.cancel()
            healthCheckTimer = nil

            // Clear state
            connection = nil
            connectionState = .disconnected
            consecutiveFailures = 0

            logger.info("Stopped XPC health monitoring")
        }
    }

    // MARK: Private

    /// Logger for operations
    private let logger: LoggerProtocol

    /// Monitor configuration
    private let configuration: Configuration

    /// Connection being monitored
    private weak var connection: NSXPCConnection?

    /// Queue for synchronising operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbra.xpc-health-monitor",
        qos: .utility
    )

    /// Timer for health checks
    private var healthCheckTimer: DispatchSourceTimer?

    /// Count of consecutive failures
    private var consecutiveFailures = 0

    /// Last health check result
    private var lastHealthCheckResult: HealthCheckResult = .healthy {
        didSet {
            handleHealthCheckResult(lastHealthCheckResult)
        }
    }

    /// Current connection state
    private var connectionState: XPCConnectionState = .disconnected {
        didSet {
            handleConnectionStateChange(from: oldValue, to: connectionState)
        }
    }

    // MARK: - Private Methods

    /// Perform health check on connection
    private func performHealthCheck() async {
        guard let connection else {
            lastHealthCheckResult = .unhealthy(reason: "No connection available")
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
            let responseTime = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) /
                1_000_000_000

            // Check response time
            if responseTime > configuration.maxResponseTime {
                lastHealthCheckResult = .degraded(
                    reason: "High latency: \(responseTime) seconds"
                )
                consecutiveFailures += 1
            } else {
                lastHealthCheckResult = .healthy
                consecutiveFailures = 0
            }
        } catch {
            consecutiveFailures += 1
            lastHealthCheckResult = .unhealthy(
                reason: "Health check failed: \(error.localizedDescription)"
            )
        }
    }

    /// Handle health check result
    /// - Parameter result: Health check result
    private func handleHealthCheckResult(_ result: HealthCheckResult) {
        // Log result
        switch result {
        case .healthy:
            logger.debug(
                "XPC connection health check passed",
                metadata: ["status": "healthy"]
            )

        case let .degraded(reason):
            logger.warning(
                "XPC connection health check degraded: \(reason)",
                metadata: [
                    "status": "degraded",
                    "reason": reason
                ]
            )

        case let .unhealthy(reason):
            logger.error(
                "XPC connection health check failed: \(reason)",
                metadata: [
                    "status": "unhealthy",
                    "reason": reason,
                    "consecutive_failures": String(consecutiveFailures)
                ]
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
                "result": result,
                "consecutive_failures": consecutiveFailures
            ]
        )
    }

    /// Handle unhealthy connection
    private func handleUnhealthyConnection() {
        guard configuration.autoRecovery else {
            return
        }

        logger.warning(
            "Attempting to recover unhealthy XPC connection",
            metadata: [
                "consecutive_failures": String(consecutiveFailures)
            ]
        )

        // Invalidate current connection
        connection?.invalidate()
        connection = nil
        connectionState = .disconnected

        // Notify for recovery
        NotificationCenter.default.post(
            name: .xpcConnectionNeedsRecovery,
            object: self
        )
    }

    /// Handle connection state change
    /// - Parameters:
    ///   - oldState: Previous state
    ///   - newState: New state
    private func handleConnectionStateChange(
        from oldState: XPCConnectionState,
        to newState: XPCConnectionState
    ) {
        logger.debug(
            "XPC connection state changed in health monitor",
            metadata: [
                "old_state": oldState.description,
                "new_state": newState.description
            ]
        )
    }
}

// MARK: - Notifications

extension Notification.Name {
    /// Posted when XPC connection health status changes
    static let xpcHealthStatusChanged = Notification.Name(
        "dev.mpy.umbra.xpc.healthStatusChanged"
    )

    /// Posted when XPC connection needs recovery
    static let xpcConnectionNeedsRecovery = Notification.Name(
        "dev.mpy.umbra.xpc.connectionNeedsRecovery"
    )
}
