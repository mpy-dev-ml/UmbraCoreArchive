@preconcurrency import Foundation
import Logging

// MARK: - ErrorHandlingService

/// Service for handling and recovering from errors
@MainActor
public final class ErrorHandlingService: BaseService {
    // MARK: - Types

    /// Error recovery strategy
    public enum RecoveryStrategy: Sendable {
        /// Retry the operation
        case retry(maxAttempts: Int, delay: TimeInterval)
        /// Use fallback value
        case fallback(Any)
        /// Clean up and continue
        case cleanup(cleanup: @Sendable () async throws -> Void)
        /// Terminate operation
        case terminate
    }

    /// Error context
    public struct ErrorContext: Sendable {
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
    public typealias ErrorHandler = @Sendable (ErrorContext) async throws -> RecoveryStrategy

    // MARK: - Properties

    /// Dictionary of error handlers
    private var handlers: [String: ErrorHandler] = [:]

    /// Queue for synchronizing handler access
    private let queue = DispatchQueue(
        label: "dev.mpy.umbracore.error-handling",
        attributes: .concurrent
    )

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameter logger: Logger for tracking operations
    public init(logger: LoggerProtocol) {
        super.init(logger: logger)
        registerDefaultHandlers()
    }

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
        }
    }

    /// Remove error handler
    /// - Parameter type: Error type identifier
    public func removeHandler(forType type: String) {
        queue.async(flags: .barrier) {
            self.handlers.removeValue(forKey: type)
        }
    }

    /// Execute operation with error handling
    /// - Parameters:
    ///   - operation: Operation name
    ///   - work: Work to execute
    /// - Returns: Result of operation
    /// - Throws: Error if operation fails and cannot be recovered
    public func run<T: Sendable>(
        operation: String,
        work: @Sendable () async throws -> T
    ) async throws -> T {
        do {
            return try await work()
        } catch {
            let context = ErrorContext(error: error, operation: operation)
            let strategy = try await handleError(context)

            switch strategy {
            case let .retry(maxAttempts, delay):
                return try await withRetry(
                    attempts: maxAttempts,
                    delay: delay,
                    operation: operation,
                    action: work
                )

            case let .fallback(value):
                guard let result = value as? T else {
                    throw ErrorHandlingError.invalidFallbackValue(operation)
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

    // MARK: - Private Methods

    /// Register default error handlers
    private func registerDefaultHandlers() {
        // Register default handlers here
    }

    /// Handle error and determine recovery strategy
    /// - Parameter context: Error context
    /// - Returns: Recovery strategy
    /// - Throws: Error if handling fails
    private func handleError(_ context: ErrorContext) async throws -> RecoveryStrategy {
        let errorType = String(describing: type(of: context.error))

        guard let handler = await getHandler(forType: errorType) else {
            logger.warning(
                "No handler registered for error type: \(errorType)",
                metadata: [
                    "error.type": .string(errorType),
                    "error.operation": .string(context.operation)
                ]
            )
            return .terminate
        }

        do {
            let strategy = try await handler(context)
            logSuccessfulHandling(context: context, strategy: strategy)
            return strategy
        } catch {
            logger.error(
                "Error handler failed: \(error.localizedDescription)",
                metadata: [
                    "error.type": .string(errorType),
                    "error.operation": .string(context.operation),
                    "handler.error": .string(String(describing: error))
                ]
            )
            return .terminate
        }
    }

    /// Get error handler for type
    /// - Parameter type: Error type
    /// - Returns: Handler if registered
    private func getHandler(forType type: String) async -> ErrorHandler? {
        await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.handlers[type])
            }
        }
    }

    /// Log successful error handling
    /// - Parameters:
    ///   - context: Error context
    ///   - strategy: Recovery strategy
    private func logSuccessfulHandling(
        context: ErrorContext,
        strategy: RecoveryStrategy
    ) {
        let strategyDescription: String
        switch strategy {
        case let .retry(attempts, delay):
            strategyDescription = "retry (attempts: \(attempts), delay: \(delay))"
        case .fallback:
            strategyDescription = "fallback"
        case .cleanup:
            strategyDescription = "cleanup"
        case .terminate:
            strategyDescription = "terminate"
        }

        logger.info(
            "Successfully handled error",
            metadata: [
                "error.type": .string(String(describing: type(of: context.error))),
                "error.operation": .string(context.operation),
                "recovery.strategy": .string(strategyDescription)
            ]
        )
    }
}

// MARK: - ErrorHandlingError

/// Errors that can occur during error handling
public enum ErrorHandlingError: Error, LocalizedError {
    /// Invalid fallback value
    case invalidFallbackValue(String)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .invalidFallbackValue(operation):
            "Invalid fallback value for operation: \(operation)"
        }
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? {
        switch self {
        case .invalidFallbackValue:
            "The provided fallback value is not compatible with the operation's return type"
        }
    }

    /// A localized message providing "help" text if the user requests help.
    public var helpAnchor: String? {
        switch self {
        case .invalidFallbackValue:
            "error-handling-invalid-fallback"
        }
    }

    /// A localized message describing how one might recover from the failure.
    public var recoverySuggestion: String? {
        switch self {
        case .invalidFallbackValue:
            "Ensure the fallback value matches the expected type of the operation"
        }
    }
}
