import Foundation
import os.log
import Logging

/// Service for managing logging operations
@MainActor
public final class LoggingService: @unchecked Sendable {
    // MARK: - Properties
    
    /// Current log level
    private(set) var currentLevel: UmbraLogLevel
    
    /// Maximum number of entries to keep
    private(set) var maxEntries: Int
    
    /// Log entries
    private(set) var entries: [LogEntry]
    
    /// System logger
    private let osLogger: OSLog
    
    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor
    
    // MARK: - Initialization
    
    /// Initialize the logging service
    /// - Parameters:
    ///   - level: Initial log level
    ///   - maxEntries: Maximum number of entries to keep
    ///   - performanceMonitor: Performance monitor instance
    public init(
        level: UmbraLogLevel = .info,
        maxEntries: Int = 1000,
        performanceMonitor: PerformanceMonitor
    ) {
        self.currentLevel = level
        self.maxEntries = maxEntries
        self.entries = []
        self.osLogger = OSLog(subsystem: "dev.mpy.umbracore", category: "logging")
        self.performanceMonitor = performanceMonitor
    }
    
    // MARK: - Level Management
    
    /// Update the current log level
    /// - Parameter level: New log level
    public func updateLevel(_ level: UmbraLogLevel) {
        currentLevel = level
    }
    
    /// Get the current log level
    /// - Returns: Current log level
    public func getLevel() -> UmbraLogLevel {
        currentLevel
    }
    
    // MARK: - Entry Management
    
    /// Get log entries filtered by level and date range
    /// - Parameters:
    ///   - level: Minimum log level
    ///   - startDate: Start date for filtering
    ///   - endDate: End date for filtering
    /// - Returns: Filtered log entries
    public func getEntries(
        level: UmbraLogLevel? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> [LogEntry] {
        var filtered = entries
        
        if let level = level {
            filtered = filtered.filter { $0.level.severity >= level.severity }
        }
        
        if let startDate = startDate {
            filtered = filtered.filter { $0.timestamp >= startDate }
        }
        
        if let endDate = endDate {
            filtered = filtered.filter { $0.timestamp <= endDate }
        }
        
        return filtered
    }
    
    /// Clear all log entries
    public func clearEntries() {
        entries.removeAll()
    }
    
    /// Get the current entry count
    /// - Returns: Number of entries
    public func entryCount() -> Int {
        entries.count
    }
    
    /// Get the maximum number of entries
    /// - Returns: Maximum number of entries
    public func getMaxEntries() -> Int {
        maxEntries
    }
    
    /// Update the maximum number of entries
    /// - Parameter count: New maximum
    public func updateMaxEntries(_ count: Int) {
        maxEntries = count
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
    }
}

// MARK: - Private Extensions

private extension UmbraLogLevel {
    /// Convert to swift-log LogLevel
    var swiftLogLevel: Logger.Level {
        switch self {
        case .trace:
            return .debug

        case .debug:
            return .debug

        case .info:
            return .info

        case .notice:
            return .notice

        case .warning:
            return .warning

        case .error:
            return .error

        case .critical:
            return .critical
        }
    }
    
    /// Severity of log level
    var severity: Int {
        switch self {
        case .trace:
            return 0

        case .debug:
            return 1

        case .info:
            return 2

        case .notice:
            return 3

        case .warning:
            return 4

        case .error:
            return 5

        case .critical:
            return 6
        }
    }
    
    /// Icon for log level
    var icon: String {
        switch self {
        case .trace:
            return ""

        case .debug:
            return ""

        case .info:
            return ""

        case .notice:
            return ""

        case .warning:
            return ""

        case .error:
            return ""

        case .critical:
            return ""
        }
    }
    
    /// Color code for log level
    var colorCode: String {
        switch self {
        case .trace:
            return "\u{001B}[0;37m"

        case .debug:
            return "\u{001B}[0;37m"

        case .info:
            return "\u{001B}[0;37m"

        case .notice:
            return "\u{001B}[0;37m"

        case .warning:
            return "\u{001B}[0;33m"

        case .error:
            return "\u{001B}[0;31m"

        case .critical:
            return "\u{001B}[0;31m"
        }
    }
}
