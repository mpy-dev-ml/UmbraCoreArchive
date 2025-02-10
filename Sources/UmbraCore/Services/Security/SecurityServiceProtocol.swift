import Foundation

// MARK: - SecurityServiceProtocol

/// Protocol defining security service operations
@objc public protocol SecurityServiceProtocol: SandboxCompliant {
    // MARK: - Bookmark Management

    /// Create a security-scoped bookmark for a URL
    /// - Parameter url: URL to create bookmark for
    /// - Returns: Bookmark data
    /// - Throws: SecurityError if bookmark creation fails
    func createBookmark(for url: URL) throws -> Data

    /// Resolve a security-scoped bookmark
    /// - Parameter bookmark: Bookmark data to resolve
    /// - Returns: Resolved URL
    /// - Throws: SecurityError if bookmark resolution fails
    func resolveBookmark(_ bookmark: Data) throws -> URL

    /// Start accessing a security-scoped resource
    /// - Parameter url: URL to access
    /// - Returns: true if access was started successfully
    func startAccessing(_ url: URL) -> Bool

    /// Stop accessing a security-scoped resource
    /// - Parameter url: URL to stop accessing
    func stopAccessing(_ url: URL)

    /// Check if currently accessing a URL
    /// - Parameter url: URL to check
    /// - Returns: true if currently accessing
    func isCurrentlyAccessing(_ url: URL) -> Bool

    // MARK: - Access Control

    /// Request permission to access a URL
    /// - Parameter url: URL to request permission for
    /// - Returns: true if permission was granted
    /// - Throws: SecurityError if permission request fails
    func requestPermission(for url: URL) async throws -> Bool

    /// Validate access to a URL
    /// - Parameter url: URL to validate
    /// - Returns: true if access is valid
    /// - Throws: SecurityError if validation fails
    func validateAccess(to url: URL) throws -> Bool

    /// Revoke access to a URL
    /// - Parameter url: URL to revoke access from
    func revokeAccess(to url: URL)

    /// Clean up all access
    func cleanupAccess()
}

// MARK: - SandboxCompliant

/// Protocol for sandbox compliance
@objc public protocol SandboxCompliant {
    /// Request access to a URL
    /// - Parameter url: URL to request access to
    /// - Returns: true if access was granted
    /// - Throws: SecurityError if request fails
    func requestAccess(to url: URL) async throws -> Bool

    /// Persist access to a URL
    /// - Parameter url: URL to persist access to
    /// - Returns: Data for persisting access
    /// - Throws: SecurityError if persistence fails
    func persistAccess(to url: URL) throws -> Data

    /// Validate access to a URL
    /// - Parameter url: URL to validate
    /// - Returns: true if access is valid
    /// - Throws: SecurityError if validation fails
    func validateAccess(to url: URL) -> Bool

    /// Handle access being denied
    /// - Parameter url: URL that was denied
    /// - Throws: SecurityError with recovery information
    func handleAccessDenied(for url: URL) async throws

    /// Handle a stale bookmark
    /// - Parameter bookmark: Stale bookmark data
    /// - Throws: SecurityError with recovery information
    func handleStaleBookmark(_ bookmark: Data) async throws
}
