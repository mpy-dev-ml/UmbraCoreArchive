@preconcurrency import Foundation

// MARK: - HealthState

/// Represents the possible health states of a service
@objc
public enum HealthState: Int {
    case unknown = 0
    case healthy = 1
    case degraded = 2
    case unhealthy = 3
    case critical = 4
    case maintenance = 5

    public var description: String {
        switch self {
        case .unknown:
            "Unknown"

        case .healthy:
            "Healthy"

        case .degraded:
            "Degraded"

        case .unhealthy:
            "Unhealthy"

        case .critical:
            "Critical"

        case .maintenance:
            "Maintenance"
        }
    }
}

// MARK: - HealthMetrics

/// Health metrics for a service
@objc
public final class HealthMetrics: NSObject {
    // MARK: - Properties

    /// CPU usage percentage (0-100)
    @objc public private(set) var cpuUsage: Double = 0

    /// Memory usage in bytes
    @objc public private(set) var memoryUsage: Int64 = 0

    /// Disk usage in bytes
    @objc public private(set) var diskUsage: Int64 = 0

    /// Number of active operations
    @objc public private(set) var activeOperations: Int = 0

    /// Error count since last reset
    @objc public private(set) var errorCount: Int = 0

    /// Success rate percentage (0-100)
    @objc public private(set) var successRate: Double = 100

    /// Average response time in milliseconds
    @objc public private(set) var averageResponseTime: Double = 0

    // MARK: - Methods

    /// Update metrics with new values
    /// - Parameters:
    ///   - cpuUsage: New CPU usage value
    ///   - memoryUsage: New memory usage value
    ///   - diskUsage: New disk usage value
    ///   - activeOperations: New active operations count
    ///   - errorCount: New error count
    ///   - successRate: New success rate
    ///   - averageResponseTime: New average response time
    @objc
    public func update(
        cpuUsage: Double,
        memoryUsage: Int64,
        diskUsage: Int64,
        activeOperations: Int,
        errorCount: Int,
        successRate: Double,
        averageResponseTime: Double
    ) {
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.diskUsage = diskUsage
        self.activeOperations = activeOperations
        self.errorCount = errorCount
        self.successRate = successRate
        self.averageResponseTime = averageResponseTime
    }

    /// Reset all metrics to their default values
    @objc
    public func reset() {
        cpuUsage = 0
        memoryUsage = 0
        diskUsage = 0
        activeOperations = 0
        errorCount = 0
        successRate = 100
        averageResponseTime = 0
    }
}

// MARK: - HealthCheckable

/// A protocol that defines health monitoring capabilities for services.
///
/// The `HealthCheckable` protocol provides a standardised way to monitor and report service health,
/// including detailed health metrics and status information. It is particularly useful for:
/// - Service availability monitoring
/// - Performance tracking
/// - Resource usage monitoring
/// - Error rate tracking
/// - System diagnostics
///
/// Example usage:
/// ```swift
/// class BackupService: NSObject, HealthCheckable {
///     var healthState: HealthState = .unknown
///     var lastHealthCheck: Date?
///     var healthMetrics = HealthMetrics()
///
///     func performHealthCheck() async throws -> HealthState {
///         // Perform health check logic
///         return .healthy
///     }
/// }
/// ```
@objc
public protocol HealthCheckable: NSObjectProtocol {
    /// The current health state of the service.
    ///
    /// This property provides a cached value of the service's health state,
    /// which is updated periodically through health checks.
    @objc var healthState: HealthState { get }

    /// The timestamp of the last performed health check.
    ///
    /// This property helps track when the health state was last verified
    /// and can be used to determine if a new health check is needed.
    @objc var lastHealthCheck: Date? { get }

    /// The current health metrics of the service.
    ///
    /// These metrics provide detailed information about the service's performance
    /// and resource usage, helping identify potential issues or bottlenecks.
    @objc var healthMetrics: HealthMetrics { get }

    /// Performs a comprehensive health check of the service.
    ///
    /// This method should verify:
    /// - Service availability
    /// - Resource usage
    /// - Error rates
    /// - Performance metrics
    /// - Dependencies health
    ///
    /// - Returns: The current health state after performing checks
    /// - Throws: Error if health check fails
    @objc func performHealthCheck() async throws -> HealthState
}

// MARK: - HealthCheckable Default Implementation

public extension HealthCheckable {
    /// The current health state of the service.
    /// Default implementation always returns `.healthy`.
    var healthState: HealthState { .healthy }

    /// The timestamp of the last performed health check.
    /// Default implementation returns nil.
    var lastHealthCheck: Date? { nil }

    /// The current health metrics of the service.
    /// Default implementation returns empty metrics.
    var healthMetrics: HealthMetrics { HealthMetrics() }
}
