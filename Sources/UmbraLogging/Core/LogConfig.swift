import Foundation
import Logging

/// Configuration options for the UmbraCore logging system.
public struct LogConfig: Sendable {
    /// The minimum log level to process.
    public var minimumLevel: Logging.Logger.Level

    /// Maximum number of entries to keep in memory.
    public var maxEntries: Int

    /// Whether to include source location information.
    public var includeSourceLocation: Bool

    /// Whether to include function names in logs.
    public var includeFunctionNames: Bool

    /// Whether to include line numbers in logs.
    public var includeLineNumbers: Bool

    /// Custom metadata to include with all log entries.
    public var globalMetadata: Logging.Logger.Metadata

    /// Creates a new logging configuration.
    /// - Parameters:
    ///   - minimumLevel: The minimum log level to process (default: .info).
    ///   - maxEntries: Maximum number of entries to keep in memory (default: 1000).
    ///   - includeSourceLocation: Whether to include source location (default: true).
    ///   - includeFunctionNames: Whether to include function names (default: true).
    ///   - includeLineNumbers: Whether to include line numbers (default: true).
    ///   - globalMetadata: Custom metadata to include with all logs (default: empty).
    public init(
        minimumLevel: Logging.Logger.Level = .info,
        maxEntries: Int = 1000,
        includeSourceLocation: Bool = true,
        includeFunctionNames: Bool = true,
        includeLineNumbers: Bool = true,
        globalMetadata: Logging.Logger.Metadata = [:]
    ) {
        self.minimumLevel = minimumLevel
        self.maxEntries = maxEntries
        self.includeSourceLocation = includeSourceLocation
        self.includeFunctionNames = includeFunctionNames
        self.includeLineNumbers = includeLineNumbers
        self.globalMetadata = globalMetadata
    }

    /// Returns a configuration with default settings.
    public static var `default`: LogConfig {
        LogConfig()
    }
}
