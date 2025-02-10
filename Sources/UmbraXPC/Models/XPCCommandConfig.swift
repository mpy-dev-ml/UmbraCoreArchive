//
// XPCCommandConfig.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Configuration for XPC command execution
@objc
public class XPCCommandConfig: NSObject, NSSecureCoding {
    // MARK: - Types
    /// Type alias for environment variables dictionary
    public typealias Environment = [String: String]
    /// Type alias for security bookmarks dictionary
    public typealias Bookmarks = [String: NSData]

    // MARK: - Properties
    /// Whether this class supports secure coding
    @objc public static var supportsSecureCoding: Bool { true }
    /// Command to execute
    @objc public let command: String
    /// Command arguments
    @objc public let arguments: [String]
    /// Environment variables
    @objc public let environment: Environment
    /// Working directory
    @objc public let workingDirectory: String
    /// Security-scoped bookmarks
    @objc public let bookmarks: Bookmarks
    /// Command timeout
    @objc public let timeout: TimeInterval
    /// Audit session identifier
    @objc public let auditSessionId: au_asid_t

    // MARK: - Initialization
    /// Initialize with command configuration
    /// - Parameters:
    ///   - command: Command to execute
    ///   - arguments: Command arguments
    ///   - environment: Environment variables
    ///   - workingDirectory: Working directory
    ///   - bookmarks: Security-scoped bookmarks
    ///   - timeout: Command timeout
    ///   - auditSessionId: Audit session identifier
    @objc
    public init(
        command: String,
        arguments: [String] = [],
        environment: Environment = [:],
        workingDirectory: String = FileManager.default.currentDirectoryPath,
        bookmarks: Bookmarks = [:],
        timeout: TimeInterval = 0,
        auditSessionId: au_asid_t = 0
    ) {
        self.command = command
        self.arguments = arguments
        self.environment = environment
        self.workingDirectory = workingDirectory
        self.bookmarks = bookmarks
        self.timeout = timeout
        self.auditSessionId = auditSessionId
        super.init()
    }

    // MARK: - NSSecureCoding
    /// Initialize from decoder
    /// - Parameter coder: Decoder to read from
    @objc
    public required init?(coder: NSCoder) {
        guard let values = Self.decodeRequiredValues(from: coder) else {
            return nil
        }

        self.command = values.command
        self.arguments = values.arguments
        self.environment = values.environment
        self.workingDirectory = values.workingDirectory
        self.bookmarks = values.bookmarks
        self.timeout = values.timeout
        self.auditSessionId = values.auditSessionId
        super.init()
    }

    /// Encode to coder
    /// - Parameter coder: Coder to write to
    @objc
    public func encode(with coder: NSCoder) {
        coder.encode(command, forKey: CodingKeys.command)
        coder.encode(arguments, forKey: CodingKeys.arguments)
        coder.encode(environment, forKey: CodingKeys.environment)
        coder.encode(workingDirectory, forKey: CodingKeys.workingDirectory)
        coder.encode(bookmarks, forKey: CodingKeys.bookmarks)
        coder.encode(timeout, forKey: CodingKeys.timeout)
        coder.encode(Int32(auditSessionId), forKey: CodingKeys.auditSessionId)
    }
}

// MARK: - Decoding Helpers
private extension XPCCommandConfig {
    /// Structure to hold decoded values
    struct DecodedValues {
        let command: String
        let arguments: [String]
        let environment: Environment
        let workingDirectory: String
        let bookmarks: Bookmarks
        let timeout: TimeInterval
        let auditSessionId: au_asid_t
    }

    /// Decode all required values from the coder
    /// - Parameter coder: The decoder to read from
    /// - Returns: DecodedValues containing all decoded values, or nil if any decoding fails
    static func decodeRequiredValues(from coder: NSCoder) -> DecodedValues? {
        // Decode required string values
        guard let command = decodeString(from: coder, forKey: .command),
              let workingDir = decodeString(from: coder, forKey: .workingDirectory)
        else {
            return nil
        }

        // Decode arrays and dictionaries
        guard let arguments = decodeStringArray(from: coder),
              let environment = decodeEnvironment(from: coder),
              let bookmarks = decodeBookmarks(from: coder)
        else {
            return nil
        }

        // Decode numeric values
        let timeout = coder.decodeDouble(forKey: CodingKeys.timeout)
        let sessionId = au_asid_t(coder.decodeInt32(forKey: CodingKeys.auditSessionId))

        return DecodedValues(
            command: command,
            arguments: arguments,
            environment: environment,
            workingDirectory: workingDir,
            bookmarks: bookmarks,
            timeout: timeout,
            auditSessionId: sessionId
        )
    }

    /// Decode a string value from the coder
    /// - Parameters:
    ///   - coder: The decoder to read from
    ///   - key: The coding key to decode
    /// - Returns: The decoded string, or nil if decoding fails
    static func decodeString(
        from coder: NSCoder,
        forKey key: CodingKeys
    ) -> String? {
        coder.decodeObject(of: NSString.self, forKey: key.rawValue) as? String
    }

    /// Decode string array from the coder
    /// - Parameter coder: The decoder to read from
    /// - Returns: The decoded string array, or nil if decoding fails
    static func decodeStringArray(from coder: NSCoder) -> [String]? {
        let allowedTypes = [NSArray.self, NSString.self]
        return coder.decodeObject(of: allowedTypes, forKey: CodingKeys.arguments.rawValue) as? [String]
    }

    /// Decode environment dictionary from the coder
    /// - Parameter coder: The decoder to read from
    /// - Returns: The decoded environment dictionary, or nil if decoding fails
    static func decodeEnvironment(from coder: NSCoder) -> Environment? {
        let allowedTypes = [NSDictionary.self, NSString.self]
        return coder.decodeObject(of: allowedTypes, forKey: CodingKeys.environment.rawValue) as? Environment
    }

    /// Decode bookmarks dictionary from the coder
    /// - Parameter coder: The decoder to read from
    /// - Returns: The decoded bookmarks dictionary, or nil if decoding fails
    static func decodeBookmarks(from coder: NSCoder) -> Bookmarks? {
        let allowedTypes = [NSDictionary.self, NSString.self, NSData.self]
        return coder.decodeObject(of: allowedTypes, forKey: CodingKeys.bookmarks.rawValue) as? Bookmarks
    }
}

// MARK: - Constants
private extension XPCCommandConfig {
    enum CodingKeys: String {
        case command
        case arguments
        case environment
        case workingDirectory
        case bookmarks
        case timeout
        case auditSessionId
    }
}
