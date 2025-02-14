@preconcurrency import Foundation

/// Protocol defining sandbox monitoring functionality
public protocol SandboxMonitorProtocol: LoggingServiceProtocol {
    /// Start monitoring sandbox operations
    /// - Throws: Error if start fails
    func startMonitoring() async throws

    /// Stop monitoring sandbox operations
    /// - Throws: Error if stop fails
    func stopMonitoring() async throws

    /// Get current monitor state
    /// - Returns: Current state
    func getState() -> MonitorState

    /// Add event handler
    /// - Parameter handler: Event handler closure
    /// - Returns: Handler ID for removal
    func addEventHandler(_ handler: @escaping (MonitorEvent) -> Void) -> UUID

    /// Remove event handler
    /// - Parameter handlerId: Handler ID to remove
    func removeEventHandler(_ handlerId: UUID)
}

/// Monitor state
public enum MonitorState {
    /// Monitoring active
    case active
    /// Monitoring paused
    case paused
    /// Monitoring stopped
    case stopped
    /// Monitoring failed
    case failed(Error)
}

/// Monitor event
public struct MonitorEvent {
    /// Event type
    public let type: EventType
    /// Event timestamp
    public let timestamp: Date
    /// Event data
    public let data: [String: Any]
    /// Event severity
    public let severity: EventSeverity

    /// Initialize with values
    public init(
        type: EventType,
        timestamp: Date = Date(),
        data: [String: Any],
        severity: EventSeverity
    ) {
        self.type = type
        self.timestamp = timestamp
        self.data = data
        self.severity = severity
    }
}

/// Event type
public enum EventType {
    /// File system access
    case fileSystemAccess
    /// Network access
    case networkAccess
    /// IPC communication
    case ipcCommunication
    /// Process execution
    case processExecution
    /// Resource access
    case resourceAccess
    /// Permission change
    case permissionChange
    /// Security violation
    case securityViolation
    /// Custom event
    case custom(String)
}

/// Event severity
public enum EventSeverity {
    /// Information
    case info
    /// Warning
    case warning
    /// Error
    case error
    /// Critical
    case critical
}
