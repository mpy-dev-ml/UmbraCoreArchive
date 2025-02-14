@preconcurrency import Foundation

/// Factory for creating services with appropriate implementations based on build configuration
///
/// The ServiceFactory provides a centralized way to create services with the appropriate
/// implementation based on build configuration and runtime environment.
@objc
public final class ServiceFactory: NSObject {
    // MARK: - Types

    /// Configuration for the service factory
    public struct Configuration: Sendable {
        // MARK: - Properties

        /// Default configuration
        public static let `default`: Configuration = .init(
            developmentEnabled: false,
            debugLoggingEnabled: false,
            artificialDelay: 0
        )

        /// Whether development services should be used
        public let developmentEnabled: Bool

        /// Whether debug logging is enabled
        public let debugLoggingEnabled: Bool

        /// Artificial delay for development testing (in seconds)
        public let artificialDelay: TimeInterval

        // MARK: - Initialization

        /// Initialize with values
        /// - Parameters:
        ///   - developmentEnabled: Whether development mode is enabled
        ///   - debugLoggingEnabled: Whether debug logging is enabled
        ///   - artificialDelay: Artificial delay for development testing
        public init(
            developmentEnabled: Bool,
            debugLoggingEnabled: Bool,
            artificialDelay: TimeInterval
        ) {
            self.developmentEnabled = developmentEnabled
            self.debugLoggingEnabled = debugLoggingEnabled
            self.artificialDelay = artificialDelay
        }
    }

    // MARK: - Properties

    /// Global configuration for the service factory
    public static let configuration: Configuration = .default

    /// Queue for synchronizing service creation
    private static let queue = DispatchQueue(
        label: "com.umbracore.service-factory",
        qos: .userInitiated
    )

    // MARK: - Service Creation

    /// Create a security service
    /// - Parameter logger: Logger for the service
    /// - Returns: A security service implementation
    public static func createSecurityService(
        logger: LoggerProtocol
    ) -> SecurityServiceProtocol {
        SecurityService(logger: logger)
    }

    /// Create a process service
    /// - Parameters:
    ///   - performanceMonitor: Performance monitor for the service
    ///   - logger: Logger for the service
    /// - Returns: A process service implementation
    public static func createProcessService(
        performanceMonitor: PerformanceMonitorProtocol,
        logger: LoggerProtocol
    ) -> ProcessServiceProtocol {
        ProcessService(performanceMonitor: performanceMonitor, logger: logger)
    }

    /// Create a network service
    /// - Parameters:
    ///   - performanceMonitor: Performance monitor for the service
    ///   - logger: Logger for the service
    /// - Returns: A network service implementation
    public static func createNetworkService(
        performanceMonitor: PerformanceMonitorProtocol,
        logger: LoggerProtocol
    ) -> NetworkServiceProtocol {
        NetworkService(performanceMonitor: performanceMonitor, logger: logger)
    }

    /// Create a performance monitor
    /// - Parameter logger: Logger for the monitor
    /// - Returns: A performance monitor implementation
    public static func createPerformanceMonitor(
        logger: LoggerProtocol
    ) -> PerformanceMonitorProtocol {
        PerformanceMonitor(logger: logger)
    }

    /// Create a sandbox monitor
    /// - Parameter logger: Logger for the monitor
    /// - Returns: A sandbox monitor implementation
    public static func createSandboxMonitor(
        logger: LoggerProtocol
    ) -> SandboxMonitorProtocol {
        SandboxMonitor(logger: logger)
    }
}
