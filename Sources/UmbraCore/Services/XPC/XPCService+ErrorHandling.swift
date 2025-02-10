import Foundation
import os.log

// MARK: - Error Handling

extension XPCService {
    /// Handle connection interruption
    func handleInterruption() {
        queue.async { [weak self] in
            guard let self = self else { return }
            logInterruption()
            if configuration.autoReconnect {
                Task { try await self.reconnect() }
            }
        }
    }

    /// Handle connection invalidation
    func handleInvalidation() {
        queue.async { [weak self] in
            guard let self = self else { return }
            logInvalidation()
            connection = nil
            connectionState = .disconnected
        }
    }

    /// Handle connection errors
    func handleConnectionError(_ error: Error) {
        queue.async { [weak self] in
            guard let self = self else { return }
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

// MARK: - Error Reasons

extension XPCError {
    enum Reason {
        case serviceInstanceDeallocated
        case invalidConnectionState(XPCConnectionState)
        case noActiveConnection
        case invalidProxyType(Any.Type)
        case maxRetryAttemptsExceeded
        case operationTimeout(TimeInterval)

        var description: String {
            switch self {
            case .serviceInstanceDeallocated:
                return "Service instance was deallocated"
            case .invalidConnectionState(let state):
                return "Cannot connect while in state: \(state.description)"
            case .noActiveConnection:
                return "No active connection available"
            case .invalidProxyType(let type):
                return "Failed to cast proxy to type: \(type)"
            case .maxRetryAttemptsExceeded:
                return "Maximum retry attempts exceeded"
            case .operationTimeout(let seconds):
                return "Operation timed out after \(seconds) seconds"
            }
        }
    }
}
