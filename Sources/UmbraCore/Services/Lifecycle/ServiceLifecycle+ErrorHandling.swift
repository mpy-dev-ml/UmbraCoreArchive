@preconcurrency import Foundation

extension ServiceLifecycle {
    /// Attempt to recover from an error
    /// - Parameter error: Error to recover from
    /// - Returns: true if recovery was successful
    /// - Throws: ServiceLifecycleError if recovery fails
    func attemptRecovery(from error: Error) throws -> Bool {
        logger.warning(
            """
            Attempting recovery from error: \(error.localizedDescription)
            Current state: \(state.rawValue)
            """,
            file: #file,
            function: #function,
            line: #line
        )

        do {
            // Try resetting the service
            try reset()

            // Try restarting if possible
            if state.canStart {
                try start()
            }

            logger.info(
                "Successfully recovered from error",
                file: #file,
                function: #function,
                line: #line
            )

            return true
        } catch {
            logger.error(
                """
                Recovery failed: \(error.localizedDescription)
                Service state: \(state.rawValue)
                """,
                file: #file,
                function: #function,
                line: #line
            )

            throw ServiceLifecycleError.resetFailed(
                "Recovery failed: \(error.localizedDescription)"
            )
        }
    }

    /// Handle a critical error
    /// - Parameter error: Error to handle
    /// - Throws: The original error after cleanup
    func handleCriticalError(_ error: Error) throws {
        logger.critical(
            """
            Critical error encountered: \(error.localizedDescription)
            Service state: \(state.rawValue)
            """,
            file: #file,
            function: #function,
            line: #line
        )

        // Attempt to stop the service
        if state.canStop {
            try? stop()
        }

        // Update state to error
        updateState(.error)

        // Rethrow the error
        throw error
    }

    /// Execute an operation with retry and recovery
    /// - Parameters:
    ///   - attempts: Maximum number of attempts
    ///   - operation: Operation name
    ///   - work: Work to perform
    /// - Returns: Result of the operation
    /// - Throws: Last error encountered
    func withRetryAndRecovery<T>(
        attempts: Int = 3,
        operation: String,
        work: () async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 1 ... attempts {
            do {
                return try await work()
            } catch {
                lastError = error

                logger.warning(
                    """
                    Attempt \(attempt)/\(attempts) failed for '\(operation)': \
                    \(error.localizedDescription)
                    Attempting recovery...
                    """,
                    file: #file,
                    function: #function,
                    line: #line
                )

                if attempt < attempts {
                    // Try to recover
                    if try attemptRecovery(from: error) {
                        continue
                    }
                }
            }
        }

        throw lastError ?? ServiceLifecycleError.operationFailed(operation)
    }
}
