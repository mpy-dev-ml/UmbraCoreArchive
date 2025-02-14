@preconcurrency import Foundation

/// Provider for accessing shared service instances
///
/// The ServiceProvider provides a centralized way to access shared service instances
/// throughout the application. It supports:
/// - Lazy initialization of services
/// - Dependency injection
/// - Service lifecycle management
/// - Configuration management
public final class ServiceProvider: @unchecked Sendable {
    // MARK: - Lifecycle

    // MARK: - Initialization

    /// Private initializer to enforce singleton
    private init() {
        logger = OSLogger(
            subsystem: "dev.mpy.umbra",
            category: "services",
            logger: OSLogger(subsystem: "dev.mpy.umbra", category: "bootstrap", logger: ConsoleLogger())
        )
    }

    // MARK: Public

    /// Shared instance
    public static let shared: ServiceProvider = .init()

    /// Security service
    public private(set) lazy var securityService: SecurityServiceProtocol =
        ServiceFactory
            .createSecurityService(logger: logger)

    /// Process service
    public private(set) lazy var processService: ProcessServiceProtocol =
        ServiceFactory
            .createProcessService(logger: logger)

    /// Network service
    public private(set) lazy var networkService: NetworkServiceProtocol =
        ServiceFactory
            .createNetworkService(logger: logger)

    /// Performance monitor
    public private(set) lazy var performanceMonitor: PerformanceMonitorProtocol =
        ServiceFactory
            .createPerformanceMonitor(logger: logger)

    /// Sandbox monitor
    public private(set) lazy var sandboxMonitor: SandboxMonitorProtocol =
        ServiceFactory
            .createSandboxMonitor(logger: logger)

    // MARK: - Properties

    /// Logger for the provider
    private let logger: LoggerProtocol
}
