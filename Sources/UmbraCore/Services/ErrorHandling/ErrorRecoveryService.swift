//
// ErrorRecoveryService.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Service for error recovery operations
public final class ErrorRecoveryService: BaseSandboxedService {
    // MARK: - Types

    /// Recovery operation
    public struct RecoveryOperation {
        /// Operation identifier
        public let id: String

        /// Operation description
        public let description: String

        /// Priority level
        public let priority: Priority

        /// Recovery function
        public let recover: () async throws -> Void

        /// Initialize with values
        public init(
            id: String,
            description: String,
            priority: Priority = .normal,
            recover: @escaping () async throws -> Void
        ) {
            self.id = id
            self.description = description
            self.priority = priority
            self.recover = recover
        }
    }

    /// Priority level
    public enum Priority: Int, Comparable {
        case low = 0
        case normal = 1
        case high = 2
        case critical = 3

        public static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// Recovery result
    public struct RecoveryResult {
        /// Whether recovery succeeded
        public let succeeded: Bool

        /// Duration of recovery
        public let duration: TimeInterval

        /// Any error that occurred
        public let error: Error?

        /// Additional details
        public let details: [String: Any]

        /// Initialize with values
        public init(
            succeeded: Bool,
            duration: TimeInterval,
            error: Error? = nil,
            details: [String: Any] = [:]
        ) {
            self.succeeded = succeeded
            self.duration = duration
            self.error = error
            self.details = details
        }
    }

    // MARK: - Properties

    /// Recovery operations
    private var operations: [RecoveryOperation] = []

    /// Queue for synchronizing operations
    private let queue = DispatchQueue(
        label: "dev.mpy.umbracore.recovery",
        qos: .userInitiated,
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
        self.performanceMonitor = performanceMonitor
        super.init(logger: logger)
    }

    // MARK: - Public Methods

    /// Register recovery operation
    /// - Parameter operation: Operation to register
    public func registerOperation(_ operation: RecoveryOperation) {
        queue.async(flags: .barrier) {
            self.operations.append(operation)
            self.operations.sort { $0.priority > $1.priority }

            self.logger.debug(
                """
                Registered recovery operation:
                ID: \(operation.id)
                Description: \(operation.description)
                Priority: \(operation.priority)
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Run recovery operations
    /// - Parameter priority: Optional minimum priority
    /// - Returns: Dictionary of results by operation ID
    /// - Throws: Error if recovery fails
    public func runRecovery(
        minPriority: Priority = .low
    ) async throws -> [String: RecoveryResult] {
        try validateUsable(for: "runRecovery")

        let operations = queue.sync {
            self.operations.filter { $0.priority >= minPriority }
        }

        var results: [String: RecoveryResult] = [:]

        for operation in operations {
            do {
                let start = Date()
                try await operation.recover()
                let duration = Date().timeIntervalSince(start)

                results[operation.id] = RecoveryResult(
                    succeeded: true,
                    duration: duration
                )

                logger.info(
                    """
                    Recovery operation succeeded:
                    ID: \(operation.id)
                    Duration: \(duration)s
                    """,
                    file: #file,
                    function: #function,
                    line: #line
                )
            } catch {
                results[operation.id] = RecoveryResult(
                    succeeded: false,
                    duration: 0,
                    error: error
                )

                logger.error(
                    """
                    Recovery operation failed:
                    ID: \(operation.id)
                    Error: \(error)
                    """,
                    file: #file,
                    function: #function,
                    line: #line
                )

                if operation.priority == .critical {
                    throw error
                }
            }
        }

        return results
    }

    /// Remove recovery operation
    /// - Parameter id: Operation ID
    public func removeOperation(withId id: String) {
        queue.async(flags: .barrier) {
            self.operations.removeAll { $0.id == id }

            self.logger.debug(
                "Removed recovery operation: \(id)",
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Clear all recovery operations
    public func clearOperations() {
        queue.async(flags: .barrier) {
            self.operations.removeAll()

            self.logger.debug(
                "Cleared all recovery operations",
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Get registered operations
    /// - Returns: Array of operations
    public func getOperations() -> [RecoveryOperation] {
        queue.sync { operations }
    }
}
