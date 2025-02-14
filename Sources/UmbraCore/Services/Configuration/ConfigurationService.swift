@preconcurrency import Foundation

// MARK: - ConfigValue

/// Configuration value
@unchecked
public struct ConfigValue: Sendable {
    /// Value type
    public enum ValueType: String, Codable, Sendable {
        case string
        case integer
        case double
        case boolean
        case data
    }
    
    /// Value type
    public let type: ValueType
    /// Raw value
    public let value: Any
    
    /// Initialize with value
    /// - Parameters:
    ///   - value: Value to store
    public init(_ value: Any) {
        self.value = value
        self.type = Self.determineType(of: value)
    }
    
    private static func determineType(of value: Any) -> ValueType {
        switch value {
        case is String:
            return .string
        case is Int:
            return .integer
        case is Double:
            return .double
        case is Bool:
            return .boolean
        case is Data:
            return .data
        default:
            fatalError("Unsupported value type")
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

public protocol ConfigurationObserver: AnyObject {
    func configurationDidChange(key: String, oldValue: Any?, newValue: Any?)
}

// MARK: - ConfigurationService

/// Service for managing configuration settings
public final class ConfigurationService: @unchecked Sendable {
    // MARK: - Properties
    
    private let fileURL: URL
    private let performanceMonitor: PerformanceMonitor
    private let logger: LoggerProtocol
    private var values: [String: ConfigValue]
    private var observers: [(String, UUID, (ConfigValue?) -> Void)]
    private let queue: DispatchQueue
    
    // MARK: - Initialization
    
    /// Initialize with dependencies
    /// - Parameters:
    ///   - fileURL: File URL for persistent storage
    ///   - performanceMonitor: Performance monitor
    ///   - logger: Logger for tracking operations
    @MainActor
    public init(
        fileURL: URL,
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        self.fileURL = fileURL
        self.performanceMonitor = performanceMonitor
        self.logger = logger
        self.values = [:]
        self.observers = []
        self.queue = DispatchQueue(label: "dev.mpy.umbracore.config")
    }

    // MARK: Public

    // MARK: - Public Methods

    /// Set configuration value
    /// - Parameters:
    ///   - value: Value to set
    ///   - key: Configuration key
    /// - Throws: Error if value is invalid
    public func setValue(_ value: Any, forKey key: String) throws {
        _ = try validateUsable(for: "setValue")

        let configValue = ConfigValue(value)

        queue.async(flags: .barrier) {
            let oldValue = self.values[key]
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
            let observers = self.observers
            DispatchQueue.main.async {
                observers.forEach { observer in
                    observer.2(oldValue?.value)
                }
            }
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
            let oldValue = self.values[key]
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

            // Notify observers
            let observers = self.observers
            DispatchQueue.main.async {
                observers.forEach { observer in
                    observer.2(nil)
                }
            }
        }
    }

    /// Clear all configuration values
    public func clearValues() {
        queue.async(flags: .barrier) {
            let oldValues = self.values
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

            // Notify observers
            let observers = self.observers
            DispatchQueue.main.async {
                oldValues.forEach { key, value in
                    observers.forEach { observer in
                        observer.2(nil)
                    }
                }
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

    // MARK: Public

    /// Add observer
    /// - Parameter observer: Observer to add
    public func addObserver(_ observer: ConfigurationObserver) {
        queue.async {
            self.observers.append(("key", UUID(), { value in
                observer.configurationDidChange(key: "key", oldValue: nil, newValue: value)
            }))
        }
    }
    
    /// Remove observer
    /// - Parameter observer: Observer to remove
    public func removeObserver(_ observer: ConfigurationObserver) {
        queue.async {
            self.observers.removeAll { $0.2 === observer.configurationDidChange }
        }
    }

    // MARK: Private

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

    /// Notify observers of configuration change
    private func notifyObservers(forKey key: String, oldValue: Any?, newValue: Any?) {
        let observers = self.observers
        DispatchQueue.main.async {
            observers.forEach { observer in
                observer.2(newValue)
            }
        }
    }

    private func validateUsable(for method: String) throws {
        // TO DO: implement validation
    }
}
