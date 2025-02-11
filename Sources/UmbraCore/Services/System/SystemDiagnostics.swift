import Foundation

/// Diagnostics for system operations
public struct SystemDiagnostics {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - monitor: System monitor
    ///   - performanceMonitor: Performance monitor
    ///   - logger: Logger for tracking operations
    public init(
        monitor: SystemMonitor,
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        self.monitor = monitor
        self.performanceMonitor = performanceMonitor
        self.logger = logger
    }

    // MARK: Public

    // MARK: - Types

    /// Diagnostic report
    public struct Report {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            id: UUID = UUID(),
            timestamp: Date = Date(),
            sections: [Section],
            summary: String
        ) {
            self.id = id
            self.timestamp = timestamp
            self.sections = sections
            self.summary = summary
        }

        // MARK: Public

        /// Report identifier
        public let id: UUID
        /// Report timestamp
        public let timestamp: Date
        /// Report sections
        public let sections: [Section]
        /// Report summary
        public let summary: String
    }

    /// Report section
    public struct Section {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            title: String,
            items: [Item],
            status: Status
        ) {
            self.title = title
            self.items = items
            self.status = status
        }

        // MARK: Public

        /// Section title
        public let title: String
        /// Section items
        public let items: [Item]
        /// Section status
        public let status: Status
    }

    /// Section item
    public struct Item {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            key: String,
            value: String,
            status: Status
        ) {
            self.key = key
            self.value = value
            self.status = status
        }

        // MARK: Public

        /// Item key
        public let key: String
        /// Item value
        public let value: String
        /// Item status
        public let status: Status
    }

    /// Status
    public enum Status {
        /// Operational - system is functioning normally
        case operational
        /// Warning - potential issues detected
        case warning
        /// Error - critical issues detected
        case error
        /// Unknown - status cannot be determined
        case unknown
    }

    // MARK: - Public Methods

    /// Generate diagnostic report
    /// - Returns: Diagnostic report
    /// - Throws: Error if report generation fails
    public func generateReport() async throws -> Report {
        try await performanceMonitor.trackDuration(
            "system.diagnostics.report"
        ) {
            var sections: [Section] = []

            // Check CPU metrics
            try await sections.append(
                checkResource(.cpu, title: "CPU Usage")
            )

            // Check memory metrics
            try await sections.append(
                checkResource(.memory, title: "Memory Usage")
            )

            // Check disk metrics
            try await sections.append(
                checkResource(.disk, title: "Disk Usage")
            )

            // Check network metrics
            try await sections.append(
                checkResource(.network, title: "Network Usage")
            )

            // Check battery metrics
            try await sections.append(
                checkResource(.battery, title: "Battery Status")
            )

            // Check thermal metrics
            try await sections.append(
                checkResource(.thermal, title: "Thermal State")
            )

            // Generate summary
            let summary = generateSummary(sections)

            logger.info(
                """
                Generated system diagnostic report:
                Sections: \(sections.count)
                Status: \(summary)
                """,
                file: #file,
                function: #function,
                line: #line
            )

            return Report(
                sections: sections,
                summary: summary
            )
        }
    }

    // MARK: Private

    /// System monitor
    private let monitor: SystemMonitor

    /// Logger for tracking operations
    private let logger: LoggerProtocol

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    // MARK: - Private Methods

    /// Check resource metrics
    private func checkResource(
        _ type: SystemMonitor.ResourceType,
        title: String
    ) async throws -> Section {
        do {
            let metrics = try await monitor.getResourceMetrics(type)

            var items: [Item] = []

            // Add usage item
            items.append(
                Item(
                    key: "Usage",
                    value: "\(String(format: "%.1f", metrics.usagePercentage))%",
                    status: getUsageStatus(metrics.usagePercentage)
                )
            )

            // Add capacity items
            items.append(
                Item(
                    key: "Available",
                    value: formatBytes(metrics.availableCapacity),
                    status: OperationStatus.operational
                )
            )

            items.append(
                Item(
                    key: "Total",
                    value: formatBytes(metrics.totalCapacity),
                    status: OperationStatus.operational
                )
            )

            return Section(
                title: title,
                items: items,
                status: items.contains { $0.status == .error } ? .error :
                    items.contains { $0.status == .warning } ? .warning : .operational
            )
        } catch {
            return Section(
                title: title,
                items: [
                    Item(
                        key: "Error",
                        value: error.localizedDescription,
                        status: OperationStatus.error
                    )
                ],
                status: OperationStatus.error
            )
        }
    }

    /// Get usage status
    private func getUsageStatus(_ percentage: Double) -> Status {
        switch percentage {
        case 0 ..< 70:
            .operational
        case 70 ..< 90:
            .warning
        default:
            .error
        }
    }

    /// Format bytes
    private func formatBytes(_ bytes: Int64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var unitIndex = 0

        while value > 1024, unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }

        return "\(String(format: "%.1f", value)) \(units[unitIndex])"
    }

    /// Generate summary from sections
    private func generateSummary(_ sections: [Section]) -> String {
        let errorCount = sections.filter { $0.status == .error }.count
        let warningCount = sections.filter { $0.status == .warning }.count
        let operationalCount = sections.filter { $0.status == .operational }.count

        return """
        System Diagnostics Summary:
        - \(errorCount) errors
        - \(warningCount) warnings
        - \(operationalCount) operational
        """
    }
}
