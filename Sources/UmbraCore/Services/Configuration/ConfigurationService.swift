import Foundation

// MARK: - ConfigurationService

/// Service for managing configuration settings
@objc
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

    /// Configuration value
    public struct ConfigValue: Codable, Sendable {
        // MARK: - Properties

        /// Value type
        public let type: ValueType
        /// Raw value
        public let value: Any

        // MARK: - Lifecycle

        /// Initialize with value
        /// - Parameter value: Value to store
        /// - Throws: Error if value type is not supported
        public init(value: Any) throws {
            if let bool = value as? Bool {
                type = .boolean
                self.value = bool
            } else if let string = value as? String {
                type = .string
                self.value = string
            } else if let number = value as? Double {
                type = .number
                self.value = number
            } else if let array = value as? [Any] {
                type = .array
                self.value = try array.map { try ConfigValue(value: $0) }
            } else if let dict = value as? [String: Any] {
                type = .dictionary
                self.value = try dict.mapValues { try ConfigValue(value: $0) }
            } else {
                throw ConfigurationError.unsupportedValueType(String(describing: Swift.type(of: value)))
            }
        }

        // MARK: - Codable

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)

            switch type {
            case .boolean:
                try container.encode(value as! Bool, forKey: .value)
            case .string:
                try container.encode(value as! String, forKey: .value)
            case .number:
                try container.encode(value as! Double, forKey: .value)
            case .array:
                try container.encode(value as! [ConfigValue], forKey: .value)
            case .dictionary:
                try container.encode(value as! [String: ConfigValue], forKey: .value)
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = try container.decode(ValueType.self, forKey: .type)

            switch type {
            case .boolean:
                value = try container.decode(Bool.self, forKey: .value)
            case .string:
                value = try container.decode(String.self, forKey: .value)
            case .number:
                value = try container.decode(Double.self, forKey: .value)
            case .array:
                value = try container.decode([ConfigValue].self, forKey: .value)
            case .dictionary:
                value = try container.decode([String: ConfigValue].self, forKey: .value)
            }
        }

        // MARK: - Private

        private enum CodingKeys: String, CodingKey {
            case type
            case value
        }

        public enum ValueType: String, Codable {
            case boolean
            case string
            case number
            case array
            case dictionary
        }
    }

    // MARK: - Public Methods

    /// Set configuration value
    /// - Parameters:
    ///   - value: Value to set
    ///   - key: Configuration key
    /// - Throws: Error if value is invalid
    public func setValue(_ value: Any, forKey key: String) throws {
        _ = try validateUsable(for: "setValue")

        let configValue = try ConfigValue(value: value)

        queue.async(flags: .barrier) {
            self.values[key] = configValue

            self.logger.info(
                """
                Set configuration value:
                Key: \(key)
                Type: \(configValue.type)
                """,
                file: #file,
                function: #function,
                line: #line
            )

            // Notify observers
            self.notifyObservers(forKey: key, value: value)
        }
    }

    /// Get configuration value
    /// - Parameter key: Configuration key
    /// - Returns: Configuration value
    /// - Throws: Error if value is not found
    public func getValue(forKey key: String) throws -> Any {
        _ = try validateUsable(for: "getValue")

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
            Task {
                await self.saveToDisk()
            }
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
            Task {
                await self.saveToDisk()
            }
        }
    }

    /// Load configuration from disk
    /// - Throws: Error if loading fails
    public func loadFromDisk() async throws {
        _ = try validateUsable(for: "loadFromDisk")

        try await performanceMonitor.trackDuration("config.load") {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let loadedValues = try decoder.decode([String: ConfigValue].self, from: data)

            queue.async(flags: .barrier) {
                self.values = loadedValues

                self.logger.info(
                    "Loaded \(loadedValues.count) configuration values from disk",
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
    private func saveToDisk() async {
        do {
            try await performanceMonitor.trackDuration("config.save") {
                let encoder = JSONEncoder()
                let data = try encoder.encode(self.values)
                try data.write(to: fileURL, options: .atomic)

                self.logger.debug(
                    "Saved \(self.values.count) configuration values to disk",
                    file: #file,
                    function: #function,
                    line: #line
                )
            }
        } catch {
            logger.error(
                "Failed to save configuration: \(error.localizedDescription)",
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
