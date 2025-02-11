import Foundation
import os.log

// MARK: - SecurityOperationRecorder

/// Records and logs security-related operations in the system
///
/// Provides thread-safe recording and logging of security operations with:
/// - Operation success/failure tracking
/// - Error logging with context
/// - Custom metadata support
/// - Asynchronous logging
@available(macOS 13.0, *)
public struct SecurityOperationRecorder {
    // MARK: - Properties

    private let logger: Logger
    private let queue: DispatchQueue

    // MARK: - Initialization

    /// Creates a new security operation recorder
    /// - Parameters:
    ///   - logger: Logger for recording operations
    ///   - label: Queue label for synchronisation
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

    // MARK: - Public Methods

    /// Records a security operation
    /// - Parameters:
    ///   - url: URL of the operation target
    ///   - type: Operation type
    ///   - status: Operation outcome
    ///   - error: Optional error message
    ///   - metadata: Additional context
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

    /// Records a security operation failure
    /// - Parameters:
    ///   - url: URL of the operation target
    ///   - type: Operation type
    ///   - error: Error that occurred
    ///   - metadata: Additional context
    public func recordError(
        url: URL,
        type: SecurityOperationType,
        error: Error,
        metadata: [String: String] = [:]
    ) {
        recordOperation(
            url: url,
            type: type,
            status: OperationStatus.failure,
            error: error.localizedDescription,
            metadata: metadata
        )
    }

    // MARK: - Private Methods

    private func logOperation(
        _ operation: SecurityOperation,
        metadata: [String: String]
    ) {
        let baseMetadata = createBaseMetadata(for: operation)
        let finalMetadata = mergeFinalMetadata(
            base: baseMetadata,
            error: operation.error,
            custom: metadata
        )
        let config = LogConfig(metadata: finalMetadata)
        logWithAppropriateLevel(operation, config: config)
    }

    private func createBaseMetadata(
        for operation: SecurityOperation
    ) -> [String: String] {
        [
            "type": operation.operationType.rawValue,
            "url": operation.url.lastPathComponent,
            "status": operation.status.rawValue,
            "timestamp": operation.timestamp.ISO8601Format()
        ]
    }

    private func mergeFinalMetadata(
        base: [String: String],
        error: String?,
        custom: [String: String]
    ) -> [String: String] {
        var final = base
        if let error {
            final["error"] = error
        }
        final.merge(custom) { current, _ in current }
        return final
    }

    private func logWithAppropriateLevel(
        _ operation: SecurityOperation,
        config: LogConfig
    ) {
        let path = operation.url.lastPathComponent
        let type = operation.operationType.rawValue

        switch operation.status {
        case .success:
            logger.info(
                "Security operation \(type) succeeded for \(path)",
                config: config
            )
        case .failure:
            let error = operation.error ?? "Unknown error"
            logger.error(
                "Security operation \(type) failed for \(path): \(error)",
                config: config
            )
        case .pending:
            logger.debug(
                "Security operation \(type) pending for \(path)",
                config: config
            )
        case .cancelled:
            logger.notice(
                "Security operation \(type) cancelled for \(path)",
                config: config
            )
        }
    }
}

// MARK: - LogConfig

/// Configuration for security operation logging
private struct LogConfig {
    /// Metadata for the log entry
    let metadata: [String: String]
}
