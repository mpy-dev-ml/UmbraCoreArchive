import Foundation

extension ServiceLifecycle {
    /// Update service state with logging
    /// - Parameter newState: New state to transition to
    func updateState(_ newState: ServiceState) {
        let oldState = state
        (self as? StateManaged)?.state = newState

        logger.debug(
            "Service state changed: \(oldState.rawValue) -> \(newState.rawValue)",
            file: #file,
            function: #function,
            line: #line
        )
    }

    /// Update service state and handle errors
    /// - Parameters:
    ///   - operation: Operation being performed
    ///   - work: Work to perform
    /// - Throws: Any error from the work
    func withErrorHandling<T>(
        operation: String,
        work: () throws -> T
    ) throws -> T {
        do {
            return try work()
        } catch {
            updateState(.error)

            logger.error(
                """
                Error during '\(operation)': \(error.localizedDescription)
                Service state: \(state.rawValue)
                """,
                file: #file,
                function: #function,
                line: #line
            )

            throw error
        }
    }

    /// Update service state and handle errors asynchronously
    /// - Parameters:
    ///   - operation: Operation being performed
    ///   - work: Work to perform
    /// - Throws: Any error from the work
    func withErrorHandling<T>(
        operation: String,
        work: () async throws -> T
    ) async throws -> T {
        do {
            return try await work()
        } catch {
            updateState(.error)

            logger.error(
                """
                Error during '\(operation)': \(error.localizedDescription)
                Service state: \(state.rawValue)
                """,
                file: #file,
                function: #function,
                line: #line
            )

            throw error
        }
    }
}

// MARK: - StateManaged

/// Protocol for services that manage their own state
protocol StateManaged: AnyObject {
    /// Current state of the service
    var state: ServiceState { get set }
}
