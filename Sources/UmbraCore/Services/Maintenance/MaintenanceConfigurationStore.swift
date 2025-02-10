//
// MaintenanceConfigurationStore.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Store for maintenance configuration settings
public final class MaintenanceConfigurationStore: BaseSandboxedService {
    // MARK: - Types

    /// Configuration for maintenance tasks
    public struct Configuration: Codable {
        /// Schedule for maintenance tasks
        public struct Schedule: Codable {
            /// Days of the week to run
            public var daysOfWeek: Set<Int>
            /// Hour of the day to run (0-23)
            public var hour: Int
            /// Minute of the hour to run (0-59)
            public var minute: Int

            /// Initialize with default values
            public init(
                daysOfWeek: Set<Int> = [1],  // Monday
                hour: Int = 2,               // 2 AM
                minute: Int = 0              // On the hour
            ) {
                self.daysOfWeek = daysOfWeek
                self.hour = hour
                self.minute = minute
            }
        }

        /// Whether maintenance is enabled
        public var isEnabled: Bool

        /// Schedule for maintenance tasks
        public var schedule: Schedule

        /// Maximum duration in seconds
        public var maxDuration: TimeInterval

        /// Tasks to perform
        public var tasks: Set<MaintenanceTask>

        /// Initialize with default values
        public init(
            isEnabled: Bool = true,
            schedule: Schedule = Schedule(),
            maxDuration: TimeInterval = 3600,
            tasks: Set<MaintenanceTask> = Set(MaintenanceTask.allCases)
        ) {
            self.isEnabled = isEnabled
            self.schedule = schedule
            self.maxDuration = maxDuration
            self.tasks = tasks
        }
    }

    /// Types of maintenance tasks
    public enum MaintenanceTask: String, Codable, CaseIterable {
        /// Clean up temporary files
        case cleanupTemporaryFiles
        /// Validate bookmarks
        case validateBookmarks
        /// Check file system integrity
        case checkFileSystemIntegrity
        /// Optimize database
        case optimizeDatabase
        /// Validate configuration
        case validateConfiguration
    }

    // MARK: - Properties

    /// URL for storing configuration
    private let configurationURL: URL

    /// Queue for synchronizing access
    private let queue = DispatchQueue(
        label: "dev.mpy.umbracore.maintenance",
        qos: .utility
    )

    /// Current configuration
    private var configuration: Configuration

    // MARK: - Initialization

    /// Initialize with configuration URL and logger
    /// - Parameters:
    ///   - configurationURL: URL for storing configuration
    ///   - logger: Logger for tracking operations
    public init(configurationURL: URL, logger: LoggerProtocol) {
        self.configurationURL = configurationURL
        self.configuration = Configuration()
        super.init(logger: logger)

        // Load configuration
        loadConfiguration()
    }

    // MARK: - Public Methods

    /// Get current configuration
    /// - Returns: Current configuration
    public func getConfiguration() -> Configuration {
        queue.sync {
            configuration
        }
    }

    /// Update configuration
    /// - Parameter configuration: New configuration
    /// - Throws: Error if save fails
    public func updateConfiguration(_ configuration: Configuration) throws {
        try queue.sync {
            self.configuration = configuration
            try saveConfiguration()

            logger.info(
                """
                Updated maintenance configuration:
                Enabled: \(configuration.isEnabled)
                Schedule: \(configuration.schedule.daysOfWeek) at \
                \(configuration.schedule.hour):\(configuration.schedule.minute)
                Tasks: \(configuration.tasks.map { $0.rawValue })
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Reset configuration to defaults
    /// - Throws: Error if save fails
    public func resetConfiguration() throws {
        try updateConfiguration(Configuration())
    }

    // MARK: - Private Methods

    /// Load configuration from disk
    private func loadConfiguration() {
        queue.sync {
            do {
                let data = try Data(contentsOf: configurationURL)
                configuration = try JSONDecoder().decode(Configuration.self, from: data)

                logger.debug(
                    "Loaded maintenance configuration",
                    file: #file,
                    function: #function,
                    line: #line
                )
            } catch {
                logger.warning(
                    """
                    Failed to load maintenance configuration: \
                    \(error.localizedDescription)
                    Using defaults.
                    """,
                    file: #file,
                    function: #function,
                    line: #line
                )
            }
        }
    }

    /// Save configuration to disk
    private func saveConfiguration() throws {
        do {
            let data = try JSONEncoder().encode(configuration)
            try data.write(to: configurationURL)

            logger.debug(
                "Saved maintenance configuration",
                file: #file,
                function: #function,
                line: #line
            )
        } catch {
            logger.error(
                """
                Failed to save maintenance configuration: \
                \(error.localizedDescription)
                """,
                file: #file,
                function: #function,
                line: #line
            )
            throw error
        }
    }
}
