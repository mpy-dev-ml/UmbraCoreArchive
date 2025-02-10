//
// BookmarkServiceProtocol.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Protocol defining the interface for managing security-scoped bookmarks
///
/// This protocol provides methods for:
/// - Creating and resolving security-scoped bookmarks
/// - Managing bookmark access
/// - Validating bookmark data
/// - Handling bookmark errors
@objc public protocol BookmarkServiceProtocol: NSObjectProtocol {
    /// Create a security-scoped bookmark for a URL
    ///
    /// - Parameter url: URL to create bookmark for
    /// - Returns: Bookmark data
    /// - Throws: BookmarkError if creation fails
    @objc func createBookmark(for url: URL) throws -> Data

    /// Resolve a security-scoped bookmark to its URL
    ///
    /// - Parameter bookmark: Bookmark data to resolve
    /// - Returns: Resolved URL
    /// - Throws: BookmarkError if resolution fails
    @objc func resolveBookmark(_ bookmark: Data) throws -> URL

    /// Start accessing a bookmarked URL
    ///
    /// - Parameter url: URL to access
    /// - Parameter error: Error pointer for Objective-C compatibility
    /// - Returns: true if access was started, false if an error occurred
    @objc func startAccessing(_ url: URL, error: NSErrorPointer) -> Bool

    /// Stop accessing a bookmarked URL
    ///
    /// - Parameter url: URL to stop accessing
    @objc func stopAccessing(_ url: URL)

    /// Validate a security-scoped bookmark
    ///
    /// - Parameter bookmark: Bookmark data to validate
    /// - Parameter error: Error pointer for Objective-C compatibility
    /// - Returns: true if bookmark is valid, false if an error occurred
    @objc func validateBookmark(_ bookmark: Data, error: NSErrorPointer) -> Bool

    /// Check if a URL is currently being accessed
    ///
    /// - Parameter url: URL to check
    /// - Returns: true if URL is being accessed
    @objc func isAccessing(_ url: URL) -> Bool
}
