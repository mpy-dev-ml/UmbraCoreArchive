//
// DevelopmentTestService.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Service for development testing utilities
public final class DevelopmentTestService: BaseSandboxedService {
    // MARK: - Types

    /// Test configuration
    public struct TestConfiguration: Codable {
        /// Whether to use mock data
        public var useMockData: Bool

        /// Whether to record test interactions
        public var recordInteractions: Bool

        /// Whether to verify interactions
        public var verifyInteractions: Bool

        /// Whether to simulate failures
        public var simulateFailures: Bool

        /// Failure rate (0-1)
        public var failureRate: Double

        /// Initialize with default values
        public init(
            useMockData: Bool = true,
            recordInteractions: Bool = true,
            verifyInteractions: Bool = true,
            simulateFailures: Bool = false,
            failureRate: Double = 0.1
        ) {
            self.useMockData = useMockData
            self.recordInteractions = recordInteractions
            self.verifyInteractions = verifyInteractions
            self.simulateFailures = simulateFailures
            self.failureRate = failureRate
        }
    }

    /// Test interaction
    public struct TestInteraction: Codable {
        /// Name of interaction
        public let name: String

        /// Input parameters
        public let input: [String: Any]

        /// Output result
        public let output: Any?

        /// Error if any
        public let error: Error?

        /// Timestamp
        public let timestamp: Date

        /// Initialize with values
        public init(
            name: String,
            input: [String: Any],
            output: Any? = nil,
            error: Error? = nil,
            timestamp: Date = Date()
        ) {
            self.name = name
            self.input = input
            self.output = output
            self.error = error
            self.timestamp = timestamp
        }

        /// Encode interaction
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encode(timestamp, forKey: .timestamp)

            // Convert input dictionary to JSON data
            let inputData = try JSONSerialization.data(
                withJSONObject: input,
                options: []
            )
            try container.encode(inputData, forKey: .input)

            // Encode output if present
            if let output = output {
                let outputData = try JSONSerialization.data(
                    withJSONObject: output,
                    options: []
                )
                try container.encode(outputData, forKey: .output)
            }

            // Encode error if present
            if let error = error {
                try container.encode(
                    error.localizedDescription,
                    forKey: .error
                )
            }
        }
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case input
        case output
        case error
        case timestamp
    }

    // MARK: - Properties

    /// Test configuration
    private var configuration: TestConfiguration

    /// Recorded interactions
    private var interactions: [TestInteraction] = []

    /// Queue for synchronizing operations
    private let queue = DispatchQueue(
        label: "dev.mpy.umbracore.development.test",
        qos: .userInitiated,
        attributes: .concurrent
    )

    // MARK: - Initialization

    /// Initialize with configuration and logger
    /// - Parameters:
    ///   - configuration: Test configuration
    ///   - logger: Logger for tracking operations
    public init(
        configuration: TestConfiguration = TestConfiguration(),
        logger: LoggerProtocol
    ) {
        self.configuration = configuration
        super.init(logger: logger)
    }

    // MARK: - Public Methods

    /// Run test operation
    /// - Parameters:
    ///   - name: Operation name
    ///   - input: Input parameters
    ///   - operation: Operation to run
    /// - Returns: Operation result
    /// - Throws: Error if operation fails
    public func runTest<T>(
        name: String,
        input: [String: Any],
        operation: () async throws -> T
    ) async throws -> T {
        try validateUsable(for: "runTest")

        // Check if we should simulate failure
        if configuration.simulateFailures &&
           Double.random(in: 0...1) < configuration.failureRate {
            let error = DevelopmentError.simulatedFailure(name)

            if configuration.recordInteractions {
                recordInteraction(
                    TestInteraction(
                        name: name,
                        input: input,
                        error: error
                    )
                )
            }

            throw error
        }

        do {
            let result = try await operation()

            if configuration.recordInteractions {
                recordInteraction(
                    TestInteraction(
                        name: name,
                        input: input,
                        output: result
                    )
                )
            }

            return result
        } catch {
            if configuration.recordInteractions {
                recordInteraction(
                    TestInteraction(
                        name: name,
                        input: input,
                        error: error
                    )
                )
            }

            throw error
        }
    }

    /// Update test configuration
    /// - Parameter configuration: New configuration
    public func updateConfiguration(_ configuration: TestConfiguration) {
        queue.async(flags: .barrier) {
            self.configuration = configuration

            self.logger.info(
                """
                Updated test configuration:
                Mock Data: \(configuration.useMockData)
                Record Interactions: \(configuration.recordInteractions)
                Verify Interactions: \(configuration.verifyInteractions)
                Simulate Failures: \(configuration.simulateFailures)
                Failure Rate: \(configuration.failureRate)
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Get recorded interactions
    /// - Returns: Array of interactions
    public func getInteractions() -> [TestInteraction] {
        queue.sync {
            interactions
        }
    }

    /// Clear recorded interactions
    public func clearInteractions() {
        queue.async(flags: .barrier) {
            self.interactions.removeAll()

            self.logger.debug(
                "Cleared test interactions",
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    // MARK: - Private Methods

    /// Record a test interaction
    private func recordInteraction(_ interaction: TestInteraction) {
        queue.async(flags: .barrier) {
            self.interactions.append(interaction)

            self.logger.debug(
                """
                Recorded test interaction:
                Name: \(interaction.name)
                Input: \(interaction.input)
                Output: \(String(describing: interaction.output))
                Error: \(String(describing: interaction.error))
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }
}

/// Errors that can occur during development operations
public enum DevelopmentError: LocalizedError {
    /// Simulated failure
    case simulatedFailure(String)
    /// Invalid test operation
    case invalidTestOperation(String)
    /// Mock data not found
    case mockDataNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .simulatedFailure(let operation):
            return "Simulated failure in operation: \(operation)"
        case .invalidTestOperation(let reason):
            return "Invalid test operation: \(reason)"
        case .mockDataNotFound(let type):
            return "Mock data not found for type: \(type)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .simulatedFailure:
            return "This is a simulated failure for testing purposes"
        case .invalidTestOperation:
            return "Check test configuration and parameters"
        case .mockDataNotFound:
            return "Ensure mock data is properly configured"
        }
    }
}
