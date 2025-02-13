@preconcurrency import Foundation

/// Tracks performance metrics for development services
final class PerformanceTracker {
    // MARK: Internal

    // MARK: - Public Methods

    /// Track the performance of an operation
    /// - Parameters:
    ///   - operation: Name of the operation
    ///   - work: Work to perform
    /// - Returns: Result of the work
    /// - Throws: Any error from the work
    func track<T>(_ operation: String, work: () throws -> T) throws -> T {
        let start = DispatchTime.now()
        let result = try work()
        let end = DispatchTime.now()

        let duration = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000

        queue.async {
            self.metrics[operation, default: []].append(duration)
        }

        return result
    }

    /// Track the performance of an async operation
    /// - Parameters:
    ///   - operation: Name of the operation
    ///   - work: Work to perform
    /// - Returns: Result of the work
    /// - Throws: Any error from the work
    func track<T>(_ operation: String, work: () async throws -> T) async throws -> T {
        let start = DispatchTime.now()
        let result = try await work()
        let end = DispatchTime.now()

        let duration = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000

        queue.async {
            self.metrics[operation, default: []].append(duration)
        }

        return result
    }

    /// Get metrics for an operation
    /// - Parameter operation: Operation name
    /// - Returns: Array of durations in seconds
    func getMetrics(for operation: String) -> [TimeInterval] {
        queue.sync {
            metrics[operation] ?? []
        }
    }

    /// Get average duration for an operation
    /// - Parameter operation: Operation name
    /// - Returns: Average duration in seconds, or nil if no metrics
    func getAverageDuration(for operation: String) -> TimeInterval? {
        queue.sync {
            guard let durations = metrics[operation], !durations.isEmpty else {
                return nil
            }
            return durations.reduce(0, +) / TimeInterval(durations.count)
        }
    }

    /// Clear all metrics
    func clearMetrics() {
        queue.async {
            self.metrics.removeAll()
        }
    }

    // MARK: Private

    /// Metrics for each operation
    private var metrics: [String: [TimeInterval]] = [:]

    /// Queue for synchronizing access
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.development.performance",
        qos: .utility
    )
}
