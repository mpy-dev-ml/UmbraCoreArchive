@preconcurrency import Foundation
import Security

/// Builder for keychain queries
public struct QueryBuilder {
    // MARK: Lifecycle

    /// Initialize empty builder
    public init() {
        query = [:]
    }

    // MARK: Public

    /// Set item class
    /// - Parameter itemClass: Item class
    /// - Returns: Updated builder
    public func setClass(
        _ itemClass: KeychainService.ItemClass
    ) -> Self {
        var builder = self
        builder.query[kSecClass as String] = itemClass.securityValue
        return builder
    }

    /// Set account
    /// - Parameter account: Account identifier
    /// - Returns: Updated builder
    public func setAccount(_ account: String) -> Self {
        var builder = self
        builder.query[kSecAttrAccount as String] = account
        return builder
    }

    /// Set service
    /// - Parameter service: Service identifier
    /// - Returns: Updated builder
    public func setService(_ service: String) -> Self {
        var builder = self
        builder.query[kSecAttrService as String] = service
        return builder
    }

    /// Set access level
    /// - Parameter accessLevel: Access level
    /// - Returns: Updated builder
    public func setAccessible(
        _ accessLevel: KeychainService.AccessLevel
    ) -> Self {
        var builder = self
        builder.query[kSecAttrAccessible as String] = accessLevel.securityValue
        return builder
    }

    /// Set value
    /// - Parameter value: Value data
    /// - Returns: Updated builder
    public func setValue(_ value: Data) -> Self {
        var builder = self
        builder.query[kSecValueData as String] = value
        return builder
    }

    /// Set return type
    /// - Parameter type: Return type
    /// - Returns: Updated builder
    public func setReturnType(_ type: CFString) -> Self {
        var builder = self
        builder.query[kSecReturnType as String] = type
        return builder
    }

    /// Set return data
    /// - Parameter returnData: Whether to return data
    /// - Returns: Updated builder
    public func setReturnData(_ returnData: Bool) -> Self {
        var builder = self
        builder.query[kSecReturnData as String] = returnData
        return builder
    }

    /// Set return attributes
    /// - Parameter returnAttributes: Whether to return attributes
    /// - Returns: Updated builder
    public func setReturnAttributes(
        _ returnAttributes: Bool
    ) -> Self {
        var builder = self
        builder.query[kSecReturnAttributes as String] = returnAttributes
        return builder
    }

    /// Set return reference
    /// - Parameter returnRef: Whether to return reference
    /// - Returns: Updated builder
    public func setReturnReference(
        _ returnRef: Bool
    ) -> Self {
        var builder = self
        builder.query[kSecReturnRef as String] = returnRef
        return builder
    }

    /// Set match limit
    /// - Parameter limit: Match limit
    /// - Returns: Updated builder
    public func setMatchLimit(_ limit: CFString) -> Self {
        var builder = self
        builder.query[kSecMatchLimit as String] = limit
        return builder
    }

    /// Set search policy
    /// - Parameter policy: Search policy
    /// - Returns: Updated builder
    public func setSearchPolicy(_ policy: SecPolicy) -> Self {
        var builder = self
        builder.query[kSecMatchPolicy as String] = policy
        return builder
    }

    /// Build query dictionary
    /// - Returns: Query dictionary
    public func build() -> [String: Any] {
        query
    }

    // MARK: Private

    /// Query dictionary
    private var query: [String: Any]
}
