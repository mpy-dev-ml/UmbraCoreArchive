import Foundation

/// Monitors the health of XPC services
@available(macOS 13.0, *)
public actor XPCHealthMonitor {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize the health monitor
    /// - Parameters:
    ///   - connectionManager: XPC connection manager
    ///   - logger: Logger instance
    ///   - interval: Health check interval in seconds
    public init(
        connectionManager: XPCConnectionManager,
        logger: LoggerProtocol,
        interval: TimeInterval = Constants.defaultInterval
    ) {
        self.connectionManager = connectionManager
        self.logger = logger
        healthCheckInterval = interval

        // Initialize with default values
        let resources = SystemResources(
            cpuUsage: 0,
            memoryUsage: 0,
            availableDiskSpace: 0,
            activeFileHandles: 0,
            activeConnections: 0
        )

        currentStatus = XPCHealthStatus(
            state: .unknown("Initial state"),
            lastChecked: Date(),
            responseTime: 0,
            successfulChecks: 0,
            failedChecks: 0,
            resources: resources
        )
    }

    // MARK: Public

    // MARK: - Public Methods

    /// Start health monitoring
    public func startMonitoring() {
        stopMonitoring()

        healthCheckTimer = Timer.scheduledTimer(
            withTimeInterval: healthCheckInterval,
            repeats: true
        ) { [weak self] _ in
            Task {
                await self?.performHealthCheck()
            }
        }

        let metadata = [
            "interval": String(healthCheckInterval),
            "threshold": String(Constants.criticalFailureThreshold)
        ]
        logger.info(
            "Started health monitoring",
            metadata: metadata,
            privacy: .public
        )
    }

    /// Stop health monitoring
    public func stopMonitoring() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
        logger.info(
            "Stopped health monitoring",
            privacy: .public
        )
    }

    // MARK: - Health Monitoring

    /// Perform a health check
    public func performHealthCheck() async {
        let startTime = Date()

        do {
            let resources = try await getSystemResources()
            let isHealthy = try await checkServiceHealth()

            // Calculate response time
            lastResponseTime = Date().timeIntervalSince(startTime)

            if isHealthy {
                await handleHealthyState(resources)
            } else {
                await handleUnhealthyState(resources)
            }
        } catch {
            await handleHealthCheckError(error, startTime: startTime)
        }
    }

    // MARK: Internal

    /// Current health status
    private(set) var currentStatus: XPCHealthStatus

    // MARK: Private

    // MARK: - Types

    /// Constants for health monitoring
    private enum Constants {
        static let criticalFailureThreshold = 3
        static let healthyThreshold = 5
        static let defaultInterval: TimeInterval = 30.0
        static let responseTimeThreshold: TimeInterval = 1.0
    }

    /// Logger instance
    private let logger: LoggerProtocol

    /// Connection manager
    private let connectionManager: XPCConnectionManager

    /// Health check timer
    private var healthCheckTimer: Timer?

    /// Health check interval in seconds
    private let healthCheckInterval: TimeInterval

    /// Number of consecutive successful health checks
    private var successfulChecks: Int = 0

    /// Number of consecutive failed health checks
    private var failedChecks: Int = 0

    /// Last recorded response time
    private var lastResponseTime: TimeInterval = 0

    // MARK: - Private Methods

    /// Get current system resources
    private func getSystemResources() async throws -> SystemResources {
        let metrics = try await SystemMetrics.current()

        return SystemResources(
            cpuUsage: metrics.cpuUsage,
            memoryUsage: metrics.memoryUsage,
            availableDiskSpace: metrics.diskSpace,
            activeFileHandles: metrics.fileHandles,
            activeConnections: metrics.connections
        )
    }

    /// Check if the service is healthy
    private func checkServiceHealth() async throws -> Bool {
        let remote = try await connectionManager.getRemoteProxy()
        let isHealthy = try await remote.ping()

        if !isHealthy {
            logger.warning(
                "Service health check failed",
                metadata: ["responseTime": String(lastResponseTime)],
                privacy: .public
            )
        }

        return isHealthy
    }

    /// Handle healthy service state
    private func handleHealthyState(_ resources: SystemResources) async {
        successfulChecks += 1
        failedChecks = 0

        let state: XPCHealthStatus.State =
            if successfulChecks >= Constants.healthyThreshold {
                .healthy
            } else {
                .recovering(
                    """
                    Service recovering: \(successfulChecks)/\(Constants.healthyThreshold) \
                    checks passed
                    """)
            }

        if lastResponseTime > Constants.responseTimeThreshold {
            logger.warning(
                "Slow response time detected",
                metadata: [
                    "responseTime": String(format: "%.3f", lastResponseTime),
                    "threshold": String(Constants.responseTimeThreshold)
                ],
                privacy: .public
            )
        }

        await updateStatus(state, resources: resources)
    }

    /// Handle unhealthy service state
    private func handleUnhealthyState(_ resources: SystemResources) async {
        failedChecks += 1
        successfulChecks = 0

        // Determine state based on consecutive failures
        let state: XPCHealthStatus.State =
            if failedChecks >= Constants.criticalFailureThreshold {
                .critical(
                    """
                    Service consistently failing health checks: \
                    \(failedChecks) consecutive failures
                    """)
            } else {
                .degraded(
                    """
                    Service failed health check: \
                    \(failedChecks)/\(Constants.criticalFailureThreshold) failures
                    """)
            }

        await updateStatus(state, resources: resources)
    }

    /// Handle health check error
    private func handleHealthCheckError(
        _ error: Error,
        startTime: Date
    ) async {
        failedChecks += 1
        successfulChecks = 0

        // Calculate response time even for failures
        lastResponseTime = Date().timeIntervalSince(startTime)

        // Create empty resources for error state
        let resources = SystemResources(
            cpuUsage: 0,
            memoryUsage: 0,
            availableDiskSpace: 0,
            activeFileHandles: 0,
            activeConnections: 0
        )

        let errorMessage = error.localizedDescription
        let state = XPCHealthStatus.State.error(errorMessage)
        await updateStatus(state, resources: resources)

        logger.error(
            "Health check failed",
            metadata: [
                "error": errorMessage,
                "failedChecks": String(failedChecks),
                "responseTime": String(format: "%.3f", lastResponseTime)
            ],
            privacy: .public
        )
    }

    /// Update the health status
    private func updateStatus(
        _ state: XPCHealthStatus.State,
        resources: SystemResources
    ) async {
        let oldStatus = currentStatus
        currentStatus = XPCHealthStatus(
            state: state,
            lastChecked: Date(),
            responseTime: lastResponseTime,
            successfulChecks: successfulChecks,
            failedChecks: failedChecks,
            resources: resources
        )

        // Log status change if state changed
        if oldStatus.state != state {
            logger.info(
                "Health status changed",
                metadata: [
                    "oldState": String(describing: oldStatus.state),
                    "newState": String(describing: state),
                    "responseTime": String(format: "%.3f", lastResponseTime),
                    "successfulChecks": String(successfulChecks),
                    "failedChecks": String(failedChecks)
                ],
                privacy: .public
            )
        }
    }
}
