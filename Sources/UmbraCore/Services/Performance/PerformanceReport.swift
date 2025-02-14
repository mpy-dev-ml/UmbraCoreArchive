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
        let reportData = try await generateReportData(configuration)

        // Format and write output
        let output = try formatReport(reportData, format: configuration.format)
        try output.write(to: destination, atomically: true, encoding: .utf8)

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

    /// Generate the report data dictionary
    /// - Parameter configuration: Report configuration
    /// - Returns: Dictionary containing report data
    private func generateReportData(_ configuration: Configuration) async throws -> [String: Any] {
        var reportData: [String: Any] = [
            "timestamp": Date(),
            "window": [
                "start": configuration.window.startDate,
                "end": configuration.window.endDate
            ]
        ]

        reportData["metrics"] = try await generateMetricsData(configuration)
        return reportData
    }

    /// Generate metrics data for each metric type
    /// - Parameter configuration: Report configuration
    /// - Returns: Dictionary containing metrics data
    private func generateMetricsData(_ configuration: Configuration) async throws -> [String: Any] {
        var metricsData: [String: Any] = [:]

        for type in configuration.metricTypes {
            metricsData[type.rawValue] = try await generateMetricData(
                type: type,
                configuration: configuration
            )
        }

        return metricsData
    }

    /// Generate data for a single metric type
    /// - Parameters:
    ///   - type: Metric type
    ///   - configuration: Report configuration
    /// - Returns: Dictionary containing metric data
    private func generateMetricData(
        type: MetricType,
        configuration: Configuration
    ) async throws -> [String: Any] {
        let analysis = metrics.analyzeMetrics(
            type: type,
            window: configuration.window
        )

        var metricData: [String: Any] = [
            "analysis": [
                "average": analysis.average,
                "minimum": analysis.minimum,
                "maximum": analysis.maximum,
                "standardDeviation": analysis.standardDeviation,
                "percentiles": analysis.percentiles,
                "sampleCount": analysis.sampleCount
            ]
        ]

        if configuration.includeTrends {
            metricData["trends"] = metrics.getOperationTrends(
                type: type,
                window: configuration.window,
                interval: 300 // 5 minutes
            )
        }

        if configuration.includeAnomalies {
            let anomalies = metrics
                .getOperationAnomalies(
                    type: type,
                    window: configuration.window
                )
                .map { metric in
                    [
                        "operation": metric.operation,
                        "value": metric.value,
                        "timestamp": metric.timestamp,
                        "context": metric.context
                    ]
                }
            metricData["anomalies"] = anomalies
        }

        return metricData
    }

    /// Format report data according to specified format
    /// - Parameters:
    ///   - reportData: Report data to format
    ///   - format: Desired output format
    /// - Returns: Formatted report string
    /// - Throws: Error if formatting fails
    private func formatReport(_ reportData: [String: Any], format: Format) throws -> String {
        switch format {
        case .json:
            try formatJSONReport(reportData)

        case .csv:
            try formatCSVReport(reportData)

        case .text:
            try formatTextReport(reportData)
        }
    }

    /// Format report data as JSON
    /// - Parameter reportData: Report data to format
    /// - Returns: JSON formatted string
    /// - Throws: Error if JSON serialization fails
    private func formatJSONReport(_ reportData: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(
            withJSONObject: reportData,
            options: [.prettyPrinted, .sortedKeys]
        )
        return String(data: data, encoding: .utf8) ?? ""
    }

    /// Format report data as CSV
    /// - Parameter reportData: Report data to format
    /// - Returns: CSV formatted string
    private func formatCSVReport(_ reportData: [String: Any]) -> String {
        var lines = ["Type,Operation,Value,Timestamp"]

        if let metricsData = reportData["metrics"] as? [String: Any] {
            for (type, data) in metricsData {
                if let metricData = data as? [String: Any] {
                    appendCSVAnalysis(type: type, metricData: metricData, to: &lines)
                    appendCSVTrends(type: type, metricData: metricData, to: &lines)
                }
            }
        }

        return lines.joined(separator: "\n")
    }

    /// Append analysis data to CSV lines
    private func appendCSVAnalysis(
        type: String,
        metricData: [String: Any],
        to lines: inout [String]
    ) {
        if let analysis = metricData["analysis"] as? [String: Any] {
            lines.append("\(type),average,\(analysis["average"] ?? 0),")
            lines.append("\(type),minimum,\(analysis["minimum"] ?? 0),")
            lines.append("\(type),maximum,\(analysis["maximum"] ?? 0),")
        }
    }

    /// Append trend data to CSV lines
    private func appendCSVTrends(
        type: String,
        metricData: [String: Any],
        to lines: inout [String]
    ) {
        if let trends = metricData["trends"] as? [Date: Double] {
            for (date, value) in trends {
                lines.append("\(type),trend,\(value),\(date)")
            }
        }
    }

    /// Format report data as text
    /// - Parameter reportData: Report data to format
    /// - Returns: Human-readable text formatted string
    private func formatTextReport(_ reportData: [String: Any]) -> String {
        var lines = ["Performance Report"]
        lines.append("Generated: \(reportData["timestamp"] ?? Date())")
        lines.append("")

        if let metricsData = reportData["metrics"] as? [String: Any] {
            for (type, data) in metricsData {
                lines.append("Type: \(type)")

                if let metricData = data as? [String: Any],
                   let analysis = metricData["analysis"] as? [String: Any] {
                    appendTextAnalysis(analysis: analysis, to: &lines)
                    appendTextTrends(metricData: metricData, to: &lines)
                    appendTextAnomalies(metricData: metricData, to: &lines)
                }

                lines.append("")
            }
        }

        return lines.joined(separator: "\n")
    }

    /// Append analysis data to text lines
    private func appendTextAnalysis(
        analysis: [String: Any],
        to lines: inout [String]
    ) {
        lines.append("  Average: \(analysis["average"] ?? 0)")
        lines.append("  Minimum: \(analysis["minimum"] ?? 0)")
        lines.append("  Maximum: \(analysis["maximum"] ?? 0)")
        lines.append("  Standard Deviation: \(analysis["standardDeviation"] ?? 0)")
        if let percentiles = analysis["percentiles"] as? [String: Double] {
            lines.append("  Percentiles:")
            for (percentile, value) in percentiles.sorted(by: { $0.key < $1.key }) {
                lines.append("    \(percentile): \(value)")
            }
        }
    }

    /// Append trend data to text lines
    private func appendTextTrends(
        metricData: [String: Any],
        to lines: inout [String]
    ) {
        if let trends = metricData["trends"] as? [Date: Double] {
            lines.append("  Trends:")
            for (date, value) in trends.sorted(by: { $0.key < $1.key }) {
                lines.append("    \(date): \(value)")
            }
        }
    }

    /// Append anomaly data to text lines
    private func appendTextAnomalies(
        metricData: [String: Any],
        to lines: inout [String]
    ) {
        if let anomalies = metricData["anomalies"] as? [[String: Any]] {
            lines.append("  Anomalies:")
            for anomaly in anomalies {
                lines.append("    Operation: \(anomaly["operation"] ?? "")")
                lines.append("    Value: \(anomaly["value"] ?? 0)")
                lines.append("    Timestamp: \(anomaly["timestamp"] ?? "")")
                if let context = anomaly["context"] as? [String: Any] {
                    lines.append("    Context: \(context)")
                }
                lines.append("")
            }
        }
    }
}
