import Foundation
import os.log

#if os(macOS)
    /// OS-level logger implementation
    @objc
    public class OSLogger: NSObject, LoggerProtocol {
        // MARK: Lifecycle

        // MARK: - Initialization

        /// Initialize with configuration
        @objc
        public init(
            subsystem: String = "dev.mpy.umbra",
            category: String = "default",
            performanceMonitor: PerformanceMonitor = PerformanceMonitor()
        ) {
            osLog = OSLog(
                subsystem: subsystem,
                category: category
            )
            self.performanceMonitor = performanceMonitor
            super.init()
        }

        // MARK: Public

        // MARK: - LoggerProtocol

        /// Log debug message
        @objc
        public func debug(
            _ message: String,
            config: LogConfig = LogConfig()
        ) {
            log(
                message,
                type: .debug,
                config: config
            )
        }

        /// Log info message
        @objc
        public func info(
            _ message: String,
            config: LogConfig = LogConfig()
        ) {
            log(
                message,
                type: .info,
                config: config
            )
        }

        /// Log warning message
        @objc
        public func warning(
            _ message: String,
            config: LogConfig = LogConfig()
        ) {
            log(
                message,
                type: .default,
                config: config
            )
        }

        /// Log error message
        @objc
        public func error(
            _ message: String,
            config: LogConfig = LogConfig()
        ) {
            log(
                message,
                type: .error,
                config: config
            )
        }

        /// Log critical message
        @objc
        public func critical(
            _ message: String,
            config: LogConfig = LogConfig()
        ) {
            log(
                message,
                type: .fault,
                config: config
            )
        }

        // MARK: Private

        /// OS Log instance
        private let osLog: OSLog

        /// Performance monitor
        private let performanceMonitor: PerformanceMonitor

        /// Queue for synchronizing operations
        private let queue: DispatchQueue = .init(
            label: "dev.mpy.umbra.os-logger",
            qos: .utility
        )

        // MARK: - Private Methods

        /// Log message with type
        private func log(
            _ message: String,
            type: OSLogType,
            config: LogConfig
        ) {
            queue.async {
                self.performanceMonitor.trackDuration(
                    "oslog.write"
                ) {
                    let formattedMessage = self.formatMessage(
                        message,
                        config: config
                    )

                    os_log(
                        "%{public}@",
                        log: self.osLog,
                        type: type,
                        formattedMessage
                    )
                }
            }
        }

        /// Format message with metadata
        private func formatMessage(
            _ message: String,
            config: LogConfig
        ) -> String {
            guard !config.metadata.isEmpty else {
                return message
            }

            let metadata = config.metadata
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: " ")

            return "\(message) [\(metadata)]"
        }
    }
#endif
