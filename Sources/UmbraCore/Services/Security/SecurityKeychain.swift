import Foundation
import Security

/// Service for managing keychain operations
public final class SecurityKeychain: BaseSandboxedService {
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

    /// Keychain item accessibility
    public enum Accessibility {
        /// After first unlock
        case afterFirstUnlock
        /// When unlocked
        case whenUnlocked
        /// Always
        case always

        // MARK: Internal

        /// Convert to Security framework value
        var securityValue: CFString {
            switch self {
            case .afterFirstUnlock:
                kSecAttrAccessibleAfterFirstUnlock

            case .whenUnlocked:
                kSecAttrAccessibleWhenUnlocked

            case .always:
                kSecAttrAccessibleAlways
            }
        }
    }

    /// Keychain item attributes
    public struct ItemAttributes {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            service: String,
            account: String,
            accessGroup: String? = nil,
            accessibility: Accessibility = .afterFirstUnlock,
            synchronizable: Bool = false
        ) {
            self.service = service
            self.account = account
            self.accessGroup = accessGroup
            self.accessibility = accessibility
            self.synchronizable = synchronizable
        }

        // MARK: Public

        /// Service name
        public let service: String

        /// Account name
        public let account: String

        /// Access group
        public let accessGroup: String?

        /// Accessibility
        public let accessibility: Accessibility

        /// Synchronize with iCloud
        public let synchronizable: Bool
    }

    // MARK: - Public Methods

    /// Save item to keychain
    /// - Parameters:
    ///   - data: Data to save
    ///   - attributes: Item attributes
    /// - Throws: Error if operation fails
    public func saveItem(
        _ data: Data,
        attributes: ItemAttributes
    ) async throws {
        try validateUsable(for: "saveItem")

        try await performanceMonitor.trackDuration("keychain.save") {
            // Create query
            var query = baseQuery(for: attributes)
            query[kSecValueData as String] = data

            // Add item
            let status = SecItemAdd(query as CFDictionary, nil)

            if status == errSecDuplicateItem {
                // Update existing item
                let updateQuery = baseQuery(for: attributes)
                let updateAttributes = [kSecValueData as String: data]

                let updateStatus = SecItemUpdate(
                    updateQuery as CFDictionary,
                    updateAttributes as CFDictionary
                )

                guard updateStatus == errSecSuccess else {
                    throw SecurityError.keychainError(
                        "Failed to update item: \(updateStatus)"
                    )
                }
            } else if status != errSecSuccess {
                throw SecurityError.keychainError(
                    "Failed to add item: \(status)"
                )
            }

            // Log operation
            logger.debug(
                """
                Saved keychain item:
                Service: \(attributes.service)
                Account: \(attributes.account)
                Size: \(data.count) bytes
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Load item from keychain
    /// - Parameter attributes: Item attributes
    /// - Returns: Item data
    /// - Throws: Error if operation fails
    public func loadItem(
        attributes: ItemAttributes
    ) async throws -> Data {
        try validateUsable(for: "loadItem")

        return try await performanceMonitor.trackDuration("keychain.load") {
            // Create query
            var query = baseQuery(for: attributes)
            query[kSecReturnData as String] = true

            // Load item
            var result: AnyObject?
            let status = SecItemCopyMatching(
                query as CFDictionary,
                &result
            )

            guard status == errSecSuccess,
                  let data = result as? Data
            else {
                throw SecurityError.keychainError(
                    "Failed to load item: \(status)"
                )
            }

            // Log operation
            logger.debug(
                """
                Loaded keychain item:
                Service: \(attributes.service)
                Account: \(attributes.account)
                Size: \(data.count) bytes
                """,
                file: #file,
                function: #function,
                line: #line
            )

            return data
        }
    }

    /// Delete item from keychain
    /// - Parameter attributes: Item attributes
    /// - Throws: Error if operation fails
    public func deleteItem(
        attributes: ItemAttributes
    ) async throws {
        try validateUsable(for: "deleteItem")

        try await performanceMonitor.trackDuration("keychain.delete") {
            // Create query
            let query = baseQuery(for: attributes)

            // Delete item
            let status = SecItemDelete(query as CFDictionary)

            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw SecurityError.keychainError(
                    "Failed to delete item: \(status)"
                )
            }

            // Log operation
            logger.debug(
                """
                Deleted keychain item:
                Service: \(attributes.service)
                Account: \(attributes.account)
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    // MARK: Private

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.security.keychain",
        qos: .userInitiated,
        attributes: .concurrent
    )

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    // MARK: - Private Methods

    /// Create base query for attributes
    private func baseQuery(
        for attributes: ItemAttributes
    ) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: attributes.service,
            kSecAttrAccount as String: attributes.account,
            kSecAttrAccessible as String: attributes.accessibility.securityValue,
            kSecAttrSynchronizable as String: attributes.synchronizable
        ]

        if let accessGroup = attributes.accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }
}
