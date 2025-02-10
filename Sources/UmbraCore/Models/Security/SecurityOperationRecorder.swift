import Foundation
import os.log

// MARK: - SecurityOperationRecorder

/// Records and logs security-related operations in the system
///
/// `SecurityOperationRecorder` provides thread-safe recording and logging of
/// security operations. It supports:
/// - Operation success/failure tracking
/// - Error logging with context
/// - Custom metadata attachment
/// - Asynchronous logging
///
/// Example usage:
/// ```swift
/// let recorder = SecurityOperationRecorder(
///     logger: Logger(subsystem: "com.umbra.core", category: "security")
/// )
///
/// // Record successful operation
/// recorder.recordOperation(
///     url: fileURL,
///     type: .access,
///     status: .success,
///     metadata: ["context": "backup"]
/// )
///
/// // Record operation with error
/// do {
///     try accessFile(at: fileURL)
/// } catch {
///     recorder.recordError(
///         url: fileURL,
///         type: .access,
///         error: error,
///         metadata: ["attempt": "3"]
///     )
/// }
/// ```
@available(macOS 13.0, *)
public struct SecurityOperationRecorder {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Creates a new security operation recorder
    /// - Parameters:
    ///   - logger: Logger instance for recording operations
    ///   - label: Queue label for synchronisation (defaults to bundle identifier)
    ///
    /// Example:
    /// ```swift
    /// let recorder = SecurityOperationRecorder(
    ///     logger: Logger(
    ///         subsystem: "com.umbra.core",
    ///         category: "security"
    ///     ),
    ///     label: "com.umbra.core.security"
    /// )
    /// ```
    public init(
        logger: Logger,
        label: String = Bundle.main.bundleIdentifier ?? "com.umbra.core"
    ) {
        self.logger = logger
        queue = DispatchQueue(
            label: "\(label).security-recorder",
            qos: .utility
        )
    }

    // MARK: Public

    // MARK: - Recording Operations

    /// Records a security operation
    /// - Parameters:
    ///   - url: URL associated with the operation
    ///   - type: Type of security operation
    ///   - status: Operation status
    ///   - error: Optional error message
    ///   - metadata: Additional metadata
    ///
    /// Example:
    /// ```swift
    /// recorder.recordOperation(
    ///     url: fileURL,
    ///     type: .bookmark,
    ///     status: .success,
    ///     metadata: [
    ///         "context": "backup",
    ///         "path": fileURL.path
    ///     ]
    /// )
    /// ```
    public func recordOperation(
        url: URL,
        type: SecurityOperationType,
        status: SecurityOperationStatus,
        error: String? = nil,
        metadata: [String: String] = [:]
    ) {
        queue.async {
            let operation = SecurityOperation(
                url: url,
                operationType: type,
                timestamp: Date(),
                status: status,
                error: error
            )

            logOperation(operation, metadata: metadata)
        }
    }

    /// Records a security operation with error
    /// - Parameters:
    ///   - url: URL associated with the operation
    ///   - type: Type of security operation
    ///   - error: Error that occurred
    ///   - metadata: Additional metadata
    ///
    /// Example:
    /// ```swift
    /// do {
    ///     try createBookmark(for: fileURL)
    /// } catch {
    ///     recorder.recordError(
    ///         url: fileURL,
    ///         type: .bookmark,
    ///         error: error,
    ///         metadata: [
    ///             "context": "backup",
    ///             "attempt": "3"
    ///         ]
    ///     )
    /// }
    /// ```
    public func recordError(
        url: URL,
        type: SecurityOperationType,
        error: Error,
        metadata: [String: String] = [:]
    ) {
        recordOperation(
            url: url,
            type: type,
            status: .failure,
            error: error.localizedDescription,
            metadata: metadata
        )
    }

    // MARK: Private

    /// Logger instance for recording operations
    ///
    /// Used to write operation logs with appropriate:
    /// - Log levels
    /// - Subsystem categorisation
    /// - Privacy redaction
    private let logger: Logger

    /// Queue for synchronizing operation recording
    ///
    /// Dedicated serial queue that ensures:
    /// - Thread-safe logging
    /// - Ordered operation records
    /// - Non-blocking main thread
    private let queue: DispatchQueue

    // MARK: - Private Methods

    /// Logs a security operation with metadata
    /// - Parameters:
    ///   - operation: Operation to log
    ///   - metadata: Additional metadata
    private func logOperation(
        _ operation: SecurityOperation,
        metadata: [String: String]
    ) {
        let logMetadata: [String: String] = [
            "type": operation.operationType.rawValue,
            "url": operation.url.lastPathComponent,
            "status": operation.status.rawValue,
            "timestamp": operation.timestamp.ISO8601Format(),
        ]

        // Add error if present
        var finalMetadata = logMetadata
        if let error = operation.error {
            finalMetadata["error"] = error
        }

        // Add custom metadata
        finalMetadata.merge(metadata) { current, _ in current }

        // Create log configuration
        let config = LogConfig(metadata: finalMetadata)

        // Log with appropriate level
        let pathComponent = operation.url.lastPathComponent
        let opType = operation.operationType.rawValue

        switch operation.status {
        case .success:
            logger.info(
                "Security operation \(opType) completed successfully for \(pathComponent)",
                config: config
            )

        case .failure:
            let errorMessage = operation.error ?? "Unknown error"
            logger.error(
                "Security operation \(opType) failed for \(pathComponent): \(errorMessage)",
                config: config
            )

        case .pending:
            logger.debug(
                "Security operation \(opType) pending for \(pathComponent)",
                config: config
            )

        case .cancelled:
            logger.notice(
                "Security operation \(opType) cancelled for \(pathComponent)",
                config: config
            )
        }
    }
}

// MARK: - LogConfig

/// Configuration for security operation logging
///
/// Encapsulates metadata and configuration options for log entries
private struct LogConfig {
    /// Metadata for the log entry
    ///
    /// Contains operation-specific information such as:
    /// - Operation type and status
    /// - Resource identifiers
    /// - Timestamps
    /// - Custom context
    let metadata: [String: String]
}
