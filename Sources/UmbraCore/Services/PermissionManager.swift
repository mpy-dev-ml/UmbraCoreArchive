import Foundation

// MARK: - PermissionManager

/// A service that manages permission persistence and recovery for sandbox-compliant file access.
///
/// The `PermissionManager` provides a robust system for:
/// - Persisting security-scoped bookmarks
/// - Recovering file access permissions
/// - Sharing permissions with XPC services
/// - Managing permission lifecycle
///
/// ## Overview
///
/// Use `PermissionManager` to maintain persistent access to files and directories
/// selected by the user, even after app restart:
///
/// ```swift
/// let manager = PermissionManager(
///     logger: logger,
///     securityService: SecurityService(),
///     keychain: KeychainService()
/// )
///
/// // Store permission
/// try await manager.persistPermission(for: fileURL)
///
/// // Recover permission later
/// let hasAccess = try await manager.recoverPermission(for: fileURL)
/// ```
public actor PermissionManager { // MARK: Lifecycle
    // MARK: - Initialization

    /// Creates a new permission manager instance.
    ///
    /// - Parameters:
    ///   - logger: The logging service for debugging and diagnostics
    ///   - securityService: The service handling security-scoped bookmarks
    ///   - keychain: The service for securely storing permission data
    public init(
        logger: LoggerProtocol,
        securityService: SecurityServiceProtocol,
        keychain: KeychainServiceProtocol
    ) {
        self.logger = logger
        self.securityService = securityService
        self.keychain = keychain
        fileManager = FileManager.default

        do {
            try keychain.configureXPCSharing(accessGroup: permissionAccessGroup)
        } catch {
            self.logger.error(
                "Failed to configure XPC sharing: \(error.localizedDescription)",
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    // MARK: Public

    // MARK: - Public Methods

    /// Request and persist permission for a URL
    /// - Parameter url: The URL to request permission for
    /// - Returns: true if permission was granted and persisted
    public func requestAndPersistPermission(for url: URL) async throws -> Bool {
        logPermissionRequest(for: url)

        do {
            guard try await requestPermission(for: url) else {
                return false
            }

            try await createAndPersistBookmark(for: url)
            logPermissionGranted(for: url)
            return true
        } catch {
            logPermissionError(error, for: url)
            throw PermissionError.persistenceFailed(error.localizedDescription)
        }
    }

    /// Recover permission for a URL
    /// - Parameter url: The URL to recover permission for
    /// - Returns: true if permission was recovered
    public func recoverPermission(for url: URL) async throws -> Bool {
        logRecoveryAttempt(for: url)

        guard let bookmark = try loadStoredBookmark(for: url) else {
            return false
        }

        guard let resolvedURL = try resolveAndVerifyBookmark(bookmark, originalURL: url) else {
            return false
        }

        guard try await validateAndTestAccess(resolvedURL, url) else {
            return false
        }

        logRecoverySuccess(for: url)
        return true
    }

    /// Check if permission exists for a URL
    /// - Parameter url: The URL to check
    /// - Returns: true if permission exists and is valid
    public func hasValidPermission(for url: URL) async throws -> Bool {
        do {
            return try await validatePermission(for: url)
        } catch {
            logPermissionCheckError(error)
            return false
        }
    }

    /// Validate permission for URL
    /// - Parameter url: URL to validate
    /// - Returns: true if permission is valid
    private func validatePermission(for url: URL) async throws -> Bool {
        guard let bookmark = try loadBookmark(for: url) else {
            return false
        }

        let resolvedURL = try securityService.resolveBookmark(bookmark)
        return try await validateAccess(to: resolvedURL, originalURL: url)
    }

    /// Validate access to resolved URL
    /// - Parameters:
    ///   - resolvedURL: Resolved URL from bookmark
    ///   - originalURL: Original URL for comparison
    /// - Returns: true if access is valid
    private func validateAccess(
        to resolvedURL: URL,
        originalURL: URL
    ) async throws -> Bool {
        let canAccess = try await securityService.startAccessing(resolvedURL)
        if !canAccess {
            logAccessFailure(for: resolvedURL)
            try removeBookmark(for: originalURL)
            return false
        }
        return resolvedURL.path == originalURL.path
    }

    /// Log permission check error
    /// - Parameter error: Error to log
    private func logPermissionCheckError(_ error: Error) {
        logger.debug(
            "Permission check failed: \(error.localizedDescription)",
            file: #file,
            function: #function,
            line: #line
        )
    }

    /// Log access failure for URL
    /// - Parameter url: URL that failed access
    private func logAccessFailure(for url: URL) {
        logger.error(
            "Failed to access resolved URL: \(url.path)",
            file: #file,
            function: #function,
            line: #line
        )
    }

    /// Revoke permission for a URL
    /// - Parameter url: The URL to revoke permission for
    public func revokePermission(for url: URL) async throws {
        logRevocationStart(for: url)

        do {
            try removeBookmark(for: url)
            logRevocationSuccess(for: url)
        } catch {
            logRevocationFailure(error, for: url)
            throw PermissionError.revocationFailed(error.localizedDescription)
        }
    }

    /// Log start of permission revocation
    /// - Parameter url: URL being revoked
    private func logRevocationStart(for url: URL) {
        logger.debug(
            "Revoking permission for: \(url.path)",
            file: #file,
            function: #function,
            line: #line
        )
    }

    /// Log successful permission revocation
    /// - Parameter url: URL that was revoked
    private func logRevocationSuccess(for url: URL) {
        logger.info(
            "Permission revoked for: \(url.path)",
            file: #file,
            function: #function,
            line: #line
        )
    }

    /// Log permission revocation failure
    /// - Parameters:
    ///   - error: Error that occurred
    ///   - url: URL that failed revocation
    private func logRevocationFailure(_ error: Error, for _: URL) {
        logger.error(
            "Failed to revoke permission: \(error.localizedDescription)",
            file: #file,
            function: #function,
            line: #line
        )
    }

    /// Request permission for URL
    /// - Parameter url: URL to request permission for
    /// - Returns: Whether permission was granted
    private func requestPermission(for url: URL) async throws -> Bool {
        guard try await securityService.requestPermission(for: url) else {
            logger.error(
                "Permission denied for: \(url.path)",
                file: #file,
                function: #function,
                line: #line
            )
            return false
        }
        return true
    }

    /// Create and persist bookmark for URL
    /// - Parameter url: URL to create bookmark for
    private func createAndPersistBookmark(for url: URL) async throws {
        let bookmark = try await securityService.createBookmark(for: url)
        try persistBookmark(bookmark, for: url)
    }

    /// Log permission request
    /// - Parameter url: URL being requested
    private func logPermissionRequest(for url: URL) {
        logger.debug(
            "Requesting permission for: \(url.path)",
            file: #file,
            function: #function,
            line: #line
        )
    }

    /// Log permission granted
    /// - Parameter url: URL permission was granted for
    private func logPermissionGranted(for url: URL) {
        logger.info(
            "Permission granted and persisted for: \(url.path)",
            file: #file,
            function: #function,
            line: #line
        )
    }

    /// Log permission error
    /// - Parameters:
    ///   - error: Error that occurred
    ///   - url: URL that caused error
    private func logPermissionError(_ error: Error, for _: URL) {
        logger.error(
            "Failed to request/persist permission: \(error.localizedDescription)",
            file: #file,
            function: #function,
            line: #line
        )
    }

    // MARK: Internal

    // MARK: Internal

    let logger: LoggerProtocol
    let securityService: SecurityServiceProtocol
    let keychain: KeychainServiceProtocol
    let fileManager: FileManager

    /// Prefix used for keychain permission entries to avoid naming conflicts
    let keychainPrefix = "dev.mpy.rBUM.permission."

    /// Access group identifier for sharing permissions with the XPC service
    let permissionAccessGroup = "dev.mpy.rBUM.permissions"

    // MARK: Private

    // MARK: - Private Methods

    private func persistBookmark(_ bookmark: Data, for url: URL) throws {
        logger.debug(
            "Persisting bookmark for: \(url.path)",
            file: #file,
            function: #function,
            line: #line
        )

        do {
            try keychain.save(bookmark, for: url.path, accessGroup: permissionAccessGroup)
        } catch {
            logger.error(
                "Failed to persist bookmark: \(error.localizedDescription)",
                file: #file,
                function: #function,
                line: #line
            )
            throw PermissionError.persistenceFailed(error.localizedDescription)
        }
    }

    private func loadBookmark(for url: URL) throws -> Data? {
        logger.debug(
            "Loading bookmark for: \(url.path)",
            file: #file,
            function: #function,
            line: #line
        )

        return try keychain.retrieve(for: url.path, accessGroup: permissionAccessGroup)
    }

    private func removeBookmark(for url: URL) throws {
        logger.debug(
            "Removing bookmark for: \(url.path)",
            file: #file,
            function: #function,
            line: #line
        )

        do {
            try keychain.delete(for: url.path, accessGroup: permissionAccessGroup)
        } catch {
            logger.error(
                "Failed to remove bookmark: \(error.localizedDescription)",
                file: #file,
                function: #function,
                line: #line
            )
            throw PermissionError.revocationFailed(error.localizedDescription)
        }
    }

    /// Resolves and verifies a bookmark matches the original URL
    /// - Parameters:
    ///   - bookmark: The bookmark data to resolve
    ///   - originalURL: The original URL to verify against
    /// - Returns: The resolved URL if successful, nil otherwise
    private func resolveAndVerifyBookmark(_ bookmark: Data, originalURL: URL) throws -> URL? {
        // Attempt to resolve bookmark
        let resolvedURL = try securityService.resolveBookmark(bookmark)

        // Verify resolved URL matches original
        guard resolvedURL.path == originalURL.path else {
            logger.error(
                "Bookmark resolved to different path: \(resolvedURL.path)",
                file: #file,
                function: #function,
                line: #line
            )
            try removeBookmark(for: originalURL)
            return nil
        }

        return resolvedURL
    }

    /// Tests access to a URL using the security service
    /// - Parameter url: The URL to test access to
    /// - Returns: true if access was successful
    private func testAccess(to url: URL) async throws -> Bool {
        let canAccess = try await securityService.startAccessing(url)
        guard canAccess else {
            logger.error(
                "Failed to access resolved URL: \(url.path)",
                file: #file,
                function: #function,
                line: #line
            )
            return false
        }
        try await securityService.stopAccessing(url)
        return true
    }

    /// Load stored bookmark for URL
    /// - Parameter url: URL to load bookmark for
    /// - Returns: Stored bookmark if found
    private func loadStoredBookmark(for url: URL) throws -> Data? {
        guard let bookmark = try loadBookmark(for: url) else {
            logger.debug(
                "No stored bookmark found for: \(url.path)",
                file: #file,
                function: #function,
                line: #line
            )
            return nil
        }
        return bookmark
    }

    /// Validate and test access to URL
    /// - Parameters:
    ///   - resolvedURL: Resolved URL to test
    ///   - originalURL: Original URL for bookmark removal
    /// - Returns: Whether access is valid
    private func validateAndTestAccess(
        _ resolvedURL: URL,
        _ originalURL: URL
    ) async throws -> Bool {
        guard try await testAccess(to: resolvedURL) else {
            try removeBookmark(for: originalURL)
            return false
        }
        return true
    }

    /// Log recovery attempt
    /// - Parameter url: URL attempting to recover
    private func logRecoveryAttempt(for url: URL) {
        logger.debug(
            "Attempting to recover permission for: \(url.path)",
            file: #file,
            function: #function,
            line: #line
        )
    }

    /// Log recovery success
    /// - Parameter url: URL successfully recovered
    private func logRecoverySuccess(for url: URL) {
        logger.info(
            "Successfully recovered permission for: \(url.path)",
            file: #file,
            function: #function,
            line: #line
        )
    }
}

// MARK: - PermissionError

/// Errors that can occur during permission operations
public enum PermissionError: LocalizedError {
    case persistenceFailed(String)
    case recoveryFailed(String)
    case revocationFailed(String)
    case fileNotFound(URL)
    case readAccessDenied(URL)
    case writeAccessDenied(URL)
    case fileEncrypted(URL)
    case sandboxAccessDenied(URL)
    case volumeReadOnly(URL)

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case let .persistenceFailed(reason):
            "Failed to persist permission: \(reason)"
        case let .recoveryFailed(reason):
            "Failed to recover permission: \(reason)"
        case let .revocationFailed(reason):
            "Failed to revoke permission: \(reason)"
        case let .fileNotFound(url):
            "File not found: \(url.path)"
        case let .readAccessDenied(url):
            "Read access denied for file: \(url.path)"
        case let .writeAccessDenied(url):
            "Write access denied for file: \(url.path)"
        case let .fileEncrypted(url):
            "File is encrypted: \(url.path)"
        case let .sandboxAccessDenied(url):
            "Sandbox access denied for file: \(url.path)"
        case let .volumeReadOnly(url):
            "Volume is read-only for file: \(url.path)"
        }
    }
}
