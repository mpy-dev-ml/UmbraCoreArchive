@preconcurrency import Foundation

/// An enumeration of errors that can occur during keychain operations.
///
/// `KeychainError` provides detailed error information for operations involving
/// the system keychain, including:
/// - Saving credentials
/// - Retrieving credentials
/// - Updating credentials
/// - Deleting credentials
/// - Access validation
/// - XPC configuration
///
/// Each error case includes relevant status information to help with:
/// - Error diagnosis
/// - System status reporting
/// - Error recovery
/// - Security auditing
///
/// The enum conforms to `LocalizedError` to provide:
/// - User-friendly error messages
/// - System status details
/// - Error reporting
/// - Diagnostics support
///
/// Example usage:
/// ```swift
/// // Handling keychain errors
/// do {
///     try await keychainService.saveCredentials(credentials)
/// } catch let error as KeychainError {
///     switch error {
///     case .saveFailed(let status):
///         logger.error("Save failed with status: \(status)")
///         handleKeychainError(status)
///
///     case .accessValidationFailed:
///         logger.error("Access validation failed")
///         requestKeychainAccess()
///
///     case .xpcConfigurationFailed:
///         logger.error("XPC configuration failed")
///         reconfigureXPCSharing()
///
///     default:
///         logger.error("Keychain error: \(error.localizedDescription)")
///         showKeychainErrorAlert(error)
///     }
/// }
///
/// // Using error descriptions
/// let error = KeychainError.saveFailed(status: errSecDuplicateItem)
/// print(error.localizedDescription)
/// // "Failed to save item to keychain: -25299"
/// ```
///
/// Implementation notes:
/// 1. Always check OSStatus codes
/// 2. Handle all error cases
/// 3. Provide clear error messages
/// 4. Log error details
public enum KeychainError: LocalizedError {
    /// Indicates that saving an item to the keychain failed.
    case saveFailed(status: OSStatus)

    /// Indicates that retrieving an item from the keychain failed.
    case retrievalFailed(status: OSStatus)

    /// Indicates that updating an item in the keychain failed.
    case updateFailed(status: OSStatus)

    /// Indicates that deleting an item from the keychain failed.
    case deleteFailed(status: OSStatus)

    /// Indicates that access validation failed.
    case accessValidationFailed

    /// Indicates that XPC configuration failed.
    case xpcConfigurationFailed

    // MARK: Public

    /// A localised description of the error suitable for user display.
    ///
    /// This property provides a human-readable description of the error,
    /// including any relevant status codes for system-level errors.
    ///
    /// Format: "[Operation] failed: [Details]"
    ///
    /// Example:
    /// ```swift
    /// let error = KeychainError.saveFailed(status: errSecDuplicateItem)
    /// print(error.localizedDescription)
    /// // "Failed to save item to keychain: -25299"
    /// ```
    ///
    /// Usage:
    /// - Display in error alerts
    /// - Log error details
    /// - Report system status
    /// - Track error patterns
    public var errorDescription: String? {
        switch self {
        case let .saveFailed(status):
            "Failed to save item to keychain: \(status)"
        case let .retrievalFailed(status):
            "Failed to retrieve item from keychain: \(status)"
        case let .updateFailed(status):
            "Failed to update item in keychain: \(status)"
        case let .deleteFailed(status):
            "Failed to delete item from keychain: \(status)"
        case .accessValidationFailed:
            "Failed to validate keychain access"
        case .xpcConfigurationFailed:
            "Failed to configure XPC for keychain access"
        }
    }
}
