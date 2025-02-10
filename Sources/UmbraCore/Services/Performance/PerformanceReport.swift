import Foundation

/// Service for generating performance reports
public final class PerformanceReport: BaseSandboxedService {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - metrics: Performance metrics
    ///   - logger: Logger for tracking operations
    public init(
        metrics: PerformanceMetrics,
        logger: LoggerProtocol
    ) {
        self.metrics = metrics
        super.init(logger: logger)
    }

    // MARK: Public

    // MARK: - Types

    /// Report format
    public enum Format {
        /// JSON format
        case json
        /// CSV format
        case csv
        /// Text format
        case text
    }

    /// Report configuration
    public struct Configuration {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            format: Format = .json,
            metricTypes: [PerformanceMonitor.MetricType] = PerformanceMonitor.MetricType.allCases,
            window: PerformanceMetrics.TimeWindow = .hours(24),
            includeTrends: Bool = true,
            includeAnomalies: Bool = true
        ) {
            self.format = format
            self.metricTypes = metricTypes
            self.window = window
            self.includeTrends = includeTrends
            self.includeAnomalies = includeAnomalies
        }

        // MARK: Public

        /// Report format
        public let format: Format

        /// Metric types to include
        public let metricTypes: [PerformanceMonitor.MetricType]

        /// Time window
        public let window: PerformanceMetrics.TimeWindow

        /// Include trends
        public let includeTrends: Bool

        /// Include anomalies
        public let includeAnomalies: Bool
    }

    // MARK: - Public Methods

    /// Generate performance report
    /// - Parameters:
    ///   - configuration: Report configuration
    ///   - destination: Destination URL
    /// - Throws: Error if report generation fails
    public func generateReport(
        configuration: Configuration,
        to destination: URL
    ) async throws {
        try validateUsable(for: "generateReport")

        // Generate report data
        var reportData: [String: Any] = [
            "timestamp": Date(),
            "window": [
                "start": configuration.window.startDate,
                "end": configuration.window.endDate,
            ],
        ]

        // Add metrics for each type
        var metricsData: [String: Any] = [:]

        for type in configuration.metricTypes {
            // Get analysis
            let analysis = metrics.analyzeMetrics(
                type: type,
                window: configuration.window
            )

            // Create metric data
            var metricData: [String: Any] = [
                "analysis": [
                    "average": analysis.average,
                    "minimum": analysis.minimum,
                    "maximum": analysis.maximum,
                    "standardDeviation": analysis.standardDeviation,
                    "percentiles": analysis.percentiles,
                    "sampleCount": analysis.sampleCount,
                ],
            ]

            // Add trends
            if configuration.includeTrends {
                let trends = metrics.getOperationTrends(
                    type: type,
                    window: configuration.window,
                    interval: 300 // 5 minutes
                )
                metricData["trends"] = trends
            }

            // Add anomalies
            if configuration.includeAnomalies {
                let anomalies = metrics.getOperationAnomalies(
                    type: type,
                    window: configuration.window
                )
                metricData["anomalies"] = anomalies.map { metric in
                    [
                        "operation": metric.operation,
                        "value": metric.value,
                        "timestamp": metric.timestamp,
                        "context": metric.context,
                    ]
                }
            }

            metricsData[type.rawValue] = metricData
        }

        reportData["metrics"] = metricsData

        // Generate formatted output
        let output: String
        switch configuration.format {
        case .json:
            let data = try JSONSerialization.data(
                withJSONObject: reportData,
                options: [.prettyPrinted, .sortedKeys]
            )
            output = String(data: data, encoding: .utf8) ?? ""

        case .csv:
            var lines = ["Type,Operation,Value,Timestamp"]

            for (type, data) in metricsData {
                if let metricData = data as? [String: Any] {
                    if let analysis = metricData["analysis"] as? [String: Any] {
                        lines.append("\(type),average,\(analysis["average"] ?? 0),")
                        lines.append("\(type),minimum,\(analysis["minimum"] ?? 0),")
                        lines.append("\(type),maximum,\(analysis["maximum"] ?? 0),")
                    }

                    if let trends = metricData["trends"] as? [Date: Double] {
                        for (date, value) in trends {
                            lines.append("\(type),trend,\(value),\(date)")
                        }
                    }
                }
            }

            output = lines.joined(separator: "\n")

        case .text:
            var lines = ["Performance Report"]
            lines.append("Generated: \(Date())")
            lines.append("")

            for (type, data) in metricsData {
                lines.append("Type: \(type)")

                if let metricData = data as? [String: Any],
                   let analysis = metricData["analysis"] as? [String: Any]
                {
                    lines.append("  Average: \(analysis["average"] ?? 0)")
                    lines.append("  Minimum: \(analysis["minimum"] ?? 0)")
                    lines.append("  Maximum: \(analysis["maximum"] ?? 0)")
                    lines.append("  Standard Deviation: \(analysis["standardDeviation"] ?? 0)")
                    lines.append("  Sample Count: \(analysis["sampleCount"] ?? 0)")
                    lines.append("")
                }
            }

            output = lines.joined(separator: "\n")
        }

        // Write to file
        try output.write(
            to: destination,
            atomically: true,
            encoding: .utf8
        )

        // Log operation
        logger.debug(
            """
            Generated performance report:
            Format: \(configuration.format)
            Types: \(configuration.metricTypes.map(\.rawValue))
            Window: \(configuration.window)
            Size: \(output.count) bytes
            """,
            file: #file,
            function: #function,
            line: #line
        )
    }

    // MARK: Private

    /// Performance metrics
    private let metrics: PerformanceMetrics

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.performance.report",
        qos: .utility,
        attributes: .concurrent
    )
}
