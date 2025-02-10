//
// SecurityService+AccessControl.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

extension SecurityService {
    // MARK: - Access Control

    /// Request permission to access a URL
    /// - Parameter url: URL to request permission for
    /// - Returns: true if permission was granted
    /// - Throws: SecurityError if permission request fails
    public func requestPermission(for url: URL) async throws -> Bool {
        try validateUsable(for: "requestPermission")

        logger.debug(
            "Requesting permission for: \(url.path)",
            file: #file,
            function: #function,
            line: #line
        )

        do {
            // Check if we already have permission
            if let bookmark = getActiveBookmark(for: url) {
                do {
                    _ = try resolveBookmark(bookmark)
                    return true
                } catch SecurityError.bookmarkStale {
                    // Bookmark is stale, remove it and continue
                    removeActiveBookmark(for: url)
                } catch {
                    throw error
                }
            }

            // Create new bookmark
            _ = try createBookmark(for: url)
            return true
        } catch {
            logger.error(
                """
                Failed to request permission for \(url.path): \
                \(error.localizedDescription)
                """,
                file: #file,
                function: #function,
                line: #line
            )
            throw SecurityError.permissionDenied(error.localizedDescription)
        }
    }

    /// Validate access to a URL
    /// - Parameter url: URL to validate
    /// - Returns: true if access is valid
    /// - Throws: SecurityError if validation fails
    public func validateAccess(to url: URL) throws -> Bool {
        try validateUsable(for: "validateAccess")

        guard let bookmark = getActiveBookmark(for: url) else {
            logger.warning(
                "No bookmark found for: \(url.path)",
                file: #file,
                function: #function,
                line: #line
            )
            return false
        }

        do {
            _ = try resolveBookmark(bookmark)
            return true
        } catch SecurityError.bookmarkStale {
            logger.warning(
                "Bookmark is stale for: \(url.path)",
                file: #file,
                function: #function,
                line: #line
            )
            removeActiveBookmark(for: url)
            return false
        } catch {
            logger.error(
                """
                Failed to validate access for \(url.path): \
                \(error.localizedDescription)
                """,
                file: #file,
                function: #function,
                line: #line
            )
            throw error
        }
    }

    /// Revoke access to a URL
    /// - Parameter url: URL to revoke access from
    public func revokeAccess(to url: URL) {
        logger.debug(
            "Revoking access to: \(url.path)",
            file: #file,
            function: #function,
            line: #line
        )

        stopAccessing(url)
        removeActiveBookmark(for: url)
    }

    /// Clean up all access
    public func cleanupAccess() {
        bookmarkQueue.sync(flags: .barrier) {
            // Stop accessing all URLs
            for url in accessedUrls {
                url.stopAccessingSecurityScopedResource()
                logger.debug(
                    "Stopped accessing: \(url.path)",
                    file: #file,
                    function: #function,
                    line: #line
                )
            }
            accessedUrls.removeAll()

            // Clear all bookmarks
            activeBookmarks.removeAll()
            logger.debug(
                "Cleared all bookmarks",
                file: #file,
                function: #function,
                line: #line
            )
        }
    }
}
