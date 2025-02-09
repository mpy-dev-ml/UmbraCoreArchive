//
// KeychainCredentials.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Represents credentials stored in the Keychain
public struct KeychainCredentials: Codable, CustomStringConvertible {
    /// The username or account name
    public let username: String

    /// The password or secret
    public let password: String

    /// Additional metadata if needed
    public let metadata: [String: String]?

    public init(username: String, password: String, metadata: [String: String]? = nil) {
        self.username = username
        self.password = password
        self.metadata = metadata
    }
}

    public var description: String {
        return String(describing: self)
    }
