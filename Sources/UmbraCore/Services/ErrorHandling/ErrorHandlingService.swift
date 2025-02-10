import Foundation

// MARK: - ErrorHandlingService

/// Service for handling and recovering from errors
public final class ErrorHandlingService: BaseSandboxedService {
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
        self.performanceMonitor = performanceMonitor
        super.init(logger: logger)
        registerDefaultHandlers()
    }

    // MARK: Public

    // MARK: - Types

    /// Error recovery strategy
    public enum RecoveryStrategy {
        /// Retry the operation
        case retry(maxAttempts: Int, delay: TimeInterval)
        /// Use fallback value
        case fallback(Any)
        /// Clean up and continue
        case cleanup(cleanup: () async throws -> Void)
        /// Terminate operation
        case terminate
    }

    /// Error context
    public struct ErrorContext {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            error: Error,
            operation: String,
            file: String = #file,
            function: String = #function,
            line: Int = #line,
            timestamp: Date = Date(),
            metadata: [String: Any] = [:]
        ) {
            self.error = error
            self.operation = operation
            self.file = file
            self.function = function
            self.line = line
            self.timestamp = timestamp
            self.metadata = metadata
        }

        // MARK: Public

        /// Source error
        public let error: Error

        /// Operation name
        public let operation: String

        /// Source file
        public let file: String

        /// Source function
        public let function: String

        /// Source line
        public let line: Int

        /// Timestamp
        public let timestamp: Date

        /// Additional metadata
        public let metadata: [String: Any]
    }

    /// Error handler
    public typealias ErrorHandler = (ErrorContext) async throws -> RecoveryStrategy

    // MARK: - Public Methods

    /// Register error handler
    /// - Parameters:
    ///   - handler: Error handler
    ///   - type: Error type identifier
    public func registerHandler(
        _ handler: @escaping ErrorHandler,
        forType type: String
    ) {
        queue.async(flags: .barrier) {
            self.handlers[type] = handler

            self.logger.debug(
                "Registered error handler for type: \(type)",
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Handle error
    /// - Parameter context: Error context
    /// - Returns: Recovery strategy
    /// - Throws: Error if handling fails
    public func handleError(_ context: ErrorContext) async throws -> RecoveryStrategy {
        try validateUsable(for: "handleError")

        return try await performanceMonitor.trackDuration(
            "error.handle.\(context.operation)"
        ) {
            // Log error
            logger.error(
                """
                Error occurred:
                Operation: \(context.operation)
                Error: \(context.error)
                File: \(context.file)
                Function: \(context.function)
                Line: \(context.line)
                Metadata: \(context.metadata)
                """,
                file: context.file,
                function: context.function,
                line: context.line
            )

            // Find handler
            let errorType = String(describing: type(of: context.error))
            let handler = queue.sync { handlers[errorType] }

            guard let handler else {
                logger.warning(
                    "No handler found for error type: \(errorType)",
                    file: context.file,
                    function: context.function,
                    line: context.line
                )
                return .terminate
            }

            // Handle error
            do {
                let strategy = try await handler(context)

                logger.info(
                    """
                    Error handled:
                    Operation: \(context.operation)
                    Type: \(errorType)
                    Strategy: \(String(describing: strategy))
                    """,
                    file: context.file,
                    function: context.function,
                    line: context.line
                )

                return strategy
            } catch {
                logger.error(
                    """
                    Error handler failed:
                    Operation: \(context.operation)
                    Type: \(errorType)
                    Error: \(error)
                    """,
                    file: context.file,
                    function: context.function,
                    line: context.line
                )
                throw error
            }
        }
    }

    /// Run operation with error handling
    /// - Parameters:
    ///   - operation: Operation name
    ///   - metadata: Additional metadata
    ///   - work: Work to perform
    /// - Returns: Result of operation
    /// - Throws: Error if operation fails
    public func run<T>(
        operation: String,
        metadata: [String: Any] = [:],
        work: () async throws -> T
    ) async throws -> T {
        try validateUsable(for: "run")

        do {
            return try await work()
        } catch {
            let context = ErrorContext(
                error: error,
                operation: operation,
                metadata: metadata
            )

            let strategy = try await handleError(context)

            switch strategy {
            case let .retry(maxAttempts, delay):
                return try await retry(
                    operation: operation,
                    maxAttempts: maxAttempts,
                    delay: delay,
                    work: work
                )
            case let .fallback(value):
                guard let result = value as? T else {
                    throw ErrorHandlingError.invalidFallbackValue(
                        "Expected type \(T.self), got \(type(of: value))"
                    )
                }
                return result
            case let .cleanup(cleanup):
                try await cleanup()
                throw error
            case .terminate:
                throw error
            }
        }
    }

    // MARK: Private

    /// Error handlers by type
    private var handlers: [String: ErrorHandler] = [:]

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.error",
        qos: .userInitiated,
        attributes: .concurrent
    )

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    // MARK: - Private Methods

    /// Register default error handlers
    private func registerDefaultHandlers() {
        // Handle URL errors
        registerHandler({ context in
            if let error = context.error as? URLError {
                switch error.code {
                case .notConnectedToInternet,
                     .networkConnectionLost:
                    return .retry(maxAttempts: 3, delay: 1.0)
                case .timedOut:
                    return .retry(maxAttempts: 2, delay: 2.0)
                default:
                    return .terminate
                }
            }
            return .terminate
        }, forType: "URLError")

        // Handle file system errors
        registerHandler({ context in
            if let error = context.error as? CocoaError {
                switch error.code {
                case .fileNoSuchFile:
                    return .cleanup { /* Clean up missing file references */ }
                case .fileReadNoPermission:
                    return .terminate
                default:
                    return .retry(maxAttempts: 2, delay: 1.0)
                }
            }
            return .terminate
        }, forType: "CocoaError")
    }

    /// Retry an operation
    private func retry<T>(
        operation: String,
        maxAttempts: Int,
        delay: TimeInterval,
        work: () async throws -> T
    ) async throws -> T {
        var attempts = 0
        var lastError: Error?

        while attempts < maxAttempts {
            do {
                return try await work()
            } catch {
                attempts += 1
                lastError = error

                logger.warning(
                    """
                    Retrying operation:
                    Operation: \(operation)
                    Attempt: \(attempts)/\(maxAttempts)
                    Error: \(error)
                    """,
                    file: #file,
                    function: #function,
                    line: #line
                )

                if attempts < maxAttempts {
                    try await Task.sleep(
                        nanoseconds: UInt64(delay * 1_000_000_000)
                    )
                }
            }
        }

        throw lastError ?? ErrorHandlingError.maxRetriesExceeded(operation)
    }
}

// MARK: - ErrorHandlingError

/// Errors that can occur during error handling
public enum ErrorHandlingError: LocalizedError {
    /// Invalid fallback value
    case invalidFallbackValue(String)
    /// Maximum retries exceeded
    case maxRetriesExceeded(String)
    /// Error handling failed
    case errorHandlingFailed(String)

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case let .invalidFallbackValue(reason):
            "Invalid fallback value: \(reason)"
        case let .maxRetriesExceeded(operation):
            "Maximum retries exceeded for operation: \(operation)"
        case let .errorHandlingFailed(reason):
            "Error handling failed: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidFallbackValue:
            "Check fallback value type"
        case .maxRetriesExceeded:
            "Check operation and try again later"
        case .errorHandlingFailed:
            "Check error handler implementation"
        }
    }
}
