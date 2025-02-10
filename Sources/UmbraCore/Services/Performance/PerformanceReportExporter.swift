import Foundation

/// Service for exporting performance reports
public final class PerformanceReportExporter: BaseSandboxedService {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with monitor and logger
    /// - Parameters:
    ///   - monitor: Performance monitor
    ///   - logger: Logger for tracking operations
    public init(monitor: PerformanceMonitor, logger: LoggerProtocol) {
        self.monitor = monitor
        super.init(logger: logger)
    }

    // MARK: Public

    // MARK: - Types

    /// Format for exported reports
    public enum ReportFormat {
        /// JSON format
        case json
        /// CSV format
        case csv
        /// Plain text format
        case text
    }

    /// Configuration for report export
    public struct ExportConfiguration {
        // MARK: Lifecycle

        /// Initialize with default values
        public init(
            format: ReportFormat = .json,
            metricTypes: Set<PerformanceMonitor.MetricType> = Set(
                PerformanceMonitor.MetricType
                    .allCases
            ),
            startDate: Date? = nil,
            endDate: Date? = nil,
            metadata: [String: String] = [:]
        ) {
            self.format = format
            self.metricTypes = metricTypes
            self.startDate = startDate
            self.endDate = endDate
            self.metadata = metadata
        }

        // MARK: Public

        /// Format of the report
        public let format: ReportFormat
        /// Types of metrics to include
        public let metricTypes: Set<PerformanceMonitor.MetricType>
        /// Start date for metrics
        public let startDate: Date?
        /// End date for metrics
        public let endDate: Date?
        /// Additional metadata
        public let metadata: [String: String]
    }

    // MARK: - Public Methods

    /// Export performance report
    /// - Parameters:
    ///   - configuration: Export configuration
    ///   - url: URL to export to
    /// - Throws: Error if export fails
    public func exportReport(
        configuration: ExportConfiguration,
        to url: URL
    ) throws {
        try validateUsable(for: "exportReport")

        logger.debug(
            """
            Exporting performance report:
            Format: \(configuration.format)
            Metric Types: \(configuration.metricTypes)
            Start Date: \(configuration.startDate?.description ?? "None")
            End Date: \(configuration.endDate?.description ?? "None")
            """,
            file: #file,
            function: #function,
            line: #line
        )

        // Gather metrics
        var metrics: [PerformanceMonitor.Metric] = []
        for type in configuration.metricTypes {
            metrics.append(contentsOf: monitor.getMetrics(for: type))
        }

        // Filter by date range
        if let startDate = configuration.startDate {
            metrics = metrics.filter { $0.timestamp >= startDate }
        }
        if let endDate = configuration.endDate {
            metrics = metrics.filter { $0.timestamp <= endDate }
        }

        // Generate report
        let reportData: Data =
            switch configuration.format {
            case .json:
                try generateJSONReport(
                    metrics: metrics,
                    metadata: configuration.metadata
                )
            case .csv:
                try generateCSVReport(
                    metrics: metrics,
                    metadata: configuration.metadata
                )
            case .text:
                try generateTextReport(
                    metrics: metrics,
                    metadata: configuration.metadata
                )
            }

        // Write to file
        try reportData.write(to: url)

        logger.info(
            "Exported performance report to: \(url.path)",
            file: #file,
            function: #function,
            line: #line
        )
    }

    // MARK: Private

    /// Performance monitor to export from
    private let monitor: PerformanceMonitor

    // MARK: - Private Methods

    /// Generate JSON report
    private func generateJSONReport(
        metrics: [PerformanceMonitor.Metric],
        metadata: [String: String]
    ) throws -> Data {
        let report: [String: Any] = [
            "metadata": metadata,
            "timestamp": Date().ISO8601Format(),
            "metrics": metrics.map { metric in
                [
                    "type": metric.type.rawValue,
                    "operation": metric.operation,
                    "value": metric.value,
                    "unit": metric.unit,
                    "timestamp": metric.timestamp.ISO8601Format(),
                    "context": metric.context,
                ]
            },
        ]

        return try JSONSerialization.data(
            withJSONObject: report,
            options: [.prettyPrinted, .sortedKeys]
        )
    }

    /// Generate CSV report
    private func generateCSVReport(
        metrics: [PerformanceMonitor.Metric],
        metadata _: [String: String]
    ) throws -> Data {
        var csv = "Type,Operation,Value,Unit,Timestamp,Context\n"

        for metric in metrics {
            let context = metric.context
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: ";")

            csv += """
            \(metric.type.rawValue),\
            \(metric.operation),\
            \(metric.value),\
            \(metric.unit),\
            \(metric.timestamp.ISO8601Format()),\
            \(context)\n
            """
        }

        return csv.data(using: .utf8) ?? Data()
    }

    /// Generate text report
    private func generateTextReport(
        metrics: [PerformanceMonitor.Metric],
        metadata: [String: String]
    ) throws -> Data {
        var text = "Performance Report\n"
        text += "Generated: \(Date().ISO8601Format())\n\n"

        // Add metadata
        text += "Metadata:\n"
        for (key, value) in metadata {
            text += "  \(key): \(value)\n"
        }
        text += "\n"

        // Add metrics
        text += "Metrics:\n"
        for metric in metrics {
            text += """
            Type: \(metric.type.rawValue)
            Operation: \(metric.operation)
            Value: \(metric.value) \(metric.unit)
            Timestamp: \(metric.timestamp.ISO8601Format())
            Context: \(metric.context)

            """
        }

        return text.data(using: .utf8) ?? Data()
    }
}
