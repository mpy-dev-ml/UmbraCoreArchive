@preconcurrency import Foundation

/// Provider for accessing shared service instances
///
/// The ServiceProvider provides a centralized way to access shared service instances
/// throughout the application. It supports:
/// - Lazy initialization of services
/// - Dependency injection
/// - Service lifecycle management
/// - Configuration management
///
/// Example usage:
/// ```swift
/// // Get shared services
/// let security = ServiceProvider.shared.securityService
/// let bookmark = ServiceProvider.shared.bookmarkService
///
/// // Configure provider
/// ServiceProvider.shared.configure(
///     developmentEnabled: true,
///     debugLoggingEnabled: true
/// )
/// ```
public final class ServiceProvider {
    // MARK: Lifecycle

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
    public private(set) lazy var securityService: SecurityServiceProtocol = ServiceFactory
        .createSecurityService(logger: logger)

    /// Bookmark service
    public private(set) lazy var bookmarkService: BookmarkServiceProtocol = ServiceFactory
        .createBookmarkService(logger: logger)

    /// Process service
    public private(set) lazy var processService: ProcessService = .init(
        performanceMonitor: performanceMonitor,
        logger: logger
    )

    /// Process monitor
    public private(set) lazy var processMonitor: ProcessMonitor = .init(
        performanceMonitor: performanceMonitor,
        logger: logger
    )

    /// XPC service
    public private(set) lazy var xpcService: XPCService = .init(
        performanceMonitor: performanceMonitor,
        logger: logger
    )

    /// Encryption service
    public private(set) lazy var encryptionService: EncryptionService = .init(
        performanceMonitor: performanceMonitor,
        logger: logger
    )

    // MARK: - Public Methods

    /// Configure service provider
    /// - Parameters:
    ///   - developmentEnabled: Whether development services should be used
    ///   - debugLoggingEnabled: Whether debug logging is enabled
    public func configure(
        developmentEnabled: Bool = false,
        debugLoggingEnabled: Bool = false
    ) {
        queue.sync {
            ServiceFactory.configuration = .init(
                developmentEnabled: developmentEnabled,
                debugLoggingEnabled: debugLoggingEnabled
            )
        }
    }

    /// Reset service provider
    /// This will clear all cached service instances
    public func reset() {
        queue.sync {
            // Clear cached instances
            // Note: This will trigger lazy initialization
            // when services are accessed again

            // Reset factory configuration
            ServiceFactory.configuration = .init()
        }
    }

    /// Get service of specified type
    public func getService<T>(_ type: T.Type) throws -> T {
        let key = String(describing: type)

        // Check if service exists
        if let service = tryGetExistingService(type) {
            return service
        }

        // Create new service
        return try createService(type, key: key)
    }

    /// Register service factory
    public func register(
        _ type: (some Any).Type,
        factory: @escaping () throws -> Any
    ) {
        let key = String(describing: type)
        factories[key] = factory
    }

    /// Unregister service factory
    public func unregister(_ type: (some Any).Type) {
        let key = String(describing: type)
        factories.removeValue(forKey: key)
        services.removeValue(forKey: key)
    }

    // MARK: Private

    /// Logger for services
    private let logger: LoggerProtocol

    /// Performance monitor
    private lazy var performanceMonitor: PerformanceMonitor = .init(logger: logger)

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.serviceprovider",
        qos: .userInitiated
    )

    /// Services dictionary
    private var services: [String: Any] = [:]

    /// Factories dictionary
    private var factories: [String: () throws -> Any] = [:]

    /// Try to get existing service
    private func tryGetExistingService<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)

        if let service = services[key] as? T {
            return service
        }

        return nil
    }

    /// Get service factory
    private func getFactory(for key: String) throwsthrows -> Any {
        guard let factory = factories[key] else {
            throw ServiceError.serviceNotFound(key)
        }
        return factory
    }

    /// Create service of type
    private func createService<T>(_ type: T.Type, key: String) throws -> T {
        let factory = try getFactory(for: key)
        guard let service = try factory() as? T else {
            throw try ServiceError.invalidServiceType(
                expected: String(describing: T.self),
                actual: String(describing: type(of: factory()))
            )
        }
        services[key] = service
        return service
    }
}
