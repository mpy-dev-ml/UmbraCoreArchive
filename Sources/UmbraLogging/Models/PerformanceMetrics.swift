import Foundation

/// Structure for tracking performance metrics.
public struct PerformanceMetrics: Sendable {
    /// Start time of the operation.
    public let startTime: Date
    
    /// End time of the operation.
    public let endTime: Date
    
    /// Duration of the operation in seconds.
    public var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    /// Initialize a new performance metrics instance.
    /// - Parameters:
    ///   - startTime: Start time of the operation
    ///   - endTime: End time of the operation
    public init(startTime: Date, endTime: Date) {
        self.startTime = startTime
        self.endTime = endTime
    }
}
