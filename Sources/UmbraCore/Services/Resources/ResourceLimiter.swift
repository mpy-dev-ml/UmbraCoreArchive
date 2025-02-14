import Foundation

// MARK: - ResourceLimiter

/// Service for enforcing resource limits
public final class ResourceLimiter: BaseSandboxedService {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - monitor: Resource monitor
    ///   - limits: Resource limits
    ///   - limitAction: Action to take when limit is exceeded
    ///   - logger: Logger for tracking operations
    public init(
        monitor: ResourceMonitor,
        limits: ResourceLimits = ResourceLimits(),
        limitAction: LimitAction = .warn,
        logger: LoggerProtocol
    ) {
        self.monitor = monitor
        self.limits = limits
        self.limitAction = limitAction
        super.init(logger: logger)
    }

    // MARK: Public

    // MARK: - Types

    /// Resource limits configuration
    public struct ResourceLimits {
        // MARK: Lifecycle

        /// Initialize with default values
        public init(
            memoryLimit: UInt64 = 2_000_000_000, // 2 GB
            cpuLimit: Double = 90.0, // 90%
            diskLimit: UInt64 = 10_000_000_000, // 10 GB
            networkLimit: Double = 10_000_000 // 10 MB/s
        ) {
            self.memoryLimit = memoryLimit
            self.cpuLimit = cpuLimit
            self.diskLimit = diskLimit
            self.networkLimit = networkLimit
        }

        // MARK: Public

        /// Memory limit in bytes
        public var memoryLimit: UInt64
        /// CPU usage limit percentage (0-100)
        public var cpuLimit: Double
        /// Disk space limit in bytes
        public var diskLimit: UInt64
        /// Network throughput limit in bytes/second
        public var networkLimit: Double
    }

    /// Action to take when limit is exceeded
    public enum LimitAction {
        /// Log warning only
        case warn
        /// Throttle resource usage
        case throttle
        /// Terminate operation
        case terminate
    }

    // MARK: - Public Methods

    /// Run an operation with resource limits
    /// - Parameter operation: Operation to run
    /// - Returns: Result of operation
    /// - Throws: ResourceError if limits are exceeded
    public func runWithLimits<T>(
        operation: () async throws -> T
    ) async throws -> T {
        try validateUsable(for: "runWithLimits")

        // Start monitoring
        let monitorTask = Task {
            while !Task.isCancelled {
                do {
                    let snapshot = try await monitor.takeSnapshot()
                    try checkLimits(snapshot)
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                } catch {
                    logger.error(
                        """
                        Resource monitoring failed: \
                        \(error.localizedDescription)
                        """,
                        file: #file,
                        function: #function,
                        line: #line
                    )
                }
            }
        }

        defer {
            monitorTask.cancel()
        }

        // Run operation
        return try await operation()
    }

    /// Update resource limits
    /// - Parameter limits: New limits
    public func updateLimits(_ limits: ResourceLimits) {
        queue.async {
            self.limits = limits

            self.logger.info(
                """
                Updated resource limits:
                Memory: \(limits.memoryLimit) bytes
                CPU: \(limits.cpuLimit)%
                Disk: \(limits.diskLimit) bytes
                Network: \(limits.networkLimit) bytes/s
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Update limit action
    /// - Parameter action: New action
    public func updateLimitAction(_ action: LimitAction) {
        queue.async {
            self.limitAction = action

            self.logger.info(
                "Updated limit action: \(action)",
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    // MARK: Private

    /// Resource monitor
    private let monitor: ResourceMonitor

    /// Resource limits
    private var limits: ResourceLimits

    /// Action to take when limit is exceeded
    private var limitAction: LimitAction

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.resources.limiter",
        qos: .userInitiated
    )

    // MARK: - Private Methods

    /// Check if resource limits are exceeded
    private func checkLimits(_ snapshot: ResourceMonitor.ResourceSnapshot) throws {
        var exceededLimits: [String] = []

        if snapshot.memoryUsage > limits.memoryLimit {
            exceededLimits.append("Memory")
        }

        if snapshot.cpuUsage > limits.cpuLimit {
            exceededLimits.append("CPU")
        }

        if snapshot.diskUsage > limits.diskLimit {
            exceededLimits.append("Disk")
        }

        if snapshot.networkThroughput > limits.networkLimit {
            exceededLimits.append("Network")
        }

        if !exceededLimits.isEmpty {
            let message = "Resource limits exceeded: \(exceededLimits.joined(separator: ", "))"

            switch limitAction {
            case .warn:
                logger.warning(
                    message,
                    file: #file,
                    function: #function,
                    line: #line
                )

            case .throttle:
                logger.warning(
                    "\(message) - Throttling",
                    file: #file,
                    function: #function,
                    line: #line
                )
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            case .terminate:
                logger.error(
                    "\(message) - Terminating",
                    file: #file,
                    function: #function,
                    line: #line
                )
                throw ResourceError.limitsExceeded(exceededLimits)
            }
        }
    }
}

// MARK: - ResourceError

/// Errors that can occur during resource operations
public enum ResourceError: LocalizedError {
    /// Resource limits exceeded
    case limitsExceeded([String])
    /// Resource monitoring failed
    case monitoringFailed(String)
    /// Invalid resource operation
    case invalidOperation(String)

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case let .limitsExceeded(resources):
            "Resource limits exceeded: \(resources.joined(separator: ", "))"

        case let .monitoringFailed(reason):
            "Resource monitoring failed: \(reason)"

        case let .invalidOperation(reason):
            "Invalid resource operation: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .limitsExceeded:
            "Try reducing resource usage or increasing limits"

        case .monitoringFailed:
            "Check system resources and try again"

        case .invalidOperation:
            "Check operation parameters and try again"
        }
    }
}
