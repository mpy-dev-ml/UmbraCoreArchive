import Foundation
import os.log

/// Factory for creating loggers
@objc
public class LoggerFactory: NSObject {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with dependencies
    @objc
    public init(performanceMonitor: PerformanceMonitor = PerformanceMonitor()) {
        self.performanceMonitor = performanceMonitor
        super.init()
    }

    // MARK: Public

    // MARK: - Types

    /// Logger configuration
    public struct Configuration {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            minimumLevel: Logger.Level = .info,
            destination: LogDestination = .osLog
        ) {
            self.minimumLevel = minimumLevel
            self.destination = destination
        }

        // MARK: Public

        /// Minimum log level
        public let minimumLevel: Logger.Level

        /// Log destination
        public let destination: LogDestination
    }

    /// Shared instance
    public static let shared: LoggerFactory = .init()

    // MARK: - Public Methods

    /// Get logger for category
    @objc
    public func getLogger(
        forCategory category: String,
        configuration: Configuration? = nil
    ) -> LoggerProtocol {
        queue.sync {
            if let logger = loggers[category] {
                return logger
            }

            let config = configuration ?? defaultConfig
            let logger = createLogger(
                forCategory: category,
                configuration: config
            )

            loggers[category] = logger
            return logger
        }
    }

    /// Reset all loggers
    @objc
    public func resetLoggers() {
        queue.async(flags: .barrier) {
            self.loggers.removeAll()
        }
    }

    // MARK: Private

    /// Default configuration
    private let defaultConfig: Configuration = .init()

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    /// Cache of created loggers
    private var loggers: [String: LoggerProtocol] = [:]

    /// Queue for synchronizing access
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbra.logger-factory",
        attributes: .concurrent
    )

    // MARK: - Private Methods

    /// Create logger for category
    private func createLogger(
        forCategory _: String,
        configuration: Configuration
    ) -> LoggerProtocol {
        Logger(
            minimumLevel: configuration.minimumLevel,
            destination: configuration.destination
        )
    }
}
