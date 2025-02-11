import Foundation
import os.log

// MARK: - LoggingService+Metrics

public extension LoggingService {
    /// Log a metric
    /// - Parameters:
    ///   - context: Metric context
    ///   - file: Source file
    ///   - line: Source line
    ///   - function: Source function
    func metric(
        _ context: MetricContext,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) {
        guard isUsable else { return }

        os_signpost(
            .event,
            log: osLogger,
            name: context.name,
            signpostID: .exclusive,
            "%{public}@: %{public}@ %{public}@",
            context.name,
            String(describing: context.value),
            context.unit
        )

        let entry = createLogEntry(
            level: .info,
            message: "\(context.name): \(context.value) \(context.unit)",
            file: file,
            line: line,
            function: function
        )

        addEntry(entry)
    }
}
