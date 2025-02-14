@preconcurrency import Foundation
import os.log

// MARK: - Error Handling

extension XPCService {
    /// Handle connection interruption
    func handleInterruption() {
        queue.async { [weak self] in
            guard let self else {
                return
            }
            logInterruption()
            if configuration.autoReconnect {
                Task { try await self.reconnect() }
            }
        }
    }

    /// Handle connection invalidation
    func handleInvalidation() {
        queue.async { [weak self] in
            guard let self else {
                return
            }
            logInvalidation()
            connection = nil
            connectionState = .disconnected
        }
    }

    /// Handle connection errors
    func handleConnectionError(_ error: Error) {
        queue.async { [weak self] in
            guard let self else {
                return
            }
            logConnectionError(error)
            if configuration.autoReconnect {
                Task { try await self.reconnect() }
            }
        }
    }

    /// Attempt to reconnect to the service
    func reconnect() async throws {
        guard retryCount < configuration.maxRetryAttempts else {
            throw XPCError.reconnectionFailed(
                reason: .maxRetryAttemptsExceeded
            )
        }

        retryCount += 1
        logReconnectionAttempt()

        try await Task.sleep(
            nanoseconds: UInt64(configuration.retryDelay * 1_000_000_000)
        )

        try await connect()
    }
}

// MARK: - XPCError.Reason

extension XPCError {
    enum Reason {
        case serviceInstanceDeallocated
        case invalidConnectionState(XPCConnectionState)
        case noActiveConnection
        case invalidProxyType(Any.Type)
        case maxRetryAttemptsExceeded
        case operationTimeout(TimeInterval)

        // MARK: Internal

        var description: String {
            switch self {
            case .serviceInstanceDeallocated:
                "Service instance was deallocated"

            case let .invalidConnectionState(state):
                "Cannot connect while in state: \(state.description)"

            case .noActiveConnection:
                "No active connection available"

            case let .invalidProxyType(type):
                "Failed to cast proxy to type: \(type)"

            case .maxRetryAttemptsExceeded:
                "Maximum retry attempts exceeded"

            case let .operationTimeout(seconds):
                "Operation timed out after \(seconds) seconds"
            }
        }
    }
}
