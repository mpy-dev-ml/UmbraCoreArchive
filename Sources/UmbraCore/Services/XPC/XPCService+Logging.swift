import Foundation
import Logging

// MARK: - Logging

extension XPCService {
    /// Configure logging for the XPC service
    /// - Parameter logger: The logger to use
    public func configureLogging(_ logger: UmbraLogger) {
        self.logger = logger
    }
    
    /// Log a message at the specified level
    /// - Parameters:
    ///   - level: The severity level
    ///   - message: The message to log
    ///   - metadata: Additional metadata
    ///   - source: Source file
    ///   - function: Function name
    ///   - line: Line number
    internal func log(
        level: Logger.Level,
        _ message: String,
        metadata: Logger.Metadata? = nil,
        source: String? = #file,
        function: String? = #function,
        line: UInt? = #line
    ) {
        logger?.log(
            level: level,
            message: message,
            metadata: metadata,
            source: source,
            function: function,
            line: line
        )
    }
    
    /// Log a debug message
    internal func debug(
        _ message: String,
        metadata: Logger.Metadata? = nil,
        source: String? = #file,
        function: String? = #function,
        line: UInt? = #line
    ) {
        log(level: .debug, message, metadata: metadata, source: source, function: function, line: line)
    }
    
    /// Log an info message
    internal func info(
        _ message: String,
        metadata: Logger.Metadata? = nil,
        source: String? = #file,
        function: String? = #function,
        line: UInt? = #line
    ) {
        log(level: .info, message, metadata: metadata, source: source, function: function, line: line)
    }
    
    /// Log a warning message
    internal func warning(
        _ message: String,
        metadata: Logger.Metadata? = nil,
        source: String? = #file,
        function: String? = #function,
        line: UInt? = #line
    ) {
        log(level: .warning, message, metadata: metadata, source: source, function: function, line: line)
    }
    
    /// Log an error message
    internal func error(
        _ message: String,
        metadata: Logger.Metadata? = nil,
        source: String? = #file,
        function: String? = #function,
        line: UInt? = #line
    ) {
        log(level: .error, message, metadata: metadata, source: source, function: function, line: line)
    }

    /// Log successful connection
    func logConnectionEstablished() {
        info(
            "Connected to XPC service",
            metadata: createConnectionMetadata()
        )
    }

    /// Log disconnection
    func logDisconnection() {
        info(
            "Disconnected from XPC service",
            metadata: createConnectionMetadata()
        )
    }

    /// Log connection interruption
    func logInterruption() {
        warning(
            "XPC connection interrupted",
            metadata: createInterruptionMetadata()
        )
    }

    /// Log connection invalidation
    func logInvalidation() {
        error(
            "XPC connection invalidated",
            metadata: createConnectionMetadata()
        )
    }

    /// Log connection error
    func logConnectionError(_ error: Error) {
        error(
            "XPC connection error",
            metadata: createErrorMetadata(error)
        )
    }

    /// Log reconnection attempt
    func logReconnectionAttempt() {
        info(
            "Attempting to reconnect to XPC service",
            metadata: createReconnectionMetadata()
        )
    }

    /// Create base connection metadata
    func createConnectionMetadata() -> Logger.Metadata {
        [
            "service": configuration.serviceName,
            "state": connectionState.description
        ]
    }

    /// Create interruption metadata
    func createInterruptionMetadata() -> Logger.Metadata {
        [
            "service": configuration.serviceName,
            "retry_count": String(retryCount)
        ]
    }

    /// Create error metadata
    func createErrorMetadata(_ error: Error) -> Logger.Metadata {
        [
            "service": configuration.serviceName,
            "error": String(describing: error)
        ]
    }

    /// Create reconnection metadata
    func createReconnectionMetadata() -> Logger.Metadata {
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
        debug(
            "XPC connection state changed",
            metadata: createStateChangeMetadata(oldState, newState)
        )
    }

    /// Create state change metadata
    func createStateChangeMetadata(
        _ oldState: XPCConnectionState,
        _ newState: XPCConnectionState
    ) -> Logger.Metadata {
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
