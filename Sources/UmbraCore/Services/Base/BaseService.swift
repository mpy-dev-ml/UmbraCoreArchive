import Foundation
import os.log

// MARK: - BaseService

/// Base class providing common service functionality
open class BaseService: NSObject, LoggingServiceProtocol, @unchecked Sendable {
    // MARK: Lifecycle

    /// Initialize with a logger
    /// - Parameter logger: Logger for tracking operations
    public init(logger: LoggerProtocol) {
        self.logger = logger
        super.init()
    }

    // MARK: Public

    /// Logger for tracking operations
    public let logger: LoggerProtocol

    /// Execute an operation with retry logic
    /// - Parameters:
    ///   - attempts: Maximum number of attempts (default: 3)
    ///   - delay: Delay between attempts in seconds (default: 1.0)
    ///   - operation: Name of the operation for logging
    ///   - action: The operation to execute
    /// - Returns: The result of the operation
    /// - Throws: The last error encountered if all attempts fail
    public func withRetry<T: Sendable>(
        attempts: Int = 3,
        delay: TimeInterval = 1.0,
        operation: String,
        action: @Sendable () async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 1 ... attempts {
            do {
                return try await action()
            } catch {
                lastError = error
                logger.warning(
                    """
                    Attempt \(attempt)/\(attempts) failed for operation '\(operation)': \
                    \(error.localizedDescription)
                    """,
                    file: #file,
                    function: #function,
                    line: #line
                )

                if attempt < attempts {
                    try await Task.sleep(
                        nanoseconds: UInt64(delay * 1_000_000_000)
                    )
                }
            }
        }

        throw lastError ?? ServiceError.operationFailed(
            service: String(describing: type(of: self)),
            operation: operation,
            reason: "Operation failed after \(attempts) attempts"
        )
    }

    /// Execute an operation with a timeout
    /// - Parameters:
    ///   - timeout: Maximum time to wait for operation
    ///   - operation: Description of the operation
    ///   - action: Operation to execute
    /// - Returns: The result of the operation
    /// - Throws: ServiceError.timeout if the operation exceeds the timeout
    public func withTimeout<T: Sendable>(
        timeout: TimeInterval,
        operation: String,
        action: @Sendable () async throws -> T
    ) async throws -> T {
        let task = Task {
            try await action()
        }

        do {
            return try await task.value
        } catch {
            task.cancel()
            logger.error(
                """
                Operation timed out after \(timeout) seconds
                Operation: \(operation)
                Error: \(error)
                """,
                file: #file,
                function: #function,
                line: #line
            )
            throw ServiceError.timeout(
                service: String(describing: type(of: self)),
                operation: operation,
                duration: timeout
            )
        }
    }
}
