import Foundation

/// Monitors resource usage for development services
final class ResourceMonitor {
    // MARK: Internal

    // MARK: - Public Methods

    /// Track resource allocation
    /// - Parameter resource: Resource type
    func trackAllocation(_ resource: String) {
        queue.async {
            let count = (self.resourceCounts[resource] ?? 0) + 1
            self.resourceCounts[resource] = count
            self.peakCounts[resource] = max(count, self.peakCounts[resource] ?? 0)
        }
    }

    /// Track resource deallocation
    /// - Parameter resource: Resource type
    func trackDeallocation(_ resource: String) {
        queue.async {
            self.resourceCounts[resource] = (self.resourceCounts[resource] ?? 1) - 1
        }
    }

    /// Get current count for a resource
    /// - Parameter resource: Resource type
    /// - Returns: Current count
    func getCurrentCount(for resource: String) -> Int {
        queue.sync {
            resourceCounts[resource] ?? 0
        }
    }

    /// Get peak count for a resource
    /// - Parameter resource: Resource type
    /// - Returns: Peak count
    func getPeakCount(for resource: String) -> Int {
        queue.sync {
            peakCounts[resource] ?? 0
        }
    }

    /// Get all resource counts
    /// - Returns: Dictionary of resource types to counts
    func getAllCounts() -> [String: Int] {
        queue.sync {
            resourceCounts
        }
    }

    /// Reset all counters
    func reset() {
        queue.async {
            self.resourceCounts.removeAll()
            self.peakCounts.removeAll()
        }
    }

    // MARK: Private

    /// Active resource counts
    private var resourceCounts: [String: Int] = [:]

    /// Peak resource counts
    private var peakCounts: [String: Int] = [:]

    /// Queue for synchronizing access
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.development.resources",
        qos: .utility
    )
}
