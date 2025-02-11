import Foundation

/// Protocol for secure keychain operations
///
/// This protocol defines the interface for keychain operations that must be performed
/// in a secure manner, ensuring:
/// - Proper access control
/// - Data encryption
/// - Secure storage
/// - Error handling
@objc
public protocol KeychainServiceProtocol: NSObjectProtocol {
    /// Save data to the keychain with sandbox-compliant access
    /// - Parameters:
    ///   - data: The data to save
    ///   - key: Unique identifier for the keychain item
    ///   - accessGroup: Optional access group for XPC service sharing
    /// - Throws: KeychainError if save fails or sandbox denies access
    /// - Note: Use appropriate access group to share with XPC service
    @objc
    func save(_ data: Data, for key: String, accessGroup: String?) throws

    /// Retrieve data from the keychain
    /// - Parameters:
    ///   - key: Key to retrieve data for
    ///   - accessGroup: Optional access group
    /// - Returns: Data if found, nil if not found
    /// - Throws: KeychainError if operation fails
    /// - Note: Must handle both main app and XPC service access patterns
    func retrieve(for key: String, accessGroup: String?) throws -> Data?

    /// Delete data from the keychain with sandbox-compliant access
    /// - Parameters:
    ///   - key: Key to delete data for
    ///   - accessGroup: Optional access group
    /// - Throws: KeychainError if operation fails
    @objc
    func delete(for key: String, accessGroup: String?) throws

    /// Configure keychain sharing with XPC service
    /// - Parameter accessGroup: The access group to use for sharing
    /// - Throws: KeychainError if configuration fails
    /// - Note: Must be called before any XPC service operations
    @objc
    func configureXPCSharing(accessGroup: String) throws

    /// Validate XPC access to keychain
    /// - Parameter accessGroup: Access group to validate
    /// - Returns: True if access is valid
    /// - Throws: KeychainError if validation fails
    func validateXPCAccess(accessGroup: String) throws -> Bool
}
