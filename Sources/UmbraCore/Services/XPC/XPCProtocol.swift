//
// XPCProtocol.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Protocol for XPC communication
@objc public protocol XPCProtocol {
    /// Ping connection
    /// - Returns: True if connection is healthy
    /// - Throws: Error if ping fails
    @objc func ping() async throws -> Bool

    /// Validate connection state
    /// - Returns: True if connection state is valid
    /// - Throws: Error if validation fails
    @objc func validateState() async throws -> Bool

    /// Get connection info
    /// - Returns: Dictionary of connection info
    /// - Throws: Error if info retrieval fails
    @objc func getConnectionInfo() async throws -> [String: Any]

    /// Handle error
    /// - Parameter error: Error to handle
    /// - Throws: Error if handling fails
    @objc func handleError(_ error: Error) async throws
}

/// Default implementations for XPCProtocol
public extension XPCProtocol {
    func ping() async throws -> Bool {
        return true
    }

    func validateState() async throws -> Bool {
        return true
    }

    func getConnectionInfo() async throws -> [String: Any] {
        return [:]
    }

    func handleError(_ error: Error) async throws {
        // Default implementation does nothing
    }
}

/// Protocol for XPC service delegate
@objc public protocol XPCServiceDelegate: AnyObject {
    /// Called when connection is established
    /// - Parameter service: XPC service
    @objc optional func xpcServiceDidConnect(_ service: XPCService)

    /// Called when connection is interrupted
    /// - Parameter service: XPC service
    @objc optional func xpcServiceDidInterrupt(_ service: XPCService)

    /// Called when connection is invalidated
    /// - Parameter service: XPC service
    @objc optional func xpcServiceDidInvalidate(_ service: XPCService)

    /// Called when error occurs
    /// - Parameters:
    ///   - service: XPC service
    ///   - error: Error that occurred
    @objc optional func xpcService(_ service: XPCService, didEncounterError error: Error)
}

/// Protocol for XPC service listener
@objc public protocol XPCServiceListener: AnyObject {
    /// Called when message is received
    /// - Parameters:
    ///   - service: XPC service
    ///   - message: Message data
    @objc func xpcService(
        _ service: XPCService,
        didReceiveMessage message: [String: Any]
    )

    /// Called when request is received
    /// - Parameters:
    ///   - service: XPC service
    ///   - request: Request data
    ///   - reply: Reply handler
    @objc func xpcService(
        _ service: XPCService,
        didReceiveRequest request: [String: Any],
        reply: @escaping ([String: Any]?) -> Void
    )
}
