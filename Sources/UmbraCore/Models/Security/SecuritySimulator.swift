@preconcurrency import Foundation
import os.log

/// Configuration for development environment
public struct DevelopmentConfiguration: Codable, Sendable {
    /// Enable simulation mode
    public let simulationEnabled: Bool
    
    /// Simulated delay range in seconds
    public let simulatedDelayRange: ClosedRange<TimeInterval>
    
    /// Simulated error rate (0.0 to 1.0)
    public let simulatedErrorRate: Double
    
    /// Custom error messages for simulation
    public let simulatedErrors: [String]
    
    public init(
        simulationEnabled: Bool = false,
        simulatedDelayRange: ClosedRange<TimeInterval> = 0.1...2.0,
        simulatedErrorRate: Double = 0.1,
        simulatedErrors: [String] = []
    ) {
        self.simulationEnabled = simulationEnabled
        self.simulatedDelayRange = simulatedDelayRange
        self.simulatedErrorRate = min(max(simulatedErrorRate, 0.0), 1.0)
        self.simulatedErrors = simulatedErrors
    }
}

/// A development tool that simulates various security-related scenarios for testing purposes.
///
/// The `SecuritySimulator` provides controlled simulation of security failures and delays
/// that might occur in production environments. This allows testing of error handling
/// and timeout scenarios without waiting for actual security operations to complete.
///
/// Features:
/// - Simulated security failures
/// - Configurable operation delays
/// - Detailed error logging
/// - Controlled testing environment
///
/// Example usage:
/// ```swift
/// // Create simulator with configuration
/// let simulator = SecuritySimulator(
///     logger: logger,
///     configuration: DevelopmentConfiguration(
///         simulationEnabled: true,
///         simulatedDelayRange: 1.0...3.0,
///         simulatedErrorRate: 0.2,
///         simulatedErrors: ["Error 1", "Error 2"]
///     )
/// )
///
/// // Test error handling
/// try simulator.simulateOperation("read") { result in
///     switch result {
///     case .success:
///         print("Operation successful")
///     case .failure(let error):
///         print("Operation failed: \(error)")
///     }
/// }
///
/// // Test timeout handling
/// try await simulator.simulateOperation("write")
/// ```
@available(macOS 13.0, *)
public struct SecuritySimulator {
    // MARK: Lifecycle

    /// Initialises a new `SecuritySimulator` instance
    ///
    /// Creates a simulator that can generate controlled security scenarios
    /// for testing purposes.
    ///
    /// - Parameters:
    ///   - logger: Logger for recording simulated events
    ///   - configuration: Controls simulation behaviour
    ///
    /// Example:
    /// ```swift
    /// let simulator = SecuritySimulator(
    ///     logger: Logger(
    ///         subsystem: "com.umbra.core",
    ///         category: "security-sim"
    ///     ),
    ///     configuration: DevelopmentConfiguration(
    ///         simulationEnabled: true,
    ///         simulatedDelayRange: 1.0...3.0,
    ///         simulatedErrorRate: 0.2,
    ///         simulatedErrors: ["Error 1", "Error 2"]
    ///     )
    /// )
    /// ```
    public init(logger: Logger, configuration: DevelopmentConfiguration) {
        self.logger = logger
        self.configuration = configuration
    }

    // MARK: Internal

    /// Simulates a security operation for testing purposes
    ///
    /// If enabled in configuration, simulates a security operation by:
    /// 1. Logging an operation message
    /// 2. Introducing a random delay
    /// 3. Throwing a random error (if configured)
    ///
    /// - Parameters:
    ///   - operation: Name of the operation (e.g., "read", "write")
    ///   - completion: Completion handler with result of the operation
    ///
    /// - Throws: Error if simulation is enabled and error rate is met
    ///
    /// Example:
    /// ```swift
    /// try simulator.simulateOperation("write") { result in
    ///     switch result {
    ///     case .success:
    ///         print("Operation successful")
    ///     case .failure(let error):
    ///         print("Operation failed: \(error)")
    ///     }
    /// }
    /// ```
    func simulateOperation(
        _ operation: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard configuration.simulationEnabled else {
            completion(.success(()))
            return
        }
        
        // Simulate random delay
        let delay = Double.random(
            in: configuration.simulatedDelayRange
        )
        
        Thread.sleep(forTimeInterval: delay)
        
        // Simulate random error
        if Double.random(in: 0...1) < configuration.simulatedErrorRate {
            let error = configuration.simulatedErrors.randomElement() ?? "Simulated error"
            logger.error(
                "Simulated error in operation: \(operation)",
                file: #file,
                function: #function,
                line: #line
            )
            completion(.failure(SecurityError.operationFailed(error)))
        } else {
            logger.info(
                "Successfully simulated operation: \(operation)",
                file: #file,
                function: #function,
                line: #line
            )
            completion(.success(()))
        }
    }

    /// Simulates an async security operation
    /// - Parameter operation: Operation to simulate
    /// - Returns: Result of the operation
    @available(macOS 10.15, *)
    func simulateOperation(_ operation: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            simulateOperation(operation) { result in
                continuation.resume(with: result)
            }
        }
    }

    // MARK: Private

    /// Logger for recording simulated security events
    ///
    /// Used to:
    /// - Track simulated failures
    /// - Monitor delay injections
    /// - Debug test scenarios
    private let logger: Logger

    /// Configuration controlling simulation behaviour
    ///
    /// Controls:
    /// - Whether to simulate failures
    /// - Length of artificial delays
    /// - Other test parameters
    private let configuration: DevelopmentConfiguration
}
