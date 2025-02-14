@preconcurrency import Foundation

/// Errors that can occur during repository discovery
///
/// This type defines the various errors that can occur during the repository
/// discovery process. It provides specific error cases for common failure modes,
/// along with localised descriptions and recovery suggestions.
///
/// ## Overview
/// The error cases cover the main categories of failures:
/// - Access problems (permissions, sandbox restrictions)
/// - Invalid repository structure
/// - Verification failures
/// - General discovery errors
///
/// Each error case includes contextual information to help diagnose and resolve
/// the issue, such as the affected URL or specific error messages.
///
/// ## Example Usage
/// ```swift
/// do {
///     try await service.scanLocation(url)
/// } catch let error as RepositoryDiscoveryError {
///     switch error {
///     case .accessDenied(let url):
///         print("Cannot access: \(url.path)")
///     case .invalidRepository(let url):
///         print("Invalid repository at: \(url.path)")
///     case .verificationFailed(let url, let reason):
///         print("Verification failed at \(url.path): \(reason)")
///     case .discoveryFailed(let reason):
///         print("Discovery failed: \(reason)")
///     }
/// }
/// ```
///
/// ## Topics
/// ### Error Cases
/// - ``accessDenied(url:)``
/// - ``locationNotAccessible(url:)``
/// - ``invalidRepository(url:)``
/// - ``verificationFailed(url:reason:)``
/// - ``discoveryFailed(reason:)``
///
/// ### Error Information
/// - ``errorDescription``
/// - ``recoverySuggestion``
public enum RepositoryDiscoveryError: LocalizedError {
    /// Access to the specified location was denied
    case accessDenied(url: URL)

    /// Location is not accessible (may not exist or be inaccessible)
    case locationNotAccessible(url: URL)

    /// Repository structure is invalid or corrupted
    case invalidRepository(url: URL)

    /// Repository verification failed with specific reason
    case verificationFailed(url: URL, reason: String)

    /// General discovery failure with reason
    case discoveryFailed(reason: String)

    public var errorDescription: String? {
        switch self {
        case let .accessDenied(url):
            "Access denied to repository at \(url.path)"

        case let .locationNotAccessible(url):
            "Location not accessible: \(url.path)"

        case let .invalidRepository(url):
            "Invalid repository structure at \(url.path)"

        case let .verificationFailed(url, reason):
            "Repository verification failed at \(url.path): \(reason)"

        case let .discoveryFailed(reason):
            "Repository discovery failed: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .accessDenied:
            "Check file permissions and sandbox access"

        case .locationNotAccessible:
            "Verify the location exists and is accessible"

        case .invalidRepository:
            "Verify repository integrity or reinitialise"

        case .verificationFailed:
            "Check repository configuration and try repair"

        case .discoveryFailed:
            "Check system logs for more details"
        }
    }
}
