@preconcurrency import Foundation
import os.log

// MARK: - Logging

extension XPCService {
    /// Log successful connection
    func logConnectionEstablished() {
        logger.info(
            "Connected to XPC service",
            metadata: createConnectionMetadata()
        )
    }

    /// Log disconnection
    func logDisconnection() {
        logger.info(
            "Disconnected from XPC service",
            metadata: createConnectionMetadata()
        )
    }

    /// Log connection interruption
    func logInterruption() {
        logger.warning(
            "XPC connection interrupted",
            metadata: createInterruptionMetadata()
        )
    }

    /// Log connection invalidation
    func logInvalidation() {
        logger.error(
            "XPC connection invalidated",
            metadata: createConnectionMetadata()
        )
    }

    /// Log connection error
    func logConnectionError(_ error: Error) {
        logger.error(
            "XPC connection error",
            metadata: createErrorMetadata(error)
        )
    }

    /// Log reconnection attempt
    func logReconnectionAttempt() {
        logger.info(
            "Attempting to reconnect to XPC service",
            metadata: createReconnectionMetadata()
        )
    }

    /// Create base connection metadata
    func createConnectionMetadata() -> [String: String] {
        [
            "service": configuration.serviceName,
            "state": connectionState.description
        ]
    }

    /// Create interruption metadata
    func createInterruptionMetadata() -> [String: String] {
        [
            "service": configuration.serviceName,
            "retry_count": String(retryCount)
        ]
    }

    /// Create error metadata
    func createErrorMetadata(_ error: Error) -> [String: String] {
        [
            "service": configuration.serviceName,
            "error": String(describing: error)
        ]
    }

    /// Create reconnection metadata
    func createReconnectionMetadata() -> [String: String] {
        [
            "service": configuration.serviceName,
            "attempt": String(retryCount),
            "max_attempts": String(configuration.maxRetryAttempts)
        ]
    }
}

// MARK: - State Change Logging

extension XPCService {
    /// Log state change
    func logStateChange(
        _ oldState: XPCConnectionState,
        _ newState: XPCConnectionState
    ) {
        logger.debug(
            "XPC connection state changed",
            metadata: createStateChangeMetadata(oldState, newState)
        )
    }

    /// Create state change metadata
    func createStateChangeMetadata(
        _ oldState: XPCConnectionState,
        _ newState: XPCConnectionState
    ) -> [String: String] {
        [
            "old_state": oldState.description,
            "new_state": newState.description,
            "service": configuration.serviceName
        ]
    }

    /// Create state change notification user info
    func createStateChangeUserInfo(
        _ oldState: XPCConnectionState,
        _ newState: XPCConnectionState
    ) -> [String: Any] {
        [
            "old_state": oldState,
            "new_state": newState,
            "service": configuration.serviceName
        ]
    }
}
