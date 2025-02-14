@preconcurrency import Foundation

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

/// Errors that can occur during XPC operations
public enum XPCError: Error, CustomStringConvertible {
    /// Service is not available
    case serviceUnavailable(reason: String)

    /// Invalid connection state
    case invalidState(reason: String)

    /// Connection failed
    case connectionFailed(reason: String)

    /// Reconnection failed
    case reconnectionFailed(attempts: Int)

    /// Operation failed
    case operationFailed(reason: String)

    public var description: String {
        switch self {
        case let .serviceUnavailable(reason):
            "Service unavailable: \(reason)"

        case let .invalidState(reason):
            "Invalid state: \(reason)"

        case let .connectionFailed(reason):
            "Connection failed: \(reason)"

        case let .reconnectionFailed(attempts):
            "Reconnection failed after \(attempts) attempts"

        case let .operationFailed(reason):
            "Operation failed: \(reason)"
        }
    }
}

// MARK: - Notification Names

/// Notification name for XPC connection state changes
public extension Notification.Name {
    static let xpcConnectionStateChanged = Notification.Name(
        "XPCConnectionStateChanged"
    )
}

// MARK: - Notification Keys

/// Keys used in XPC notifications
public enum XPCNotificationKey {
    /// Key for old connection state
    public static let oldState = "oldState"

    /// Key for new connection state
    public static let newState = "newState"

    /// Key for service name
    public static let service = "service"

    /// Key for error information
    public static let error = "error"
}
