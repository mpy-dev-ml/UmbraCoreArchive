import Foundation
import os.log

// MARK: - HealthCheckable Implementation

@available(macOS 13.0, *)
public extension ResticXPCService {
    /// Updates the health status of the XPC service by performing a health check
    /// If the health check fails, the service is marked as unhealthy and the error is logged
    @objc
    func updateHealthStatus() async {
        do {
            isHealthy = try await performHealthCheck()
        } catch {
            let message = "Health check failed: \(error.localizedDescription)"
            logger.error(
                message,
                file: #file,
                function: #function,
                line: #line
            )
            isHealthy = false
        }
    }

    /// Performs a health check on the XPC service
    /// - Returns: A boolean indicating if the service is healthy
    /// - Throws: SecurityError.xpcValidationFailed if the XPC connection is invalid
    @objc
    func performHealthCheck() async throws -> Bool {
        logger.debug(
            "Performing health check",
            file: #file,
            function: #function,
            line: #line
        )

        // Validate XPC connection
        let isValid = try await securityService.validateXPCConnection(connection)

        // Check connection validity
        let isInvalidated = connection.invalidationHandler == nil
        if !isValid || isInvalidated {
            let message = "XPC connection is invalidated"
            throw SecurityError.xpcValidationFailed(message)
        }

        return true
    }
}
