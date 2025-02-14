import Foundation

/// Configuration for logging operations
public struct LogConfig: Sendable {
    // MARK: - Properties

    /// Log level
    public let level: UmbraLogLevel

    /// Privacy level
    public let privacy: PrivacyLevel

    // MARK: - Initialization

    /// Initialize log configuration
    /// - Parameters:
    ///   - level: Log level (default: .info)
    ///   - privacy: Privacy level (default: .public)
    public init(
        level: UmbraLogLevel = .info,
        privacy: PrivacyLevel = .public
    ) {
        self.level = level
        self.privacy = privacy
    }

    /// Privacy level
    public enum PrivacyLevel: String, Codable, Sendable {
        /// Public information
        case `public`
        /// Private information
        case `private`
        /// Sensitive information
        case sensitive
    }
}
