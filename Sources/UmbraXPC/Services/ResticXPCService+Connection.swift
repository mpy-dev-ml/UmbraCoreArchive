import Foundation
import os.log

// MARK: - Connection Management

@available(macOS 13.0, *)
extension ResticXPCService {
    /// Configure the XPC connection with all necessary settings
    func configureConnection() {
        configureInterfaces()
        configureSecuritySettings()
        configureErrorHandlers()
        configureMessageHandlers()
    }

    /// Configure XPC interfaces and allowed classes
    private func configureInterfaces() {
        let protocolType = ResticXPCProtocol.self
        connection.remoteObjectInterface = NSXPCInterface(with: protocolType)
        connection.exportedInterface = NSXPCInterface(with: protocolType)

        // Set up allowed classes for secure coding
        guard let remoteInterface = connection.remoteObjectInterface else {
            logger.error(
                "Failed to configure remote interface",
                metadata: ["service": serviceName],
                privacy: .public
            )
            return
        }

        let allowedClasses = Set<AnyClass>([
            NSString.self,
            NSArray.self,
            NSDictionary.self
        ])

        let selector = #selector(ResticXPCProtocol.executeCommand(_:))
        remoteInterface.setClasses(
            Array(allowedClasses),
            for: selector,
            argumentIndex: 0,
            ofReply: false
        )
    }

    /// Configure security settings and permissions
    private func configureSecuritySettings() {
        // Set audit session identifier for security
        connection.auditSessionIdentifier = au_session_self()

        // Configure sandbox extensions
        let permissions: [XPCPermission] = [
            .allowFileAccess,
            .allowNetworkAccess
        ]
        connection.setAccessibilityPermissions(permissions)

        // Set up security validation
        connection.setValidationHandler { [weak self] in
            guard let self else {
                return false
            }
            return validateConnection()
        }
    }

    /// Configure error and interruption handlers
    private func configureErrorHandlers() {
        connection.interruptionHandler = { [weak self] in
            self?.handleInterruption()
        }

        connection.invalidationHandler = { [weak self] in
            self?.handleInvalidation()
        }

        connection.errorHandler = { [weak self] error in
            self?.handleError(error)
        }
    }

    /// Configure message and command handlers
    private func configureMessageHandlers() {
        messageHandler = { [weak self] message in
            guard let self else {
                throw ResticXPCError.serviceUnavailable
            }
            try await handleMessage(message)
        }

        commandHandler = { [weak self] command in
            guard let self else {
                throw ResticXPCError.serviceUnavailable
            }
            try await executeCommand(command)
        }
    }

    /// Handle XPC connection interruption
    private func handleInterruption() {
        connectionState = .interrupted
        logger.warning(
            "XPC connection interrupted",
            metadata: ["service": serviceName],
            privacy: .public
        )

        notificationCenter.post(
            name: .xpcConnectionInterrupted,
            object: nil,
            userInfo: ["service": serviceName]
        )

        // Attempt to recover
        Task {
            try await recoverConnection()
        }
    }

    /// Handle XPC connection invalidation
    private func handleInvalidation() {
        connectionState = .invalidated
        logger.error(
            "XPC connection invalidated",
            metadata: ["service": serviceName],
            privacy: .public
        )

        notificationCenter.post(
            name: .xpcConnectionInvalidated,
            object: nil,
            userInfo: ["service": serviceName]
        )

        // Clean up resources
        cleanupResources()
    }

    /// Handle XPC connection errors
    private func handleError(_ error: Error) {
        logger.error(
            "XPC connection error",
            metadata: [
                "service": serviceName,
                "error": error.localizedDescription
            ],
            privacy: .public
        )

        notificationCenter.post(
            name: .xpcConnectionError,
            object: nil,
            userInfo: [
                "service": serviceName,
                "error": error
            ]
        )

        // Update metrics
        metrics.recordError()
    }

    /// Attempt to recover a failed connection
    private func recoverConnection() async throws {
        guard connectionState == .interrupted else {
            return
        }

        logger.info(
            "Attempting to recover XPC connection",
            metadata: ["service": serviceName],
            privacy: .public
        )

        // Wait before attempting recovery
        try await Task.sleep(
            nanoseconds: UInt64(1e9) // 1 second
        )

        do {
            try await reconnect()
            connectionState = .connected
            logger.info(
                "XPC connection recovered",
                metadata: ["service": serviceName],
                privacy: .public
            )
        } catch {
            logger.error(
                "Failed to recover XPC connection",
                metadata: [
                    "service": serviceName,
                    "error": error.localizedDescription
                ],
                privacy: .public
            )
            throw ResticXPCError.recoveryFailed(error)
        }
    }

    /// Clean up connection resources
    private func cleanupResources() {
        // Cancel any pending operations
        pendingOperations.forEach { $0.cancel() }
        pendingOperations.removeAll()

        // Release any held resources
        connection.suspend()
        messageHandler = nil
        commandHandler = nil
    }

    /// Validate the remote object proxy and return the service instance
    private func validateRemoteProxy() throws -> ResticXPCServiceProtocol {
        guard let remoteObjectProxy = connection.remoteObjectProxy else {
            logger.error(
                "Failed to obtain remote object proxy",
                metadata: ["service": serviceName],
                privacy: .public
            )
            throw ResticXPCError.connectionFailed
        }

        guard let service = remoteObjectProxy as? ResticXPCServiceProtocol else {
            logger.error(
                """
                Remote object proxy type mismatch: \
                expected ResticXPCServiceProtocol
                """,
                metadata: [
                    "service": serviceName,
                    "actualType": String(describing: type(of: remoteObjectProxy))
                ],
                privacy: .public
            )
            throw ResticXPCError.invalidServiceType
        }

        return service
    }

    /// Check the health of the XPC service
    private func checkServiceHealth(_ service: ResticXPCServiceProtocol) async throws {
        do {
            let isAlive = try await service.ping()
            isHealthy = isAlive

            if isAlive {
                logger.info(
                    "XPC service validation successful",
                    metadata: ["service": serviceName],
                    privacy: .public
                )
            } else {
                logger.error(
                    "XPC service is not responding to ping",
                    metadata: ["service": serviceName],
                    privacy: .public
                )
                throw ResticXPCError.serviceUnavailable
            }
        } catch {
            logger.error(
                "XPC service validation failed",
                metadata: [
                    "service": serviceName,
                    "error": error.localizedDescription
                ],
                privacy: .public
            )
            isHealthy = false
            throw error
        }
    }

    /// Validate the XPC interface and service health
    func validateInterface() async throws {
        let service = try validateRemoteProxy()
        try await checkServiceHealth(service)
    }
}
