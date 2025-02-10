import Foundation

/// XPC connection states
enum XPCConnectionState: CustomStringConvertible {
    case disconnected
    case connecting
    case connected
    case disconnecting

    var description: String {
        switch self {
        case .disconnected: return "disconnected"
        case .connecting: return "connecting"
        case .connected: return "connected"
        case .disconnecting: return "disconnecting"
        }
    }
}

/// XPC service configuration
struct XPCConfiguration {
    let serviceName: String
    let interfaceProtocol: Protocol
    let validateAuditSession: Bool
    let autoReconnect: Bool
    let maxRetryAttempts: Int
    let retryDelay: TimeInterval
    let connectionTimeout: TimeInterval

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
}

/// XPC service errors
enum XPCError: LocalizedError {
    case serviceUnavailable(reason: Reason)
    case invalidState(reason: Reason)
    case notConnected(reason: Reason)
    case invalidProxy(reason: Reason)
    case reconnectionFailed(reason: Reason)
    case timeout(reason: Reason)

    var errorDescription: String? {
        switch self {
        case .serviceUnavailable(let reason):
            return "Service unavailable: \(reason.description)"
        case .invalidState(let reason):
            return "Invalid state: \(reason.description)"
        case .notConnected(let reason):
            return "Not connected: \(reason.description)"
        case .invalidProxy(let reason):
            return "Invalid proxy: \(reason.description)"
        case .reconnectionFailed(let reason):
            return "Reconnection failed: \(reason.description)"
        case .timeout(let reason):
            return "Operation timed out: \(reason.description)"
        }
    }
}

/// Notification name for XPC connection state changes
extension Notification.Name {
    static let xpcConnectionStateChanged = Notification.Name(
        "XPCConnectionStateChanged"
    )
}
