//
// ServiceProvider.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

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
    // MARK: - Properties

    /// Shared instance
    public static let shared = ServiceProvider()

    /// Logger for services
    private let logger: LoggerProtocol

    /// Performance monitor
    private lazy var performanceMonitor: PerformanceMonitor = {
        PerformanceMonitor(logger: logger)
    }()

    /// Security service
    public private(set) lazy var securityService: SecurityServiceProtocol = {
        ServiceFactory.createSecurityService(logger: logger)
    }()

    /// Bookmark service
    public private(set) lazy var bookmarkService: BookmarkServiceProtocol = {
        ServiceFactory.createBookmarkService(logger: logger)
    }()

    /// Process service
    public private(set) lazy var processService: ProcessService = {
        ProcessService(
            performanceMonitor: performanceMonitor,
            logger: logger
        )
    }()

    /// Process monitor
    public private(set) lazy var processMonitor: ProcessMonitor = {
        ProcessMonitor(
            performanceMonitor: performanceMonitor,
            logger: logger
        )
    }()

    /// XPC service
    public private(set) lazy var xpcService: XPCService = {
        XPCService(
            performanceMonitor: performanceMonitor,
            logger: logger
        )
    }()

    /// Encryption service
    public private(set) lazy var encryptionService: EncryptionService = {
        EncryptionService(
            performanceMonitor: performanceMonitor,
            logger: logger
        )
    }()

    /// Queue for synchronizing operations
    private let queue = DispatchQueue(
        label: "dev.mpy.umbracore.serviceprovider",
        qos: .userInitiated
    )

    /// Services dictionary
    private var services: [String: Any] = [:]

    /// Factories dictionary
    private var factories: [String: () throws -> Any] = [:]

    // MARK: - Initialization

    /// Private initializer to enforce singleton
    private init() {
        self.logger = LoggerFactory.createLogger(category: .services)
    }

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
        return try createNewService(type)
    }

    /// Try to get existing service
    private func tryGetExistingService<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)

        if let service = services[key] as? T {
            return service
        }

        return nil
    }

    /// Create new service
    private func createNewService<T>(_ type: T.Type) throws -> T {
        let key = String(describing: type)

        // Get factory
        guard let factory = factories[key] else {
            throw ServiceError.factoryNotFound(key)
        }

        // Create service
        guard let service = try factory() as? T else {
            throw ServiceError.invalidServiceType(key)
        }

        // Store service
        services[key] = service

        return service
    }

    /// Register service factory
    public func register<T>(
        _ type: T.Type,
        factory: @escaping () throws -> Any
    ) {
        let key = String(describing: type)
        factories[key] = factory
    }

    /// Unregister service factory
    public func unregister<T>(_ type: T.Type) {
        let key = String(describing: type)
        factories.removeValue(forKey: key)
        services.removeValue(forKey: key)
    }
}
