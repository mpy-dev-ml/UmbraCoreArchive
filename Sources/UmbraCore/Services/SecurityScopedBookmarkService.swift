//
// SecurityScopedBookmarkService.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Service for managing security-scoped bookmarks
@objc
public class SecurityScopedBookmarkService: NSObject {
    // MARK: - Types

    /// Bookmark data with metadata
    public struct BookmarkData: Codable {
        /// Bookmark identifier
        public let id: String
        /// Bookmark data
        public let data: Data
        /// URL path when created
        public let path: String
        /// Creation date
        public let createdAt: Date
        /// Last access date
        public var lastAccessedAt: Date
        /// Access count
        public var accessCount: Int
        /// Is read only
        public let isReadOnly: Bool

        /// Initialize with values
        public init(
            id: String = UUID().uuidString,
            data: Data,
            path: String,
            createdAt: Date = Date(),
            lastAccessedAt: Date = Date(),
            accessCount: Int = 0,
            isReadOnly: Bool
        ) {
            self.id = id
            self.data = data
            self.path = path
            self.createdAt = createdAt
            self.lastAccessedAt = lastAccessedAt
            self.accessCount = accessCount
            self.isReadOnly = isReadOnly
        }
    }

    // MARK: - Properties

    /// Logger for tracking operations
    private let logger: LoggerProtocol

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    /// Bookmark storage
    private var bookmarks: [String: BookmarkData] = [:]

    /// Active access
    private var activeAccess: Set<String> = []

    /// Queue for synchronizing access
    private let queue = DispatchQueue(
        label: "dev.mpy.umbra.bookmark-service",
        attributes: .concurrent
    )

    // MARK: - Initialization

    /// Initialize with dependencies
    @objc
    public init(
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        self.performanceMonitor = performanceMonitor
        self.logger = logger
        super.init()
    }

    // MARK: - Public Methods

    /// Create bookmark for URL
    @objc
    public func createBookmark(
        for url: URL,
        isReadOnly: Bool = true
    ) throws -> BookmarkData {
        return try performanceMonitor.trackDuration(
            "bookmark.create"
        ) {
            let data = try url.bookmarkData(
                options: [
                    .withSecurityScope,
                    .securityScopeAllowOnlyReadAccess
                ],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            let bookmark = BookmarkData(
                data: data,
                path: url.path,
                isReadOnly: isReadOnly
            )

            try storeBookmark(bookmark)
            logBookmarkCreated(bookmark)

            return bookmark
        }
    }

    /// Start accessing URL with bookmark
    @objc
    public func startAccessing(
        _ bookmarkId: String
    ) throws -> URL {
        return try performanceMonitor.trackDuration(
            "bookmark.start_access"
        ) {
            let bookmark = try getBookmark(bookmarkId)

            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmark.data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                throw BookmarkError.staleBookmark(bookmarkId)
            }

            guard url.startAccessingSecurityScopedResource() else {
                throw BookmarkError.accessDenied(url.path)
            }

            try updateBookmarkAccess(bookmarkId)
            markActiveAccess(bookmarkId)
            logBookmarkAccessed(bookmark)

            return url
        }
    }

    /// Stop accessing URL with bookmark
    @objc
    public func stopAccessing(
        _ bookmarkId: String
    ) throws {
        try performanceMonitor.trackDuration(
            "bookmark.stop_access"
        ) {
            let bookmark = try getBookmark(bookmarkId)

            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmark.data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            url.stopAccessingSecurityScopedResource()
            clearActiveAccess(bookmarkId)
            logBookmarkStopped(bookmark)
        }
    }

    /// Remove bookmark
    @objc
    public func removeBookmark(
        _ bookmarkId: String
    ) throws {
        try performanceMonitor.trackDuration(
            "bookmark.remove"
        ) {
            let bookmark = try getBookmark(bookmarkId)

            if isAccessActive(bookmarkId) {
                throw BookmarkError.activeAccess(bookmarkId)
            }

            try deleteBookmark(bookmarkId)
            logBookmarkRemoved(bookmark)
        }
    }

    /// Get all bookmarks
    @objc
    public func getAllBookmarks() -> [BookmarkData] {
        return queue.sync {
            Array(bookmarks.values)
        }
    }

    // MARK: - Private Methods

    /// Get bookmark by ID
    private func getBookmark(
        _ bookmarkId: String
    ) throws -> BookmarkData {
        return try queue.sync {
            guard let bookmark = bookmarks[bookmarkId] else {
                throw BookmarkError.notFound(bookmarkId)
            }
            return bookmark
        }
    }

    /// Store bookmark
    private func storeBookmark(
        _ bookmark: BookmarkData
    ) throws {
        queue.async(flags: .barrier) {
            self.bookmarks[bookmark.id] = bookmark
        }
    }

    /// Delete bookmark
    private func deleteBookmark(
        _ bookmarkId: String
    ) throws {
        queue.async(flags: .barrier) {
            self.bookmarks.removeValue(forKey: bookmarkId)
        }
    }

    /// Update bookmark access
    private func updateBookmarkAccess(
        _ bookmarkId: String
    ) throws {
        queue.async(flags: .barrier) {
            guard var bookmark = self.bookmarks[bookmarkId] else {
                return
            }

            bookmark.lastAccessedAt = Date()
            bookmark.accessCount += 1
            self.bookmarks[bookmarkId] = bookmark
        }
    }

    /// Mark active access
    private func markActiveAccess(
        _ bookmarkId: String
    ) {
        queue.async(flags: .barrier) {
            self.activeAccess.insert(bookmarkId)
        }
    }

    /// Clear active access
    private func clearActiveAccess(
        _ bookmarkId: String
    ) {
        queue.async(flags: .barrier) {
            self.activeAccess.remove(bookmarkId)
        }
    }

    /// Check if access is active
    private func isAccessActive(
        _ bookmarkId: String
    ) -> Bool {
        return queue.sync {
            activeAccess.contains(bookmarkId)
        }
    }

    /// Log bookmark created
    private func logBookmarkCreated(
        _ bookmark: BookmarkData
    ) {
        logger.info(
            "Created security-scoped bookmark",
            config: LogConfig(
                metadata: [
                    "id": bookmark.id,
                    "path": bookmark.path,
                    "readOnly": String(bookmark.isReadOnly)
                ]
            )
        )
    }

    /// Log bookmark accessed
    private func logBookmarkAccessed(
        _ bookmark: BookmarkData
    ) {
        logger.debug(
            "Started accessing security-scoped bookmark",
            config: LogConfig(
                metadata: [
                    "id": bookmark.id,
                    "path": bookmark.path,
                    "accessCount": String(bookmark.accessCount)
                ]
            )
        )
    }

    /// Log bookmark stopped
    private func logBookmarkStopped(
        _ bookmark: BookmarkData
    ) {
        logger.debug(
            "Stopped accessing security-scoped bookmark",
            config: LogConfig(
                metadata: [
                    "id": bookmark.id,
                    "path": bookmark.path
                ]
            )
        )
    }

    /// Log bookmark removed
    private func logBookmarkRemoved(
        _ bookmark: BookmarkData
    ) {
        logger.info(
            "Removed security-scoped bookmark",
            config: LogConfig(
                metadata: [
                    "id": bookmark.id,
                    "path": bookmark.path
                ]
            )
        )
    }

    deinit {
        // Stop accessing any remaining active bookmarks
        queue.sync {
            for bookmarkId in activeAccess {
                if let bookmark = bookmarks[bookmarkId] {
                    do {
                        try stopAccessing(bookmarkId)
                    } catch {
                        logger.error(
                            "Failed to stop accessing bookmark on deinit",
                            config: LogConfig(
                                metadata: [
                                    "id": bookmarkId,
                                    "error": error.localizedDescription
                                ]
                            )
                        )
                    }
                }
            }
        }
    }
}
