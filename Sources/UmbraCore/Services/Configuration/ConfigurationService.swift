import Foundation

// MARK: - ConfigurationService

/// Service for managing configuration settings
public final class ConfigurationService: BaseSandboxedService {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - fileURL: File URL for persistent storage
    ///   - performanceMonitor: Performance monitor
    ///   - logger: Logger for tracking operations
    public init(
        fileURL: URL,
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        self.fileURL = fileURL
        self.performanceMonitor = performanceMonitor
        super.init(logger: logger)
    }

    // MARK: Public

    // MARK: - Types

    /// Configuration value type
    public enum ValueType: String, Codable {
        case string
        case integer
        case double
        case boolean
        case date
        case data
        case array
        case dictionary
    }

    /// Configuration value
    public struct ConfigValue: Codable {
        // MARK: Lifecycle

        /// Initialize with value
        public init(value: Any) throws {
            switch value {
            case is String:
                type = .string
            case is Int:
                type = .integer
            case is Double:
                type = .double
            case is Bool:
                type = .boolean
            case is Date:
                type = .date
            case is Data:
                type = .data
            case is [Any]:
                type = .array
            case is [String: Any]:
                type = .dictionary
            default:
                throw ConfigurationError.unsupportedValueType(
                    String(describing: type(of: value))
                )
            }
            self.value = value
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = try container.decode(ValueType.self, forKey: .type)

            switch type {
            case .string:
                value = try container.decode(String.self, forKey: .value)
            case .integer:
                value = try container.decode(Int.self, forKey: .value)
            case .double:
                value = try container.decode(Double.self, forKey: .value)
            case .boolean:
                value = try container.decode(Bool.self, forKey: .value)
            case .date:
                value = try container.decode(Date.self, forKey: .value)
            case .data:
                value = try container.decode(Data.self, forKey: .value)
            case .array:
                value = try container.decode([Any].self, forKey: .value)
            case .dictionary:
                value = try container.decode(
                    [String: Any].self,
                    forKey: .value
                )
            }
        }

        // MARK: Public

        /// Value type
        public let type: ValueType

        /// Raw value
        public let value: Any

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)

            switch type {
            case .string:
                guard let stringValue = value as? String else {
                    throw ConfigurationError.invalidValueType(expected: String.self, actual: type(of: value))
                }
                try container.encode(stringValue, forKey: .value)
            case .integer:
                guard let intValue = value as? Int else {
                    throw ConfigurationError.invalidValueType(expected: Int.self, actual: type(of: value))
                }
                try container.encode(intValue, forKey: .value)
            case .double:
                guard let doubleValue = value as? Double else {
                    throw ConfigurationError.invalidValueType(expected: Double.self, actual: type(of: value))
                }
                try container.encode(doubleValue, forKey: .value)
            case .boolean:
                guard let boolValue = value as? Bool else {
                    throw ConfigurationError.invalidValueType(expected: Bool.self, actual: type(of: value))
                }
                try container.encode(boolValue, forKey: .value)
            case .date:
                guard let dateValue = value as? Date else {
                    throw ConfigurationError.invalidValueType(expected: Date.self, actual: type(of: value))
                }
                try container.encode(dateValue, forKey: .value)
            case .data:
                guard let dataValue = value as? Data else {
                    throw ConfigurationError.invalidValueType(expected: Data.self, actual: type(of: value))
                }
                try container.encode(dataValue, forKey: .value)
            case .array:
                guard let arrayValue = value as? [Any] else {
                    throw ConfigurationError.invalidValueType(expected: Array<Any>.self, actual: type(of: value))
                }
                try container.encode(arrayValue, forKey: .value)
            case .dictionary:
                guard let dictValue = value as? [String: Any] else {
                    throw ConfigurationError.invalidValueType(expected: Dictionary<String, Any>.self, actual: type(of: value))
                }
                try container.encode(dictValue, forKey: .value)
            }
        }

        // MARK: Private

        // MARK: - Codable Implementation

        private enum CodingKeys: String, CodingKey {
            case type
            case value
        }
    }

    // MARK: - Public Methods

    /// Set configuration value
    /// - Parameters:
    ///   - value: Value to set
    ///   - key: Configuration key
    /// - Throws: Error if value is invalid
    public func setValue(_ value: Any, forKey key: String) throws {
        try validateUsable(for: "setValue")

        let configValue = try ConfigValue(value: value)

        queue.async(flags: .barrier) {
            self.values[key] = configValue

            self.logger.debug(
                """
                Set configuration value:
                Key: \(key)
                Type: \(configValue.type)
                """,
                file: #file,
                function: #function,
                line: #line
            )

            // Save to disk
            self.saveToDisk()
        }
    }

    /// Get configuration value
    /// - Parameter key: Configuration key
    /// - Returns: Configuration value
    /// - Throws: Error if value is not found
    public func getValue(forKey key: String) throws -> Any {
        try validateUsable(for: "getValue")

        guard let configValue = queue.sync(execute: { values[key] }) else {
            throw ConfigurationError.valueNotFound(key)
        }

        return configValue.value
    }

    /// Remove configuration value
    /// - Parameter key: Configuration key
    public func removeValue(forKey key: String) {
        queue.async(flags: .barrier) {
            self.values.removeValue(forKey: key)

            self.logger.debug(
                "Removed configuration value for key: \(key)",
                file: #file,
                function: #function,
                line: #line
            )

            // Save to disk
            self.saveToDisk()
        }
    }

    /// Clear all configuration values
    public func clearValues() {
        queue.async(flags: .barrier) {
            self.values.removeAll()

            self.logger.debug(
                "Cleared all configuration values",
                file: #file,
                function: #function,
                line: #line
            )

            // Save to disk
            self.saveToDisk()
        }
    }

    /// Load configuration from disk
    /// - Throws: Error if loading fails
    public func loadFromDisk() throws {
        try validateUsable(for: "loadFromDisk")

        try performanceMonitor.trackDuration("config.load") {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let loadedValues = try decoder.decode(
                [String: ConfigValue].self,
                from: data
            )

            queue.async(flags: .barrier) {
                self.values = loadedValues

                self.logger.info(
                    "Loaded configuration from disk",
                    file: #file,
                    function: #function,
                    line: #line
                )
            }
        }
    }

    // MARK: Private

    /// Configuration values
    private var values: [String: ConfigValue] = [:]

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.config",
        qos: .userInitiated,
        attributes: .concurrent
    )

    /// File URL for persistent storage
    private let fileURL: URL

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    // MARK: - Private Methods

    /// Save configuration to disk
    private func saveToDisk() {
        do {
            try performanceMonitor.trackDuration("config.save") {
                let encoder = JSONEncoder()
                let data = try encoder.encode(self.values)
                try data.write(to: fileURL, options: .atomic)

                logger.info(
                    "Saved configuration to disk",
                    file: #file,
                    function: #function,
                    line: #line
                )
            }
        } catch {
            logger.error(
                "Failed to save configuration: \(error)",
                file: #file,
                function: #function,
                line: #line
            )
        }
    }
}

// MARK: - ConfigurationError

/// Errors that can occur during configuration operations
public enum ConfigurationError: LocalizedError {
    /// Value not found
    case valueNotFound(String)
    /// Invalid value type
    case invalidValueType(expected: Any.Type, actual: Any.Type)
    /// Unsupported value type
    case unsupportedValueType(String)
    /// Persistence error
    case persistenceError(String)

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case let .valueNotFound(key):
            "Configuration value not found for key: \(key)"
        case let .invalidValueType(expected, actual):
            "Invalid value type: expected \(expected), actual \(actual)"
        case let .unsupportedValueType(type):
            "Unsupported value type: \(type)"
        case let .persistenceError(reason):
            "Configuration persistence error: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .valueNotFound:
            "Check configuration key"
        case .invalidValueType:
            "Check value type"
        case .unsupportedValueType:
            "Use supported value type"
        case .persistenceError:
            "Check file permissions and disk space"
        }
    }
}
