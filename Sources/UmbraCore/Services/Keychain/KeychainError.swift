import Foundation
import Security

// MARK: - Keychain Error

/// Errors that can occur during keychain operations
public enum KeychainError: LocalizedError {
    // MARK: - Operation Cases

    /// Add operation failed
    /// - Parameters:
    ///   - account: Account identifier
    ///   - service: Service identifier
    ///   - status: Security framework status code
    case addFailed(account: String, service: String, status: OSStatus)

    /// Update operation failed
    /// - Parameters:
    ///   - account: Account identifier
    ///   - service: Service identifier
    ///   - status: Security framework status code
    case updateFailed(account: String, service: String, status: OSStatus)

    /// Delete operation failed
    /// - Parameters:
    ///   - account: Account identifier
    ///   - service: Service identifier
    ///   - status: Security framework status code
    case deleteFailed(account: String, service: String, status: OSStatus)

    /// Get operation failed
    /// - Parameters:
    ///   - account: Account identifier
    ///   - service: Service identifier
    ///   - status: Security framework status code
    case getFailed(account: String, service: String, status: OSStatus)

    // MARK: - Data Cases

    /// Invalid data format or encoding
    /// - Parameter reason: Description of the data issue
    case invalidData(String)

    // MARK: - Configuration Cases

    /// Invalid access group configuration
    /// - Parameter group: Invalid access group identifier
    case invalidAccessGroup(String)

    /// Invalid keychain configuration
    /// - Parameter reason: Description of the configuration issue
    case invalidConfiguration(String)

    /// Generic operation failure
    /// - Parameter reason: Description of the failure
    case operationFailed(String)

    // MARK: Public

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case let .addFailed(account, service, status):
            formatOperationError(
                "Failed to add keychain item",
                account: account,
                service: service,
                status: status
            )

        case let .updateFailed(account, service, status):
            formatOperationError(
                "Failed to update keychain item",
                account: account,
                service: service,
                status: status
            )

        case let .deleteFailed(account, service, status):
            formatOperationError(
                "Failed to delete keychain item",
                account: account,
                service: service,
                status: status
            )

        case let .getFailed(account, service, status):
            formatOperationError(
                "Failed to get keychain item",
                account: account,
                service: service,
                status: status
            )

        case let .invalidData(reason):
            "Invalid keychain data: \(reason)"

        case let .invalidAccessGroup(group):
            "Invalid keychain access group: \(group)"

        case let .invalidConfiguration(reason):
            "Invalid keychain configuration: \(reason)"

        case let .operationFailed(reason):
            "Keychain operation failed: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .addFailed:
            """
            - Verify the item doesn't already exist
            - Check application has keychain access
            - Verify access group permissions
            """

        case .updateFailed:
            """
            - Verify the item exists
            - Check application has keychain access
            - Verify access group permissions
            """

        case .deleteFailed:
            """
            - Verify the item exists
            - Check application has keychain access
            - Verify access group permissions
            """

        case .getFailed:
            """
            - Verify the item exists
            - Check application has keychain access
            - Verify access group permissions
            """

        case .invalidData:
            """
            - Check data format is correct
            - Verify data encoding
            - Ensure data is not corrupted
            """

        case .invalidAccessGroup:
            """
            - Check access group exists
            - Verify application entitlements
            - Check keychain sharing configuration
            """

        case .invalidConfiguration:
            """
            - Review keychain configuration
            - Check security attribute values
            - Verify access control settings
            """

        case .operationFailed:
            """
            - Try the operation again
            - Check system keychain status
            - Verify keychain is unlocked
            """
        }
    }

    public var failureReason: String? {
        switch self {
        case .addFailed:
            "Failed to add new item to keychain"

        case .updateFailed:
            "Failed to update existing keychain item"

        case .deleteFailed:
            "Failed to delete keychain item"

        case .getFailed:
            "Failed to retrieve keychain item"

        case .invalidData:
            "Data format or encoding is invalid"

        case .invalidAccessGroup:
            "Access group configuration is invalid"

        case .invalidConfiguration:
            "Keychain configuration is invalid"

        case .operationFailed:
            "Keychain operation encountered an error"
        }
    }

    public var helpAnchor: String? {
        switch self {
        case .addFailed:
            "keychain_add"

        case .updateFailed:
            "keychain_update"

        case .deleteFailed:
            "keychain_delete"

        case .getFailed:
            "keychain_get"

        case .invalidData:
            "keychain_data"

        case .invalidAccessGroup:
            "keychain_access_groups"

        case .invalidConfiguration:
            "keychain_configuration"

        case .operationFailed:
            "keychain_troubleshooting"
        }
    }

    // MARK: Private

    // MARK: - Private Methods

    /// Format error message for keychain operations
    /// - Parameters:
    ///   - operation: Description of the operation
    ///   - account: Account identifier
    ///   - service: Service identifier
    ///   - status: Security framework status code
    /// - Returns: Formatted error message
    private func formatOperationError(
        _ operation: String,
        account: String,
        service: String,
        status: OSStatus
    ) -> String {
        """
        \(operation):
        Account: \(account)
        Service: \(service)
        Status: \(status) (\(securityError(for: status)))
        """
    }

    /// Get security error description
    /// - Parameter status: Security framework status code
    /// - Returns: Error description
    private func securityError(for status: OSStatus) -> String {
        let errorDescriptions: [OSStatus: String] = [
            errSecSuccess: "No error",
            errSecUnimplemented: "Function not implemented",
            errSecParam: "Invalid parameters",
            errSecAllocate: "Failed to allocate memory",
            errSecNotAvailable: "No keychain is available",
            errSecDuplicateItem: "Item already exists",
            errSecItemNotFound: "Item not found",
            errSecInteractionNotAllowed: "Interaction not allowed",
            errSecDecode: "Unable to decode data",
            errSecAuthFailed: "Authentication failed",
            errSecInvalidKeychain: "Keychain is invalid",
            errSecNoSuchKeychain: "Keychain does not exist",
            errSecNoAccess: "Access denied",
            errSecReadOnly: "Keychain is read-only",
            errSecNoSuchAttr: "Attribute does not exist",
            errSecInvalidOwnerEdit: "Invalid owner edit",
            errSecDuplicateKeychain: "Keychain already exists",
            errSecInvalidSearchRef: "Invalid search reference",
            errSecInvalidItemRef: "Invalid item reference",
            errSecDataTooLarge: "Data is too large",
            errSecDataNotAvailable: "Data is not available",
            errSecDataNotModifiable: "Data is not modifiable"
        ]
        return errorDescriptions[status] ?? "Unknown error (\(status))"
    }
}
