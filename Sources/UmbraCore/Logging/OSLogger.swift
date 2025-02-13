@preconcurrency import Foundation
import os.log

#if os(macOS)
    /// OS-level logger implementation
    @objc
    public class OSLogger: NSObject, LoggerProtocol {
        // MARK: - Properties

        /// OS log instance
        private let osLog: OSLog

        /// Queue for synchronizing log operations
        private let queue: DispatchQueue

        /// Performance monitor
        private let performanceMonitor: PerformanceMonitor

        // MARK: - Lifecycle

        /// Initialize OS logger
        /// - Parameters:
        ///   - subsystem: Subsystem identifier
        ///   - category: Log category
        ///   - logger: Logger instance
        public init(
            subsystem: String = "dev.mpy.umbra",
            category: String = "default",
            logger: LoggerProtocol
        ) {
            osLog = OSLog(
                subsystem: subsystem,
                category: category
            )
            queue = DispatchQueue(
                label: "dev.mpy.umbra.logger",
                qos: .utility
            )
            performanceMonitor = PerformanceMonitor(logger: logger)
            super.init()
        }

        // MARK: - LoggerProtocol

        public func debug(
            _ message: String,
            file: String,
            function: String,
            line: Int
        ) {
            log(message, type: .debug, file: file, function: function, line: line)
        }

        public func info(
            _ message: String,
            file: String,
            function: String,
            line: Int
        ) {
            log(message, type: .info, file: file, function: function, line: line)
        }

        public func warning(
            _ message: String,
            file: String,
            function: String,
            line: Int
        ) {
            log(message, type: .warning, file: file, function: function, line: line)
        }

        public func error(
            _ message: String,
            file: String,
            function: String,
            line: Int
        ) {
            log(message, type: .error, file: file, function: function, line: line)
        }

        // MARK: - Private Methods

        private func log(
            _ message: String,
            type: OSLogType,
            file: String,
            function: String,
            line: Int
        ) {
            queue.async {
                let formattedMessage = """
                \(message)
                File: \(file)
                Function: \(function)
                Line: \(line)
                """
                os_log(
                    "%{public}@",
                    log: self.osLog,
                    type: type,
                    formattedMessage
                )
            }
        }
    }
#endif
