import Foundation
import os.log

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
///         shouldSimulateAccessFailures: true,
///         artificialDelay: 2.0
///     )
/// )
///
/// // Test error handling
/// try simulator.simulateFailureIfNeeded(
///     operation: "read",
///     url: fileURL
/// ) { message in
///     SecurityError.accessDenied(
///         """
///         Access denied to \(fileURL.lastPathComponent): \
///         \(message)
///         """
///     )
/// }
///
/// // Test timeout handling
/// try await simulator.simulateDelay()
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
    ///         shouldSimulateAccessFailures: true,
    ///         artificialDelay: 1.5
    ///     )
    /// )
    /// ```
    public init(logger: Logger, configuration: DevelopmentConfiguration) {
        self.logger = logger
        self.configuration = configuration
    }

    // MARK: Internal

    /// Simulates a security failure for testing purposes
    ///
    /// If enabled in configuration, simulates a security failure by:
    /// 1. Logging an error message
    /// 2. Throwing a configured error
    ///
    /// - Parameters:
    ///   - operation: Name of the operation (e.g., "read", "write")
    ///   - url: URL associated with the operation
    ///   - error: Closure creating an error with given message
    ///
    /// - Throws: Error from closure if simulation is enabled
    ///
    /// Example:
    /// ```swift
    /// try simulator.simulateFailureIfNeeded(
    ///     operation: "write",
    ///     url: fileURL
    /// ) { message in
    ///     SecurityError.permissionDenied(
    ///         """
    ///         Cannot write to \(fileURL.lastPathComponent): \
    ///         \(message)
    ///         """
    ///     )
    /// }
    /// ```
    func simulateFailureIfNeeded(
        operation: String,
        url: URL,
        error: (String) -> Error
    ) throws {
        guard configuration.shouldSimulateAccessFailures else {
            return
        }

        let errorMessage = "\(operation) failed (simulated)"
        let logMessage = """
        Simulating \(operation) failure for URL: \
        \(url.path)
        """

        logger.error(
            logMessage,
            file: #file,
            function: #function,
            line: #line
        )
        throw error(errorMessage)
    }

    /// Simulates a delay in operation execution
    ///
    /// If configured, introduces an artificial delay to simulate:
    /// - Network latency
    /// - Disk I/O delays
    /// - Service response times
    ///
    /// - Throws: Any error during the sleep operation
    ///
    /// Example:
    /// ```swift
    /// // Simulate network delay
    /// try await simulator.simulateDelay()
    ///
    /// // Proceed with operation
    /// try await performNetworkRequest()
    /// ```
    func simulateDelay() async throws {
        if configuration.artificialDelay > 0 {
            let nanoseconds = UInt64(
                configuration.artificialDelay * 1_000_000_000
            )
            try await Task.sleep(nanoseconds: nanoseconds)
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
