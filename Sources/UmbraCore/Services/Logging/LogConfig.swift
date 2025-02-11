import Foundation

/// Configuration for logging operations
public struct LogConfig: Sendable {
    // MARK: - Properties

    /// Log level for the message
    public let level: LogLevel

    /// Additional metadata to include with the log
    public let metadata: [String: String]

    /// Privacy level for sensitive information
    public let privacy: PrivacyLevel

    // MARK: - Initialization

    /// Initialize with configuration
    /// - Parameters:
    ///   - level: Log level (default: .info)
    ///   - metadata: Additional metadata (default: empty)
    ///   - privacy: Privacy level (default: .public)
    public init(
        level: LogLevel = .info,
        metadata: [String: String] = [:],
        privacy: PrivacyLevel = .public
    ) {
        self.level = level
        self.metadata = metadata
        self.privacy = privacy
    }
}

/// Privacy level for log messages
public enum PrivacyLevel: Sendable {
    /// Public information that can be freely logged
    case `public`
    /// Private information that should be redacted in logs
    case `private`
    /// Sensitive information that should never be logged
    case sensitive
}
