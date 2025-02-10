import Foundation

// MARK: - Service Error Types

/// Supporting types for ServiceError
public extension ServiceError {
    /// Service state information
    struct ServiceState: CustomStringConvertible {
        // MARK: Lifecycle

        /// Creates a new service state
        /// - Parameters:
        ///   - name: Name of the service
        ///   - state: Current state
        public init(
            name: String,
            state: String
        ) {
            self.name = name
            self.state = state
        }

        // MARK: Public

        /// Name of the service state
        public let name: String

        /// Current state value
        public let state: String

        public var description: String {
            "\(name) in state: \(state)"
        }
    }

    /// Resource usage information
    struct ResourceUsage: CustomStringConvertible {
        // MARK: Lifecycle

        /// Creates new resource usage
        /// - Parameters:
        ///   - current: Current usage
        ///   - limit: Usage limit
        ///   - unit: Measurement unit
        public init(
            current: UInt64,
            limit: UInt64,
            unit: String
        ) {
            self.current = current
            self.limit = limit
            self.unit = unit
        }

        // MARK: Public

        /// Current resource usage
        public let current: UInt64

        /// Resource usage limit
        public let limit: UInt64

        /// Unit of measurement
        public let unit: String

        public var description: String {
            String(
                format: "Current: %llu %@, Limit: %llu %@",
                current,
                unit,
                limit,
                unit
            )
        }
    }
}
