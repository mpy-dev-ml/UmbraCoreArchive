@preconcurrency import Foundation

/// Protocol defining performance monitoring functionality
public protocol PerformanceMonitorProtocol: LoggingServiceProtocol {
    /// Track the duration of an operation
    /// - Parameters:
    ///   - id: Name of the operation
    ///   - metadata: Optional metadata to record with the operation
    ///   - operation: Operation to track
    /// - Returns: Result of the operation
    /// - Throws: Error if operation fails
    func trackDuration<T>(
        _ id: String,
        metadata: [String: String],
        operation: () async throws -> T
    ) async throws -> T

    /// Get performance statistics for an operation
    /// - Parameter id: Operation identifier
    /// - Returns: Statistics if available, nil if no data exists
    func getStatistics(for id: String) -> PerformanceMonitor.Statistics?

    /// Reset statistics for an operation
    /// - Parameter id: Operation identifier
    func resetStatistics(for id: String)
}
