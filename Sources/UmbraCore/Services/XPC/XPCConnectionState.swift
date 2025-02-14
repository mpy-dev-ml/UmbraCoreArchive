import Foundation
import Logging

// MARK: - XPCConnectionState

/// State of an XPC connection
/// Represents the lifecycle states of an XPC connection, including health and error states
@frozen
@Observable
@objc
public enum XPCConnectionState: Int, CaseIterable, Sendable {
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

    // MARK: - State Properties

    /// Whether the connection is in a terminal state
    @inlinable
    public var isTerminal: Bool {
        switch self {
        case .invalidated:
            true

        default:
            false
        }
    }

    /// Whether the connection is active
    @inlinable
    public var isActive: Bool {
        switch self {
        case .connected, .degraded:
            true

        default:
            false
        }
    }

    /// Whether the connection is recoverable
    @inlinable
    public var isRecoverable: Bool {
        switch self {
        case .interrupted, .error, .degraded, .needsRecovery:
            true

        default:
            false
        }
    }

    /// Whether the connection is transitioning
    @inlinable
    public var isTransitioning: Bool {
        switch self {
        case .connecting, .disconnecting:
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
            String(localized: "Disconnected")

        case .connecting:
            String(localized: "Connecting...")

        case .connected:
            String(localized: "Connected")

        case .disconnecting:
            String(localized: "Disconnecting...")

        case .interrupted:
            String(localized: "Connection Interrupted")

        case .invalidated:
            String(localized: "Connection Invalid")

        case .error:
            String(localized: "Connection Error")

        case .degraded:
            String(localized: "Connection Degraded")

        case .needsRecovery:
            String(localized: "Connection Needs Recovery")
        }
    }

    /// Technical description of the state
    public var description: String {
        switch self {
        case .disconnected: "disconnected"
        case .connecting: "connecting"
        case .connected: "connected"
        case .disconnecting: "disconnecting"
        case .interrupted: "interrupted"
        case .invalidated: "invalidated"
        case .error: "error"
        case .degraded: "degraded"
        case .needsRecovery: "needs_recovery"
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
    public var logLevel: Logger.Level {
        switch self {
        case .connected:
            .info

        case .connecting, .disconnecting, .disconnected:
            .debug

        case .degraded:
            .warning

        case .interrupted, .error, .needsRecovery:
            .error

        case .invalidated:
            .critical
        }
    }

    /// Metadata for logging
    public var loggingMetadata: Logger.Metadata {
        [
            "state": .string(description),
            "terminal": .string(String(isTerminal)),
            "active": .string(String(isActive)),
            "recoverable": .string(String(isRecoverable)),
            "transitioning": .string(String(isTransitioning))
        ]
    }

    // MARK: - State Transitions

    /// Valid next states from current state
    public var validNextStates: Set<Self> {
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
            []

        case .error:
            [.connecting, .disconnected]

        case .degraded:
            [.connected, .needsRecovery, .error]

        case .needsRecovery:
            [.connected, .error, .disconnected]
        }
    }

    /// Check if transition to state is valid
    /// - Parameter state: Target state
    /// - Returns: Whether transition is valid
    public func canTransitionTo(_ state: Self) -> Bool {
        validNextStates.contains(state)
    }

    /// Get transition error if invalid
    /// - Parameter state: Target state
    /// - Returns: Error if transition invalid
    public func transitionError(to state: Self) -> XPCError? {
        guard !canTransitionTo(state) else { return nil }

        return .invalidState(reason: "Invalid transition from \(self) to \(state)")
    }
}

// MARK: - Protocol Conformances

extension XPCConnectionState: CustomStringConvertible {}
extension XPCConnectionState: CustomDebugStringConvertible {}
extension XPCConnectionState: Hashable {}
extension XPCConnectionState: Codable {}
