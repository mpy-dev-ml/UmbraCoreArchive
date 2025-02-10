//
// BaseService.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation
import os.log

/// Base class providing common service functionality
open class BaseService: NSObject, LoggingService {
    /// Logger for tracking operations
    public let logger: LoggerProtocol

    /// Initialize with a logger
    /// - Parameter logger: Logger for tracking operations
    public init(logger: LoggerProtocol) {
        self.logger = logger
        super.init()
    }

    /// Execute an operation with retry logic
    /// - Parameters:
    ///   - attempts: Maximum number of attempts (default: 3)
    ///   - delay: Delay between attempts in seconds (default: 1.0)
    ///   - operation: Name of the operation for logging
    ///   - action: The operation to execute
    /// - Returns: The result of the operation
    /// - Throws: The last error encountered if all attempts fail
    public func withRetry<T>(
        attempts: Int = 3,
        delay: TimeInterval = 1.0,
        operation: String,
        action: () async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 1...attempts {
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

        throw lastError ?? ServiceError.operationFailed(operation)
    }

    /// Execute an operation with timeout
    /// - Parameters:
    ///   - timeout: Maximum time to wait in seconds
    ///   - operation: Name of the operation for logging
    ///   - action: The operation to execute
    /// - Returns: The result of the operation
    /// - Throws: ServiceError.timeout if the operation exceeds the timeout
    public func withTimeout<T>(
        timeout: TimeInterval,
        operation: String,
        action: () async throws -> T
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
                Operation '\(operation)' timed out after \(timeout) seconds: \
                \(error.localizedDescription)
                """,
                file: #file,
                function: #function,
                line: #line
            )
            throw ServiceError.timeout(operation)
        }
    }
}

/// Common service errors
public enum ServiceError: LocalizedError {
    /// Operation failed after all retry attempts
    case operationFailed(String)
    /// Operation timed out
    case timeout(String)

    public var errorDescription: String? {
        switch self {
        case .operationFailed(let operation):
            return "Operation '\(operation)' failed after all retry attempts"
        case .timeout(let operation):
            return "Operation '\(operation)' timed out"
        }
    }
}
