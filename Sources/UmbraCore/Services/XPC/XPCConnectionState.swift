// MARK: - XPCConnectionState

/// State of an XPC connection
/// Represents the lifecycle states of an XPC connection, including health and error states
@objc
public enum XPCConnectionState: Int {
    // MARK: - Base States

    /// Connection is disconnected
    /// Initial state or after clean disconnection
    case disconnected

    /// Connection is in process of connecting
    /// Attempting to establish connection
    case connecting

    /// Connection is established and ready
    /// Normal operating state
    case connected

    /// Connection is in process of disconnecting
    /// Clean shutdown in progress
    case disconnecting

    // MARK: - Error States

    /// Connection was interrupted
    /// May be recoverable
    case interrupted

    /// Connection was invalidated
    /// Non-recoverable state
    case invalidated

    /// Connection is in error state
    /// May be recoverable depending on error
    case error

    // MARK: - Health States

    /// Connection is established but degraded
    /// Performance or stability issues detected
    case degraded

    /// Connection is established but needs recovery
    /// Automatic recovery may be possible
    case needsRecovery

    // MARK: Public

    /// Whether the connection is in a terminal state
    public var isTerminal: Bool {
        switch self {
        case .invalidated:
            true
        default:
            false
        }
    }

    /// Whether the connection is active
    public var isActive: Bool {
        switch self {
        case .connected,
             .degraded:
            true
        default:
            false
        }
    }

    /// Whether the connection is recoverable
    public var isRecoverable: Bool {
        switch self {
        case .interrupted,
             .error,
             .degraded,
             .needsRecovery:
            true
        default:
            false
        }
    }

    /// Whether the connection is transitioning
    public var isTransitioning: Bool {
        switch self {
        case .connecting,
             .disconnecting:
            true
        default:
            false
        }
    }

    // MARK: - Descriptions

    /// User-facing description of the state
    public var localizedDescription: String {
        switch self {
        case .disconnected:
            "Disconnected"
        case .connecting:
            "Connecting..."
        case .connected:
            "Connected"
        case .disconnecting:
            "Disconnecting..."
        case .interrupted:
            "Connection Interrupted"
        case .invalidated:
            "Connection Invalid"
        case .error:
            "Connection Error"
        case .degraded:
            "Connection Degraded"
        case .needsRecovery:
            "Connection Needs Recovery"
        }
    }

    /// Technical description of the state
    public var description: String {
        switch self {
        case .disconnected:
            "disconnected"
        case .connecting:
            "connecting"
        case .connected:
            "connected"
        case .disconnecting:
            "disconnecting"
        case .interrupted:
            "interrupted"
        case .invalidated:
            "invalidated"
        case .error:
            "error"
        case .degraded:
            "degraded"
        case .needsRecovery:
            "needs_recovery"
        }
    }

    /// Detailed technical description
    public var debugDescription: String {
        """
        XPCConnectionState(
            state: \(description),
            terminal: \(isTerminal),
            active: \(isActive),
            recoverable: \(isRecoverable),
            transitioning: \(isTransitioning)
        )
        """
    }

    // MARK: - Logging Support

    /// Log level appropriate for the state
    public var logLevel: LogLevel {
        switch self {
        case .connected:
            .info
        case .connecting,
             .disconnecting,
             .disconnected:
            .debug
        case .degraded:
            .warning
        case .interrupted,
             .error,
             .needsRecovery:
            .error
        case .invalidated:
            .critical
        }
    }

    /// Metadata for logging
    public var loggingMetadata: [String: String] {
        [
            "state": description,
            "terminal": String(isTerminal),
            "active": String(isActive),
            "recoverable": String(isRecoverable),
            "transitioning": String(isTransitioning),
        ]
    }

    // MARK: - State Transitions

    /// Valid next states from current state
    public var validNextStates: Set<XPCConnectionState> {
        switch self {
        case .disconnected:
            [.connecting]
        case .connecting:
            [.connected, .error, .disconnected]
        case .connected:
            [.disconnecting, .interrupted, .error, .degraded]
        case .disconnecting:
            [.disconnected]
        case .interrupted:
            [.connecting, .disconnected, .error]
        case .invalidated:
            [.disconnected]
        case .error:
            [.connecting, .disconnected]
        case .degraded:
            [.connected, .needsRecovery, .error, .disconnecting]
        case .needsRecovery:
            [.connecting, .error, .disconnected]
        }
    }

    /// Whether transition to given state is valid
    /// - Parameter state: Target state
    /// - Returns: Whether transition is valid
    public func canTransitionTo(_ state: XPCConnectionState) -> Bool {
        validNextStates.contains(state)
    }

    /// Validate transition to new state
    /// - Parameter newState: Target state
    /// - Throws: XPCError if transition is invalid
    public func validateTransitionTo(_ newState: XPCConnectionState) throws {
        guard canTransitionTo(newState) else {
            throw XPCError.invalidState(
                reason: """
                Invalid state transition from \(self) to \(newState). \
                Valid next states: \(validNextStates)
                """
            )
        }
    }
}

// MARK: CustomStringConvertible

extension XPCConnectionState: CustomStringConvertible {
    // Implementation provided by description property
}

// MARK: CustomDebugStringConvertible

extension XPCConnectionState: CustomDebugStringConvertible {
    // Implementation provided by debugDescription property
}

// MARK: Codable

extension XPCConnectionState: Codable {
    // Default implementation sufficient for Int raw value
}
