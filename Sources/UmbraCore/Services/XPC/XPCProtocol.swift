@preconcurrency import Foundation

// MARK: - XPCProtocol

/// Protocol for XPC communication
@objc
public protocol XPCProtocol {
    /// Ping connection
    @objc
    func ping() async throws -> Bool

    /// Validate connection state
    @objc
    func validateState() async throws -> Bool

    /// Get connection info
    @objc
    func getConnectionInfo() async throws -> [String: Any]

    /// Handle error
    @objc
    func handleError(_ error: Error) async throws
}

/// Default implementations for XPCProtocol
public extension XPCProtocol {
    @objc
    func ping() async throws -> Bool {
        true
    }

    @objc
    func validateState() async throws -> Bool {
        true
    }

    @objc
    func getConnectionInfo() async throws -> [String: Any] {
        [:]
    }

    @objc
    func handleError(_: Error) async throws {
        // Default implementation does nothing
    }
}

// MARK: - XPCServiceDelegate

/// Protocol for XPC service delegate
@objc
public protocol XPCServiceDelegate: AnyObject {
    /// Called when connection is established
    @objc
    optional func xpcServiceDidConnect(_ service: XPCService)

    /// Called when connection is interrupted
    @objc
    optional func xpcServiceDidInterrupt(_ service: XPCService)

    /// Called when connection is invalidated
    @objc
    optional func xpcServiceDidInvalidate(_ service: XPCService)

    /// Called when error occurs
    @objc
    optional func xpcService(_ service: XPCService, didEncounterError error: Error)
}

// MARK: - XPCServiceListener

/// Protocol for XPC service listener
@objc
public protocol XPCServiceListener: AnyObject {
    /// Called when message is received
    @objc
    func xpcService(
        _ service: XPCService,
        didReceiveMessage message: [String: Any]
    )

    /// Called when request is received
    @objc
    func xpcService(
        _ service: XPCService,
        didReceiveRequest request: [String: Any],
        reply: @escaping ([String: Any]?) -> Void
    )
}
