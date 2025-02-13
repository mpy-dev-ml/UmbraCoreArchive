@preconcurrency import Foundation

// MARK: - BaseSandboxedService

/// Base class for services that operate within the sandbox
public class BaseSandboxedService: BaseService {
    // MARK: Lifecycle

    /// Initialize with a logger
    /// - Parameter logger: Logger for tracking operations
    override public init(logger: LoggerProtocol) {
        super.init(logger: logger)
    }

    /// Clean up any resources when the service is being deallocated
    deinit {
        logger.debug(
            "Cleaning up sandboxed service resources",
            file: #file,
            function: #function,
            line: #line
        )
    }

    // MARK: Public

    /// Validate that the service is operating within sandbox constraints
    /// - Returns: true if the service is properly sandboxed
    /// - Throws: SandboxError if validation fails
    public func validateSandboxCompliance() throws -> Bool {
        // Default implementation assumes compliance
        // Subclasses should override this if they need specific validation
        logger.debug(
            "Validating sandbox compliance",
            file: #file,
            function: #function,
            line: #line
        )
        return true
    }

    /// Execute an operation with sandbox validation
    /// - Parameters:
    ///   - operation: Name of the operation for logging
    ///   - action: The operation to execute
    /// - Returns: The result of the operation
    /// - Throws: SandboxError if validation fails or the operation fails
    public func withSandboxValidation<T>(
        operation: String,
        action: () async throws -> T
    ) async throws -> T {
        try await sandboxQueue.sync {
            guard try validateSandboxCompliance() else {
                throw SandboxError.complianceValidationFailed(operation)
            }
            return try await action()
        }
    }

    /// Validate if the service is usable for the given operation
    /// - Parameter operation: Operation being validated
    /// - Returns: True if service is usable
    /// - Throws: ServiceError if service is not usable
    func validateUsable(for operation: String) throws -> Bool {
        guard isUsable else {
            throw ServiceError.serviceNotUsable(
                service: String(describing: type(of: self)),
                operation: operation
            )
        }
        return true
    }

    /// Execute an operation in the sandbox
    /// - Parameters:
    ///   - operation: Operation description
    ///   - action: Action to execute
    /// - Returns: Result of the action
    /// - Throws: Error if operation fails
    func executeSandboxed<T>(
        operation: String,
        action: () async throws -> T
    ) async throws -> T {
        try await sandboxQueue.sync {
            guard try validateUsable(for: operation) else {
                throw ServiceError.serviceNotUsable(
                    service: String(describing: type(of: self)),
                    operation: operation
                )
            }
            return try await action()
        }
    }

    // MARK: Private

    /// Queue for synchronizing sandbox operations
    private let sandboxQueue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.sandbox",
        qos: .userInitiated,
        attributes: .concurrent
    )
}
