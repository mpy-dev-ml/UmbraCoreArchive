import Foundation
import os.log

// MARK: - SecurityMetrics

/// Collects and manages security-related metrics for monitoring and debugging
@available(macOS 13.0, *)
public actor SecurityMetrics {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Creates a new security metrics tracker
    /// - Parameters:
    ///   - logger: Logger for recording metric events
    ///   - label: Queue label (defaults to bundle identifier)
    ///   - maxHistory: Maximum operations to keep in history (default: 100)
    public init(
        logger: Logger,
        label: String = Bundle.main.bundleIdentifier ?? "com.umbra.core",
        maxHistory: Int = 100
    ) {
        self.logger = logger
        queue = DispatchQueue(
            label: "\(label).security-metrics",
            qos: .utility
        )
        maxHistorySize = maxHistory
    }

    // MARK: Public

    // MARK: - Recording Methods

    /// Records an access attempt
    /// - Parameters:
    ///   - success: Whether access was successful
    ///   - error: Optional error message
    ///   - metadata: Additional context
    public func recordAccess(
        success: Bool = true,
        error: String? = nil,
        metadata: [String: String] = [:]
    ) {
        queue.async {
            self.accessCount += 1
            if !success {
                self.failureCount += 1
            }
            self.logMetric(
                type: "access",
                success: success,
                error: error,
                metadata: metadata
            )
        }
    }

    /// Records a permission request
    /// - Parameters:
    ///   - success: Whether permission was granted
    ///   - error: Optional error message
    ///   - metadata: Additional context
    public func recordPermission(
        success: Bool = true,
        error: String? = nil,
        metadata: [String: String] = [:]
    ) {
        queue.async {
            self.permissionCount += 1
            if !success {
                self.failureCount += 1
            }
            self.logMetric(
                type: "permission",
                success: success,
                error: error,
                metadata: metadata
            )
        }
    }

    /// Records a bookmark operation
    /// - Parameters:
    ///   - success: Whether operation succeeded
    ///   - error: Optional error message
    ///   - metadata: Additional context
    public func recordBookmark(
        success: Bool = true,
        error: String? = nil,
        metadata: [String: String] = [:]
    ) {
        queue.async {
            self.bookmarkCount += 1
            if !success {
                self.failureCount += 1
            }
            self.logMetric(
                type: "bookmark",
                success: success,
                error: error,
                metadata: metadata
            )
        }
    }

    /// Records an XPC service interaction
    /// - Parameters:
    ///   - success: Whether interaction succeeded
    ///   - error: Optional error message
    ///   - metadata: Additional context
    public func recordXPC(
        success: Bool = true,
        error: String? = nil,
        metadata: [String: String] = [:]
    ) {
        queue.async {
            self.xpcCount += 1
            if !success {
                self.failureCount += 1
            }
            self.logMetric(
                type: "xpc",
                success: success,
                error: error,
                metadata: metadata
            )
        }
    }

    // MARK: - Session Management

    /// Increments active access count
    public func incrementActiveAccess() {
        queue.async {
            self.activeAccessCount += 1
            self.logMetric(
                type: "session",
                success: true,
                metadata: ["action": "start"]
            )
        }
    }

    /// Decrements active access count
    public func decrementActiveAccess() {
        queue.async {
            self.activeAccessCount = max(0, self.activeAccessCount - 1)
            self.logMetric(
                type: "session",
                success: true,
                metadata: ["action": "end"]
            )
        }
    }

    // MARK: Internal

    // MARK: - Metrics

    /// Total number of access attempts (successful and failed)
    private(set) var accessCount: Int = 0

    /// Total number of permission requests
    private(set) var permissionCount: Int = 0

    /// Total number of bookmark operations
    private(set) var bookmarkCount: Int = 0

    /// Total number of XPC service interactions
    private(set) var xpcCount: Int = 0

    /// Total number of security operation failures
    private(set) var failureCount: Int = 0

    /// Current number of active access sessions
    private(set) var activeAccessCount: Int = 0

    /// Chronological history of security operations
    private(set) var operationHistory: [SecurityOperation] = []

    // MARK: Private

    /// Logger instance for recording metric events
    private let logger: Logger

    /// Queue for synchronizing metric updates
    private let queue: DispatchQueue

    /// Maximum number of operations to keep in history
    private let maxHistorySize: Int

    // MARK: - History Management

    /// Adds an operation to history
    /// - Parameter operation: Operation to record
    private func addToHistory(_ operation: SecurityOperation) {
        operationHistory.append(operation)
        if operationHistory.count > maxHistorySize {
            operationHistory.removeFirst()
        }
    }

    // MARK: - Private Methods

    /// Logs a metric event with metadata
    /// - Parameters:
    ///   - type: Type of metric
    ///   - success: Whether operation succeeded
    ///   - error: Optional error message
    ///   - metadata: Additional context
    private func logMetric(
        type: String,
        success: Bool,
        error: String? = nil,
        metadata: [String: String] = [:]
    ) {
        var logMetadata = [
            "type": type,
            "success": String(success),
            "timestamp": Date().ISO8601Format(),
        ]

        // Add error if present
        if let error {
            logMetadata["error"] = error
        }

        // Add custom metadata
        logMetadata.merge(metadata) { current, _ in current }

        // Create log configuration
        let config = LogConfig(metadata: logMetadata)

        // Log with appropriate level
        if success {
            logger.info("\(type) operation completed", config: config)
        } else {
            logger.error(
                "\(type) operation failed: \(error ?? "Unknown error")",
                config: config
            )
        }
    }
}

// MARK: - LogConfig

/// Configuration for metric logging
private struct LogConfig {
    /// Metadata for the log entry
    let metadata: [String: String]
}
