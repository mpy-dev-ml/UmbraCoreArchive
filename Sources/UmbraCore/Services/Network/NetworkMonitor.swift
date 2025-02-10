//
// NetworkMonitor.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation
import Network

/// Service for monitoring network connectivity
public final class NetworkMonitor: BaseSandboxedService {
    // MARK: - Types

    /// Network status
    public struct NetworkStatus {
        /// Whether network is available
        public let isAvailable: Bool

        /// Whether network is expensive
        public let isExpensive: Bool

        /// Whether network is constrained
        public let isConstrained: Bool

        /// Network interface type
        public let interfaceType: InterfaceType

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
    }

    /// Network interface type
    public enum InterfaceType {
        case wifi
        case cellular
        case wired
        case loopback
        case other
    }

    // MARK: - Properties

    /// Network path monitor
    private let monitor: NWPathMonitor

    /// Queue for monitor callbacks
    private let monitorQueue = DispatchQueue(
        label: "dev.mpy.umbracore.network.monitor",
        qos: .utility
    )

    /// Current network status
    private var currentStatus: NetworkStatus?

    /// Status change handlers
    private var statusHandlers: [(NetworkStatus) -> Void] = []

    /// Queue for synchronizing operations
    private let queue = DispatchQueue(
        label: "dev.mpy.umbracore.network.status",
        qos: .utility,
        attributes: .concurrent
    )

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - performanceMonitor: Performance monitor
    ///   - logger: Logger for tracking operations
    public init(
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        self.monitor = NWPathMonitor()
        self.performanceMonitor = performanceMonitor
        super.init(logger: logger)
        setupMonitor()
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

    // MARK: - Private Methods

    /// Set up network monitor
    private func setupMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            // Create status
            let status = NetworkStatus(
                isAvailable: path.status == .satisfied,
                isExpensive: path.isExpensive,
                isConstrained: path.isConstrained,
                interfaceType: self.getInterfaceType(from: path)
            )

            // Update status
            self.queue.async(flags: .barrier) {
                self.currentStatus = status

                // Notify handlers
                for handler in self.statusHandlers {
                    handler(status)
                }
            }

            // Log status change
            self.logger.info(
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
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wired
        } else if path.usesInterfaceType(.loopback) {
            return .loopback
        } else {
            return .other
        }
    }

    // MARK: - Deinitializer

    deinit {
        stopMonitoring()
    }
}
