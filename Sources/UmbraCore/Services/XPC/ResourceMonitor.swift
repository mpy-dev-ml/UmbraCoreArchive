import Foundation

// MARK: - Resource Monitor

/// Monitor for tracking and managing system resource usage
final class ResourceMonitor {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with configuration
    /// - Parameters:
    ///   - limits: Resource limits
    ///   - logger: Operation logger
    init(
        limits: [String: Double],
        logger: LoggerProtocol
    ) {
        self.limits = limits
        self.logger = logger

        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: Internal

    // MARK: - Types

    /// Resource usage snapshot
    struct ResourceSnapshot {
        /// CPU usage percentage (0-100)
        let cpuUsage: Double

        /// Memory usage in bytes
        let memoryUsage: Double

        /// Disk usage in bytes
        let diskUsage: Double

        /// Network usage in bytes
        let networkUsage: Double

        /// Process count
        let processCount: Int

        /// File descriptor count
        let fileDescriptorCount: Int

        /// Timestamp of snapshot
        let timestamp: Date
    }

    /// Resource reservation
    struct ResourceReservation {
        /// Reservation identifier
        let identifier: String

        /// Reserved CPU percentage
        let cpuReservation: Double

        /// Reserved memory in bytes
        let memoryReservation: Double

        /// Reservation timestamp
        let timestamp: Date

        /// Reservation expiry
        let expiry: Date?
    }

    // MARK: - Public Methods

    /// Get current resource usage
    /// - Returns: Dictionary of resource usage
    func getCurrentUsage() async throws -> [String: Double] {
        let snapshot = try await captureResourceSnapshot()
        return [
            "cpu": snapshot.cpuUsage,
            "memory": snapshot.memoryUsage,
            "disk": snapshot.diskUsage,
            "network": snapshot.networkUsage
        ]
    }

    /// Reserve resources for operation
    /// - Parameters:
    ///   - identifier: Operation identifier
    ///   - cpu: CPU percentage needed
    ///   - memory: Memory bytes needed
    ///   - duration: Reservation duration
    func reserveResources(
        identifier: String,
        cpu: Double,
        memory: Double,
        duration: TimeInterval? = nil
    ) async throws {
        try await queue.sync(flags: .barrier) {
            try validateResourceAvailability(cpu: cpu, memory: memory)
            let reservation = createResourceReservation(
                identifier: identifier,
                cpu: cpu,
                memory: memory,
                duration: duration
            )
            storeReservation(reservation)
            logReservation(reservation, duration: duration)
        }
    }

    /// Release resources for operation
    /// - Parameter identifier: Operation identifier
    func releaseResources(
        for identifier: String
    ) async throws {
        try await queue.sync(flags: .barrier) {
            guard reservations.removeValue(forKey: identifier) != nil else {
                throw XPCError.resourceUnavailable(
                    reason: "No reservation found for: \(identifier)"
                )
            }

            logger.debug(
                "Released resources",
                metadata: ["identifier": identifier]
            )
        }
    }

    /// Check if operation has sufficient resources
    /// - Parameter identifier: Operation identifier
    /// - Returns: Whether resources are sufficient
    func hasSufficientResources(
        for identifier: String
    ) async throws -> Bool {
        try await queue.sync {
            let reservation = try getValidReservation(identifier)
            if try shouldReleaseExpiredReservation(reservation, identifier) {
                return false
            }
            return try checkResourceLimits()
        }
    }

    // MARK: Private

    /// Get valid reservation for identifier
    /// - Parameter identifier: Operation identifier
    /// - Returns: Valid reservation
    private func getValidReservation(_ identifier: String) throws -> ResourceReservation {
        guard let reservation = reservations[identifier] else {
            throw XPCError.resourceUnavailable(
                reason: "No reservation found for: \(identifier)"
            )
        }
        return reservation
    }

    /// Check if reservation has expired and should be released
    /// - Parameters:
    ///   - reservation: Reservation to check
    ///   - identifier: Operation identifier
    /// - Returns: Whether reservation should be released
    private func shouldReleaseExpiredReservation(
        _ reservation: ResourceReservation,
        _ identifier: String
    ) async throws -> Bool {
        if let expiry = reservation.expiry, expiry < Date() {
            try await releaseResources(for: identifier)
            return true
        }
        return false
    }

    /// Check if current usage is within resource limits
    /// - Returns: Whether usage is within limits
    private func checkResourceLimits() throws -> Bool {
        let currentUsage = try getCurrentResourceUsage()
        return currentUsage.cpu <= limits["cpu"] ?? .infinity &&
            currentUsage.memory <= limits["memory"] ?? .infinity
    }

    /// Get current resource usage with reservations
    private struct CurrentResourceUsage {
        let cpu: Double
        let memory: Double
        let disk: Double
        let network: Double
    }

    /// Resource limits
    private let limits: [String: Double]

    /// Logger for operations
    private let logger: LoggerProtocol

    /// Queue for synchronising access
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbra.resource-monitor",
        attributes: .concurrent
    )

    /// Active resource reservations
    private var reservations: [String: ResourceReservation] = [:]

    /// Resource usage history
    private var usageHistory: [ResourceSnapshot] = []

    /// Maximum history entries to keep
    private let maxHistoryEntries = 100

    /// Resource usage monitor timer
    private var monitorTimer: DispatchSourceTimer?

    // MARK: - Private Methods

    /// Start resource monitoring
    private func startMonitoring() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(
            deadline: .now(),
            repeating: .seconds(1)
        )

        timer.setEventHandler { [weak self] in
            guard let self else {
                return
            }
            Task {
                do {
                    let snapshot = try await self.captureResourceSnapshot()
                    try await self.processResourceSnapshot(snapshot)
                } catch {
                    self.logger.error(
                        "Failed to capture resource snapshot: \(error.localizedDescription)"
                    )
                }
            }
        }

        timer.resume()
        monitorTimer = timer
    }

    /// Stop resource monitoring
    private func stopMonitoring() {
        monitorTimer?.cancel()
        monitorTimer = nil
    }

    /// Capture current resource snapshot
    private func captureResourceSnapshot() async throws -> ResourceSnapshot {
        // This implementation should use system APIs to gather real metrics
        // For now, we return placeholder values
        ResourceSnapshot(
            cpuUsage: 0,
            memoryUsage: 0,
            diskUsage: 0,
            networkUsage: 0,
            processCount: 0,
            fileDescriptorCount: 0,
            timestamp: Date()
        )
    }

    /// Process resource snapshot
    private func processResourceSnapshot(
        _ snapshot: ResourceSnapshot
    ) async throws {
        try await queue.sync(flags: .barrier) {
            // Add to history
            usageHistory.append(snapshot)

            // Trim history if needed
            if usageHistory.count > maxHistoryEntries {
                usageHistory.removeFirst(
                    usageHistory.count - maxHistoryEntries
                )
            }

            // Clean up expired reservations
            let now = Date()
            reservations = reservations.filter { _, reservation in
                guard let expiry = reservation.expiry else {
                    return true
                }
                return expiry > now
            }

            // Check resource limits
            if snapshot.cpuUsage > limits["cpu"] ?? .infinity {
                logger.warning(
                    "CPU usage exceeded limit",
                    metadata: [
                        "usage": String(snapshot.cpuUsage),
                        "limit": String(limits["cpu"] ?? .infinity)
                    ]
                )
            }

            if snapshot.memoryUsage > limits["memory"] ?? .infinity {
                logger.warning(
                    "Memory usage exceeded limit",
                    metadata: [
                        "usage": String(snapshot.memoryUsage),
                        "limit": String(limits["memory"] ?? .infinity)
                    ]
                )
            }
        }
    }

    /// Get current resource usage including reservations
    private func getCurrentResourceUsage() throws -> CurrentResourceUsage {
        let reservedResources = calculateReservedResources()
        return try combineWithLatestSnapshot(reservedResources)
    }

    /// Calculate total reserved resources
    /// - Returns: Reserved CPU and memory
    private func calculateReservedResources() -> (cpu: Double, memory: Double) {
        reservations.values.reduce(
            into: (cpu: 0.0, memory: 0.0)
        ) { result, reservation in
            result.cpu += reservation.cpuReservation
            result.memory += reservation.memoryReservation
        }
    }

    /// Combine reserved resources with latest snapshot
    /// - Parameter reservedResources: Reserved resources
    /// - Returns: Combined resource usage
    private func combineWithLatestSnapshot(
        _ reservedResources: (cpu: Double, memory: Double)
    ) throws -> CurrentResourceUsage {
        guard let latestSnapshot = usageHistory.last else {
            return CurrentResourceUsage(
                cpu: reservedResources.cpu,
                memory: reservedResources.memory,
                disk: 0,
                network: 0
            )
        }

        return CurrentResourceUsage(
            cpu: latestSnapshot.cpuUsage + reservedResources.cpu,
            memory: latestSnapshot.memoryUsage + reservedResources.memory,
            disk: latestSnapshot.diskUsage,
            network: latestSnapshot.networkUsage
        )
    }

    /// Validate resource availability
    /// - Parameters:
    ///   - cpu: CPU percentage needed
    ///   - memory: Memory bytes needed
    private func validateResourceAvailability(cpu: Double, memory: Double) throws {
        let currentUsage = try getCurrentResourceUsage()

        guard currentUsage.cpu + cpu <= limits["cpu"] ?? .infinity else {
            throw XPCError.resourceUnavailable(
                reason: "Insufficient CPU available"
            )
        }

        guard currentUsage.memory + memory <= limits["memory"] ?? .infinity else {
            throw XPCError.resourceUnavailable(
                reason: "Insufficient memory available"
            )
        }
    }

    /// Create resource reservation
    /// - Parameters:
    ///   - identifier: Operation identifier
    ///   - cpu: CPU percentage needed
    ///   - memory: Memory bytes needed
    ///   - duration: Reservation duration
    /// - Returns: Created reservation
    private func createResourceReservation(
        identifier: String,
        cpu: Double,
        memory: Double,
        duration: TimeInterval?
    ) -> ResourceReservation {
        ResourceReservation(
            identifier: identifier,
            cpuReservation: cpu,
            memoryReservation: memory,
            timestamp: Date(),
            expiry: duration.map { Date().addingTimeInterval($0) }
        )
    }

    /// Store reservation
    /// - Parameter reservation: Reservation to store
    private func storeReservation(_ reservation: ResourceReservation) {
        reservations[reservation.identifier] = reservation
    }

    /// Log reservation details
    /// - Parameters:
    ///   - reservation: Reservation to log
    ///   - duration: Reservation duration
    private func logReservation(
        _ reservation: ResourceReservation,
        duration: TimeInterval?
    ) {
        logger.debug(
            "Reserved resources",
            metadata: [
                "identifier": reservation.identifier,
                "cpu": String(reservation.cpuReservation),
                "memory": String(reservation.memoryReservation),
                "duration": duration.map { String($0) } ?? "indefinite"
            ]
        )
    }
}
