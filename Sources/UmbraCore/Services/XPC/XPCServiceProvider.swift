@preconcurrency import Foundation

// MARK: - XPCServiceProvider

/// Provider for managing XPC service lifecycle and registration
public final class XPCServiceProvider {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with configuration
    /// - Parameters:
    ///   - configuration: Service configuration
    ///   - logger: Operation logger
    ///   - performanceMonitor: Performance tracking
    public init(
        configuration: Configuration = .default,
        logger: LoggerProtocol,
        performanceMonitor: PerformanceMonitor
    ) {
        self.configuration = configuration
        self.logger = logger
        self.performanceMonitor = performanceMonitor

        // Create service delegate
        serviceDelegate = XPCServiceDelegate(
            configuration: .init(
                maxConcurrentOperations: configuration.maxConcurrentConnections,
                validateAuditSession: configuration.validateAuditSession,
                resourceLimits: configuration.resourceLimits
            ),
            logger: logger,
            performanceMonitor: performanceMonitor
        )
    }

    deinit {
        stop()
    }

    // MARK: Public

    // MARK: - Types

    /// Configuration for service provider
    public struct Configuration {
        // MARK: Lifecycle

        /// Initialize with values
        /// - Parameters:
        ///   - serviceName: Name of service
        ///   - interfaceProtocol: Interface protocol
        ///   - maxConcurrentConnections: Max connections
        ///   - validateAuditSession: Validate sessions
        ///   - resourceLimits: Resource limits
        public init(
            serviceName: String,
            interfaceProtocol: Protocol,
            maxConcurrentConnections: Int = 4,
            validateAuditSession: Bool = true,
            resourceLimits: [String: Double] = [:]
        ) {
            self.serviceName = serviceName
            self.interfaceProtocol = interfaceProtocol
            self.maxConcurrentConnections = maxConcurrentConnections
            self.validateAuditSession = validateAuditSession
            self.resourceLimits = resourceLimits
        }

        // MARK: Public

        /// Default configuration
        public static let `default`: Configuration = .init(
            serviceName: "dev.mpy.umbra.xpc-service",
            interfaceProtocol: XPCServiceProtocol.self,
            maxConcurrentConnections: 4,
            validateAuditSession: true,
            resourceLimits: [
                "memory": 512 * 1_024 * 1_024, // 512MB
                "cpu": 80.0 // 80% CPU
            ]
        )

        /// Service name
        public let serviceName: String

        /// Service interface protocol
        public let interfaceProtocol: Protocol

        /// Maximum concurrent connections
        public let maxConcurrentConnections: Int

        /// Whether to validate audit sessions
        public let validateAuditSession: Bool

        /// Resource limits
        public let resourceLimits: [String: Double]
    }

    /// Get current connection count
    public var connectionCount: Int {
        queue.sync {
            connections.count
        }
    }

    // MARK: - Public Methods

    /// Start the service provider
    public func start() {
        queue.sync(flags: .barrier) {
            guard listener == nil else {
                return
            }

            // Create listener
            let listener = NSXPCListener(machServiceName: configuration.serviceName)

            // Set delegate
            listener.delegate = self

            // Resume listener
            listener.resume()

            self.listener = listener

            logger.info(
                "Started XPC service provider",
                metadata: [
                    "service": configuration.serviceName,
                    "max_connections": String(configuration.maxConcurrentConnections)
                ]
            )
        }
    }

    /// Stop the service provider
    public func stop() {
        queue.sync(flags: .barrier) {
            // Invalidate listener
            listener?.suspend()
            listener = nil

            // Invalidate connections
            connections.forEach { $0.invalidate() }
            connections.removeAll()

            logger.info(
                "Stopped XPC service provider",
                metadata: ["service": configuration.serviceName]
            )
        }
    }

    // MARK: Private

    /// Service configuration
    private let configuration: Configuration

    /// Logger for operations
    private let logger: LoggerProtocol

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    /// Listener for incoming connections
    private var listener: NSXPCListener?

    /// Active connections
    private var connections: Set<NSXPCConnection> = []

    /// Queue for synchronising access
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbra.xpc-service-provider",
        attributes: .concurrent
    )

    /// Service delegate
    private let serviceDelegate: XPCServiceDelegate

    private let defaultMetadata = [
        "service": configuration.serviceName,
        "provider": "XPCServiceProvider"
    ]

    private func createConnectionMetadata(_ state: XPCConnectionState) -> [String: String] {
        [
            "service": configuration.serviceName,
            "provider": "XPCServiceProvider",
            "state": state.description
        ]
    }

    private func createErrorMetadata(_ error: Error) -> [String: String] {
        [
            "service": configuration.serviceName,
            "provider": "XPCServiceProvider",
            "error": String(describing: error)
        ]
    }

    private func createStateChangeMetadata(
        _ oldState: XPCConnectionState,
        _ newState: XPCConnectionState
    ) -> [String: String] {
        [
            "old_state": oldState.description,
            "new_state": newState.description
        ]
    }

    private func createStateChangeUserInfo(
        _ oldState: XPCConnectionState,
        _ newState: XPCConnectionState
    ) -> [String: Any] {
        [
            "old_state": oldState,
            "new_state": newState
        ]
    }

    private func createReconnectionMetadata() -> [String: String] {
        [
            "service": configuration.serviceName,
            "provider": "XPCServiceProvider"
        ]
    }
}

// MARK: NSXPCListenerDelegate

extension XPCServiceProvider: NSXPCListenerDelegate {
    public func listener(
        _: NSXPCListener,
        shouldAcceptNewConnection connection: NSXPCConnection
    ) -> Bool {
        // Check connection count
        guard connectionCount < configuration.maxConcurrentConnections else {
            logger.warning(
                "Rejected connection: maximum connections reached",
                metadata: [
                    "service": configuration.serviceName,
                    "max_connections": String(configuration.maxConcurrentConnections)
                ]
            )
            return false
        }

        // Configure connection
        connection.exportedInterface = NSXPCInterface(
            with: configuration.interfaceProtocol
        )

        connection.exportedObject = serviceDelegate

        // Set up handlers
        connection.invalidationHandler = { [weak self] in
            self?.handleConnectionInvalidation(connection)
        }

        connection.interruptionHandler = { [weak self] in
            self?.handleConnectionInterruption(connection)
        }

        // Track connection
        queue.sync(flags: .barrier) {
            connections.insert(connection)
        }

        // Resume connection
        connection.resume()

        logger.info(
            "Accepted new XPC connection",
            metadata: [
                "service": configuration.serviceName,
                "connections": String(connectionCount)
            ]
        )

        return true
    }
}

// MARK: - Private Methods

private extension XPCServiceProvider {
    /// Handle connection invalidation
    /// - Parameter connection: Invalid connection
    func handleConnectionInvalidation(
        _ connection: NSXPCConnection
    ) {
        queue.async(flags: .barrier) {
            connections.remove(connection)

            logger.debug(
                "XPC connection invalidated",
                metadata: [
                    "service": self.configuration.serviceName,
                    "connections": String(self.connectionCount)
                ]
            )
        }
    }

    /// Handle connection interruption
    /// - Parameter connection: Interrupted connection
    func handleConnectionInterruption(
        _ connection: NSXPCConnection
    ) {
        queue.async(flags: .barrier) {
            connections.remove(connection)

            logger.warning(
                "XPC connection interrupted",
                metadata: [
                    "service": self.configuration.serviceName,
                    "connections": String(self.connectionCount)
                ]
            )
        }
    }
}
