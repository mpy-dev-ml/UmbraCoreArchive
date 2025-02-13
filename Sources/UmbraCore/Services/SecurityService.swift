@preconcurrency import Foundation

// MARK: - SecurityService

/// Service implementing security operations with sandbox compliance
///
/// The SecurityService provides a comprehensive security layer for the application,
/// handling sandbox compliance and security-scoped bookmarks. It manages:
/// - Security-scoped bookmarks for file access
/// - User permission requests
/// - Access control for sandboxed resources
///
/// Example usage:
/// ```swift
/// let security = ServiceFactory.createSecurityService(logger: logger)
///
/// // Request permission
/// let granted = try await security.requestPermission(for: fileURL)
///
/// // Create and resolve bookmarks
/// let bookmark = try security.createBookmark(for: fileURL)
/// let url = try security.resolveBookmark(bookmark)
///
/// // Manage access
/// security.startAccessing(url)
/// defer { security.stopAccessing(url) }
/// ```
public final class SecurityService: BaseSandboxedService, SecurityServiceProtocol {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with logger
    /// - Parameter logger: Logger for tracking operations
    override public init(logger: LoggerProtocol) {
        super.init(logger: logger)
    }

    /// Clean up resources
    deinit {
        cleanupAccess()
    }

    // MARK: Internal

    /// Queue for synchronizing bookmark operations
    let bookmarkQueue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.security.bookmarks",
        qos: .userInitiated,
        attributes: .concurrent
    )

    /// Active bookmarks by URL
    var activeBookmarks: [URL: Data] = [:]

    /// Currently accessed URLs
    var accessedURLs: Set<URL> = []
}
