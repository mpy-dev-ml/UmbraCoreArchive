import Foundation
import Security

/// Service for managing keychain operations
public final class KeychainService: BaseSandboxedService {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - performanceMonitor: Performance monitor
    ///   - logger: Logger for tracking operations
    public init(
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        self.performanceMonitor = performanceMonitor
        super.init(logger: logger)
    }

    // MARK: Public

    // MARK: - Types

    /// Access level for keychain items
    public enum AccessLevel {
        /// When unlocked
        case whenUnlocked
        /// After first unlock
        case afterFirstUnlock
        /// Always
        case always
        /// When passcode set
        case whenPasscodeSet
        /// When unlocked this device only
        case whenUnlockedThisDeviceOnly
        /// After first unlock this device only
        case afterFirstUnlockThisDeviceOnly
        /// Always this device only
        case alwaysThisDeviceOnly
        /// When passcode set this device only
        case whenPasscodeSetThisDeviceOnly

        // MARK: Internal

        /// Convert to Security framework constant
        var securityValue: CFString {
            switch self {
            case .whenUnlocked:
                kSecAttrAccessibleWhenUnlocked

            case .afterFirstUnlock:
                kSecAttrAccessibleAfterFirstUnlock

            case .always:
                kSecAttrAccessibleAlways

            case .whenPasscodeSet:
                kSecAttrAccessibleWhenPasscodeSet

            case .whenUnlockedThisDeviceOnly:
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly

            case .afterFirstUnlockThisDeviceOnly:
                kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

            case .alwaysThisDeviceOnly:
                kSecAttrAccessibleAlwaysThisDeviceOnly

            case .whenPasscodeSetThisDeviceOnly:
                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
            }
        }
    }

    /// Item class for keychain items
    public enum ItemClass {
        /// Generic password
        case genericPassword
        /// Internet password
        case internetPassword
        /// Certificate
        case certificate
        /// Key
        case key
        /// Identity
        case identity

        // MARK: Internal

        /// Convert to Security framework constant
        var securityValue: CFString {
            switch self {
            case .genericPassword:
                kSecClassGenericPassword

            case .internetPassword:
                kSecClassInternetPassword

            case .certificate:
                kSecClassCertificate

            case .key:
                kSecClassKey

            case .identity:
                kSecClassIdentity
            }
        }
    }

    // MARK: - Public Methods

    /// Add item to keychain
    /// - Parameters:
    ///   - data: Item data
    ///   - account: Account identifier
    ///   - service: Service identifier
    ///   - accessGroup: Access group
    ///   - accessLevel: Access level
    ///   - itemClass: Item class
    /// - Throws: Error if operation fails
    public func addItem(
        _ data: Data,
        account: String,
        service: String,
        accessGroup: String? = nil,
        accessLevel: AccessLevel = .whenUnlocked,
        itemClass: ItemClass = .genericPassword
    ) throws {
        try validateUsable(for: "addItem")

        try queue.sync {
            // Build query
            var query = QueryBuilder()
                .setClass(itemClass)
                .setAccount(account)
                .setService(service)
                .setAccessible(accessLevel)
                .setValue(data)
                .build()

            // Add access group if specified
            if let accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup
            }

            // Add item
            let status = SecItemAdd(query as CFDictionary, nil)
            guard status == errSecSuccess else {
                throw KeychainError.addFailed(
                    account: account,
                    service: service,
                    status: status
                )
            }

            logger.debug(
                """
                Added keychain item:
                Account: \(account)
                Service: \(service)
                Access: \(accessLevel)
                Class: \(itemClass)
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Update item in keychain
    /// - Parameters:
    ///   - data: New item data
    ///   - account: Account identifier
    ///   - service: Service identifier
    ///   - accessGroup: Access group
    ///   - itemClass: Item class
    /// - Throws: Error if operation fails
    public func updateItem(
        _ data: Data,
        account: String,
        service: String,
        accessGroup: String? = nil,
        itemClass: ItemClass = .genericPassword
    ) throws {
        try validateUsable(for: "updateItem")

        try queue.sync {
            // Build query
            var query = QueryBuilder()
                .setClass(itemClass)
                .setAccount(account)
                .setService(service)
                .build()

            // Add access group if specified
            if let accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup
            }

            // Build attributes
            let attributes = [
                kSecValueData as String: data
            ]

            // Update item
            let status = SecItemUpdate(
                query as CFDictionary,
                attributes as CFDictionary
            )

            guard status == errSecSuccess else {
                throw KeychainError.updateFailed(
                    account: account,
                    service: service,
                    status: status
                )
            }

            logger.debug(
                """
                Updated keychain item:
                Account: \(account)
                Service: \(service)
                Class: \(itemClass)
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Delete item from keychain
    /// - Parameters:
    ///   - account: Account identifier
    ///   - service: Service identifier
    ///   - accessGroup: Access group
    ///   - itemClass: Item class
    /// - Throws: Error if operation fails
    public func deleteItem(
        account: String,
        service: String,
        accessGroup: String? = nil,
        itemClass: ItemClass = .genericPassword
    ) throws {
        try validateUsable(for: "deleteItem")

        try queue.sync {
            // Build query
            var query = QueryBuilder()
                .setClass(itemClass)
                .setAccount(account)
                .setService(service)
                .build()

            // Add access group if specified
            if let accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup
            }

            // Delete item
            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw KeychainError.deleteFailed(
                    account: account,
                    service: service,
                    status: status
                )
            }

            logger.debug(
                """
                Deleted keychain item:
                Account: \(account)
                Service: \(service)
                Class: \(itemClass)
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Get item from keychain
    /// - Parameters:
    ///   - account: Account identifier
    ///   - service: Service identifier
    ///   - accessGroup: Access group
    ///   - itemClass: Item class
    /// - Returns: Item data if found
    /// - Throws: Error if operation fails
    public func getItem(
        account: String,
        service: String,
        accessGroup: String? = nil,
        itemClass: ItemClass = .genericPassword
    ) throws -> Data {
        try validateUsable(for: "getItem")

        return try queue.sync {
            // Build query
            var query = QueryBuilder()
                .setClass(itemClass)
                .setAccount(account)
                .setService(service)
                .setReturnData(true)
                .build()

            // Add access group if specified
            if let accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup
            }

            // Get item
            var result: AnyObject?
            let status = SecItemCopyMatching(
                query as CFDictionary,
                &result
            )

            guard status == errSecSuccess,
                  let data = result as? Data
            else {
                throw KeychainError.getFailed(
                    account: account,
                    service: service,
                    status: status
                )
            }

            return data
        }
    }

    /// Check if item exists in keychain
    /// - Parameters:
    ///   - account: Account identifier
    ///   - service: Service identifier
    ///   - accessGroup: Access group
    ///   - itemClass: Item class
    /// - Returns: Whether item exists
    /// - Throws: Error if operation fails
    public func containsItem(
        account: String,
        service: String,
        accessGroup: String? = nil,
        itemClass: ItemClass = .genericPassword
    ) throws -> Bool {
        try validateUsable(for: "containsItem")

        return try queue.sync {
            // Build query
            var query = QueryBuilder()
                .setClass(itemClass)
                .setAccount(account)
                .setService(service)
                .build()

            // Add access group if specified
            if let accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup
            }

            // Check item
            let status = SecItemCopyMatching(
                query as CFDictionary,
                nil
            )

            switch status {
            case errSecSuccess:
                return true

            case errSecItemNotFound:
                return false

            default:
                throw KeychainError.operationFailed(
                    "Failed to check item existence: \(status)"
                )
            }
        }
    }

    // MARK: Private

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.keychain",
        qos: .userInitiated,
        attributes: .concurrent
    )

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor
}
