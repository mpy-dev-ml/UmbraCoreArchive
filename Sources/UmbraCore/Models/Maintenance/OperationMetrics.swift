@preconcurrency import Foundation

/// Namespace for operation-related metrics
public enum Operations {
    /// Metrics for a specific repository operation
    @frozen
    public struct Metrics: Codable, CustomStringConvertible, Equatable, Sendable {
        // MARK: Lifecycle

        public init(
            totalOperations: Int = 0,
            successfulOperations: Int = 0,
            failedOperations: Int = 0,
            averageDuration: TimeInterval = 0,
            maxDuration: TimeInterval = 0,
            lastExecutionTime: Date? = nil,
            lastSuccessTime: Date? = nil,
            lastFailureTime: Date? = nil,
            errorCounts: [String: Int] = [:]
        ) {
            self.totalOperations = totalOperations
            self.successfulOperations = successfulOperations
            self.failedOperations = failedOperations
            self.averageDuration = averageDuration
            self.maxDuration = maxDuration
            self.lastExecutionTime = lastExecutionTime
            self.lastSuccessTime = lastSuccessTime
            self.lastFailureTime = lastFailureTime
            self.errorCounts = errorCounts
        }

        // MARK: Public

        /// Total number of operations performed
        public let totalOperations: Int

        /// Number of successful operations
        public let successfulOperations: Int

        /// Number of failed operations
        public let failedOperations: Int

        /// Average duration of operations
        public let averageDuration: TimeInterval

        /// Maximum duration of any operation
        public let maxDuration: TimeInterval

        /// Time of last execution attempt
        public let lastExecutionTime: Date?

        /// Time of last successful execution
        public let lastSuccessTime: Date?

        /// Time of last failed execution
        public let lastFailureTime: Date?

        /// Count of errors by type
        public let errorCounts: [String: Int]

        /// Success rate as a percentage
        public var successRate: Double {
            guard totalOperations > 0 else { return 0 }
            return Double(successfulOperations) / Double(totalOperations) * 100
        }

        /// Failure rate as a percentage
        public var failureRate: Double {
            guard totalOperations > 0 else { return 0 }
            return Double(failedOperations) / Double(totalOperations) * 100
        }

        /// String representation of metrics
        public var description: String {
            """
            Operations: \(totalOperations) total, \(successfulOperations) successful, \(failedOperations) failed
            Success Rate: \(String(format: "%.1f%%", successRate))
            Average Duration: \(String(format: "%.1fs", averageDuration))
            Max Duration: \(String(format: "%.1fs", maxDuration))
            Last Execution: \(lastExecutionTime?.description ?? "Never")
            Last Success: \(lastSuccessTime?.description ?? "Never")
            Last Failure: \(lastFailureTime?.description ?? "Never")
            """
        }
    }
}
