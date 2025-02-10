//
// SecurityScopedAccess.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Manages security-scoped access to files and directories in a thread-safe manner
public struct SecurityScopedAccess:
    Codable,
    CustomStringConvertible,
    Equatable
{
    // MARK: - Properties
    
    /// The URL being accessed
    public let url: URL

    /// The security-scoped bookmark data
    private let bookmarkData: Data

    /// Whether this bookmark is currently being accessed
    public private(set) var isAccessing: Bool

    /// Whether this bookmark was created for a directory
    private let isDirectory: Bool

    /// Queue for synchronising access operations
    private static let accessQueue = DispatchQueue(
        label: "dev.mpy.rBUM.SecurityScopedAccess",
        attributes: .concurrent
    )
    
    // MARK: - Initialization
    
    /// Initialize with URL and options
    /// - Parameters:
    ///   - url: URL to create bookmark for
    ///   - isDirectory: Whether URL is a directory
    /// - Throws: SecurityScopedAccessError if bookmark creation fails
    public init(
        url: URL,
        isDirectory: Bool = false
    ) throws {
        self.url = url
        self.isDirectory = isDirectory
        self.isAccessing = false
        
        do {
            let options: URL.BookmarkCreationOptions = isDirectory ? [.withSecurityScope, .securityScopeAllowOnlyReadAccess] : [.withSecurityScope]
            self.bookmarkData = try url.bookmarkData(
                options: options,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            throw SecurityScopedAccessError.bookmarkCreationFailed(error)
        }
    }
    
    /// Initialize with bookmark data
    /// - Parameters:
    ///   - bookmarkData: Security-scoped bookmark data
    ///   - isDirectory: Whether bookmark is for directory
    /// - Throws: SecurityScopedAccessError if bookmark resolution fails
    public init(
        bookmarkData: Data,
        isDirectory: Bool = false
    ) throws {
        self.bookmarkData = bookmarkData
        self.isDirectory = isDirectory
        self.isAccessing = false
        
        do {
            var isStale = false
            let resolvedURL = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                throw SecurityScopedAccessError.staleBookmark(resolvedURL)
            }
            
            self.url = resolvedURL
        } catch {
            throw SecurityScopedAccessError.bookmarkResolutionFailed(error)
        }
    }
    
    // MARK: - Public Methods
    
    /// Start accessing security-scoped resource
    /// - Throws: SecurityScopedAccessError if access is denied
    public mutating func startAccessing() throws {
        try Self.accessQueue.sync(flags: .barrier) {
            guard !isAccessing else { return }
            
            guard url.startAccessingSecurityScopedResource() else {
                throw SecurityScopedAccessError.accessDenied(url)
            }
            
            self.isAccessing = true
        }
    }
    
    /// Stop accessing security-scoped resource
    public mutating func stopAccessing() {
        Self.accessQueue.sync(flags: .barrier) {
            guard isAccessing else { return }
            
            url.stopAccessingSecurityScopedResource()
            self.isAccessing = false
        }
    }
    
    // MARK: - Codable
    
    /// Coding keys for Codable conformance
    private enum CodingKeys: String, CodingKey {
        case url
        case bookmarkData
        case isDirectory
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try container.decode(URL.self, forKey: .url)
        self.bookmarkData = try container.decode(Data.self, forKey: .bookmarkData)
        self.isDirectory = try container.decode(Bool.self, forKey: .isDirectory)
        self.isAccessing = false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        try container.encode(bookmarkData, forKey: .bookmarkData)
        try container.encode(isDirectory, forKey: .isDirectory)
    }
    
    // MARK: - CustomStringConvertible
    
    public var description: String {
        "SecurityScopedAccess(url: \(url.path), isAccessing: \(isAccessing))"
    }
}

// MARK: - Errors

/// Errors that can occur during security-scoped access operations
public enum SecurityScopedAccessError: LocalizedError {
    /// Failed to create bookmark
    case bookmarkCreationFailed(Error)
    /// Failed to resolve bookmark
    case bookmarkResolutionFailed(Error)
    /// Access was denied to URL
    case accessDenied(URL)
    /// URL mismatch during resolution
    case urlMismatch(expected: URL, got: URL)
    /// Bookmark is stale
    case staleBookmark(URL)
    
    public var errorDescription: String? {
        switch self {
        case .bookmarkCreationFailed(let error):
            return "Failed to create security-scoped bookmark: \(error.localizedDescription)"
        case .bookmarkResolutionFailed(let error):
            return "Failed to resolve security-scoped bookmark: \(error.localizedDescription)"
        case .accessDenied(let url):
            return "Access denied to security-scoped resource: \(url.path)"
        case .urlMismatch(let expected, let got):
            return "URL mismatch during bookmark resolution. Expected: \(expected.path), got: \(got.path)"
        case .staleBookmark(let url):
            return "Security-scoped bookmark is stale: \(url.path)"
        }
    }
}
