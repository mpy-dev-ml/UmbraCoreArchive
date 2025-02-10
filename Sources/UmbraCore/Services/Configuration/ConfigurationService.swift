//
// ConfigurationService.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Service for managing configuration settings
public final class ConfigurationService: BaseSandboxedService {
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
        /// Value type
        public let type: ValueType

        /// Raw value
        public let value: Any

        /// Initialize with value
        public init(value: Any) throws {
            switch value {
            case is String:
                self.type = .string
            case is Int:
                self.type = .integer
            case is Double:
                self.type = .double
            case is Bool:
                self.type = .boolean
            case is Date:
                self.type = .date
            case is Data:
                self.type = .data
            case is [Any]:
                self.type = .array
            case is [String: Any]:
                self.type = .dictionary
            default:
                throw ConfigurationError.unsupportedValueType(
                    String(describing: type(of: value))
                )
            }
            self.value = value
        }

        // MARK: - Codable Implementation

        private enum CodingKeys: String, CodingKey {
            case type
            case value
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.type = try container.decode(ValueType.self, forKey: .type)

            switch type {
            case .string:
                self.value = try container.decode(String.self, forKey: .value)
            case .integer:
                self.value = try container.decode(Int.self, forKey: .value)
            case .double:
                self.value = try container.decode(Double.self, forKey: .value)
            case .boolean:
                self.value = try container.decode(Bool.self, forKey: .value)
            case .date:
                self.value = try container.decode(Date.self, forKey: .value)
            case .data:
                self.value = try container.decode(Data.self, forKey: .value)
            case .array:
                self.value = try container.decode([Any].self, forKey: .value)
            case .dictionary:
                self.value = try container.decode(
                    [String: Any].self,
                    forKey: .value
                )
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)

            switch type {
            case .string:
                try container.encode(value as! String, forKey: .value)
            case .integer:
                try container.encode(value as! Int, forKey: .value)
            case .double:
                try container.encode(value as! Double, forKey: .value)
            case .boolean:
                try container.encode(value as! Bool, forKey: .value)
            case .date:
                try container.encode(value as! Date, forKey: .value)
            case .data:
                try container.encode(value as! Data, forKey: .value)
            case .array:
                try container.encode(value as! [Any], forKey: .value)
            case .dictionary:
                try container.encode(value as! [String: Any], forKey: .value)
            }
        }
    }

    // MARK: - Properties

    /// Configuration values
    private var values: [String: ConfigValue] = [:]

    /// Queue for synchronizing operations
    private let queue = DispatchQueue(
        label: "dev.mpy.umbracore.config",
        qos: .userInitiated,
        attributes: .concurrent
    )

    /// File URL for persistent storage
    private let fileURL: URL

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

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

/// Errors that can occur during configuration operations
public enum ConfigurationError: LocalizedError {
    /// Value not found
    case valueNotFound(String)
    /// Invalid value type
    case invalidValueType(String)
    /// Unsupported value type
    case unsupportedValueType(String)
    /// Persistence error
    case persistenceError(String)

    public var errorDescription: String? {
        switch self {
        case .valueNotFound(let key):
            return "Configuration value not found for key: \(key)"
        case .invalidValueType(let type):
            return "Invalid value type: \(type)"
        case .unsupportedValueType(let type):
            return "Unsupported value type: \(type)"
        case .persistenceError(let reason):
            return "Configuration persistence error: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .valueNotFound:
            return "Check configuration key"
        case .invalidValueType:
            return "Check value type"
        case .unsupportedValueType:
            return "Use supported value type"
        case .persistenceError:
            return "Check file permissions and disk space"
        }
    }
}
