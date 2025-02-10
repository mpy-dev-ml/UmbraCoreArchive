import Foundation
import Network

/// Service for monitoring network connectivity
public final class NetworkMonitor: BaseSandboxedService {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - performanceMonitor: Performance monitor
    ///   - logger: Logger for tracking operations
    public init(
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        monitor = NWPathMonitor()
        self.performanceMonitor = performanceMonitor
        super.init(logger: logger)
        setupMonitor()
    }

    // MARK: - Deinitializer

    deinit {
        stopMonitoring()
    }

    // MARK: Public

    // MARK: - Types

    /// Network status
    public struct NetworkStatus {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            isAvailable: Bool,
            isExpensive: Bool,
            isConstrained: Bool,
            interfaceType: InterfaceType
        ) {
            self.isAvailable = isAvailable
            self.isExpensive = isExpensive
            self.isConstrained = isConstrained
            self.interfaceType = interfaceType
        }

        // MARK: Public

        /// Whether network is available
        public let isAvailable: Bool

        /// Whether network is expensive
        public let isExpensive: Bool

        /// Whether network is constrained
        public let isConstrained: Bool

        /// Network interface type
        public let interfaceType: InterfaceType
    }

    /// Network interface type
    public enum InterfaceType {
        case wifi
        case cellular
        case wired
        case loopback
        case other
    }

    // MARK: - Public Methods

    /// Start monitoring network
    public func startMonitoring() {
        monitor.start(queue: monitorQueue)

        logger.debug(
            "Started network monitoring",
            file: #file,
            function: #function,
            line: #line
        )
    }

    /// Stop monitoring network
    public func stopMonitoring() {
        monitor.cancel()

        logger.debug(
            "Stopped network monitoring",
            file: #file,
            function: #function,
            line: #line
        )
    }

    /// Get current network status
    /// - Returns: Network status
    public func getCurrentStatus() -> NetworkStatus? {
        queue.sync { currentStatus }
    }

    /// Add status change handler
    /// - Parameter handler: Status change handler
    public func addStatusHandler(_ handler: @escaping (NetworkStatus) -> Void) {
        queue.async(flags: .barrier) {
            self.statusHandlers.append(handler)

            // Call handler with current status
            if let status = self.currentStatus {
                handler(status)
            }
        }
    }

    /// Remove all status handlers
    public func removeAllHandlers() {
        queue.async(flags: .barrier) {
            self.statusHandlers.removeAll()
        }
    }

    // MARK: Private

    /// Network path monitor
    private let monitor: NWPathMonitor

    /// Queue for monitor callbacks
    private let monitorQueue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.network.monitor",
        qos: .utility
    )

    /// Current network status
    private var currentStatus: NetworkStatus?

    /// Status change handlers
    private var statusHandlers: [(NetworkStatus) -> Void] = []

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.network.status",
        qos: .utility,
        attributes: .concurrent
    )

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    // MARK: - Private Methods

    /// Set up network monitor
    private func setupMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else {
                return
            }

            // Create status
            let status = NetworkStatus(
                isAvailable: path.status == .satisfied,
                isExpensive: path.isExpensive,
                isConstrained: path.isConstrained,
                interfaceType: getInterfaceType(from: path)
            )

            // Update status
            queue.async(flags: .barrier) {
                self.currentStatus = status

                // Notify handlers
                for handler in self.statusHandlers {
                    handler(status)
                }
            }

            // Log status change
            logger.info(
                """
                Network status changed:
                Available: \(status.isAvailable)
                Expensive: \(status.isExpensive)
                Constrained: \(status.isConstrained)
                Interface: \(status.interfaceType)
                """,
                file: #file,
                function: #function,
                line: #line
            )

            // Track metrics
            Task {
                try? await self.performanceMonitor.trackMetric(
                    "network.available",
                    value: status.isAvailable ? 1.0 : 0.0
                )
                try? await self.performanceMonitor.trackMetric(
                    "network.expensive",
                    value: status.isExpensive ? 1.0 : 0.0
                )
                try? await self.performanceMonitor.trackMetric(
                    "network.constrained",
                    value: status.isConstrained ? 1.0 : 0.0
                )
            }
        }
    }

    /// Get interface type from network path
    /// - Parameter path: Network path
    /// - Returns: Interface type
    private func getInterfaceType(from path: NWPath) -> InterfaceType {
        if path.usesInterfaceType(.wifi) {
            .wifi
        } else if path.usesInterfaceType(.cellular) {
            .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            .wired
        } else if path.usesInterfaceType(.loopback) {
            .loopback
        } else {
            .other
        }
    }
}
