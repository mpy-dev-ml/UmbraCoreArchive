@preconcurrency import Foundation

// MARK: - XPCConnectionState

/// XPC connection states
enum XPCConnectionState: CustomStringConvertible {
    case disconnected
    case connecting
    case connected
    case disconnecting

    // MARK: Internal

    var description: String {
        switch self {
        case .disconnected: "disconnected"
        case .connecting: "connecting"
        case .connected: "connected"
        case .disconnecting: "disconnecting"
        }
    }
}

// MARK: - XPCConfiguration

/// XPC service configuration
struct XPCConfiguration {
    // MARK: Lifecycle

    init(
        serviceName: String,
        interfaceProtocol: Protocol,
        validateAuditSession: Bool = true,
        autoReconnect: Bool = true,
        maxRetryAttempts: Int = 3,
        retryDelay: TimeInterval = 1.0,
        connectionTimeout: TimeInterval = 5.0
    ) {
        self.serviceName = serviceName
        self.interfaceProtocol = interfaceProtocol
        self.validateAuditSession = validateAuditSession
        self.autoReconnect = autoReconnect
        self.maxRetryAttempts = maxRetryAttempts
        self.retryDelay = retryDelay
        self.connectionTimeout = connectionTimeout
    }

    // MARK: Internal

    let serviceName: String
    let interfaceProtocol: Protocol
    let validateAuditSession: Bool
    let autoReconnect: Bool
    let maxRetryAttempts: Int
    let retryDelay: TimeInterval
    let connectionTimeout: TimeInterval
}

// MARK: - XPCError

/// XPC service errors
enum XPCError: LocalizedError {
    case serviceUnavailable(reason: Reason)
    case invalidState(reason: Reason)
    case notConnected(reason: Reason)
    case invalidProxy(reason: Reason)
    case reconnectionFailed(reason: Reason)
    case timeout(reason: Reason)

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case let .serviceUnavailable(reason):
            "Service unavailable: \(reason.description)"
        case let .invalidState(reason):
            "Invalid state: \(reason.description)"
        case let .notConnected(reason):
            "Not connected: \(reason.description)"
        case let .invalidProxy(reason):
            "Invalid proxy: \(reason.description)"
        case let .reconnectionFailed(reason):
            "Reconnection failed: \(reason.description)"
        case let .timeout(reason):
            "Operation timed out: \(reason.description)"
        }
    }
}

/// Notification name for XPC connection state changes
extension Notification.Name {
    static let xpcConnectionStateChanged = Notification.Name(
        "XPCConnectionStateChanged"
    )
}
