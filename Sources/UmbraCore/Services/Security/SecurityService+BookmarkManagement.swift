@preconcurrency import Foundation

public extension SecurityService {
    // MARK: - Bookmark Management

    /// Get active bookmark for a URL
    /// - Parameter url: URL to get bookmark for
    /// - Returns: Bookmark data if available
    internal func getActiveBookmark(for url: URL) -> Data? {
        bookmarkQueue.sync {
            activeBookmarks[url]
        }
    }

    /// Set active bookmark for a URL
    /// - Parameters:
    ///   - bookmark: Bookmark data to set
    ///   - url: URL to set bookmark for
    internal func setActiveBookmark(_ bookmark: Data, for url: URL) {
        bookmarkQueue.sync(flags: .barrier) {
            activeBookmarks[url] = bookmark
            logger.debug(
                "Set active bookmark for: \(url.path)",
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Remove active bookmark for a URL
    /// - Parameter url: URL to remove bookmark for
    internal func removeActiveBookmark(for url: URL) {
        bookmarkQueue.sync(flags: .barrier) {
            if activeBookmarks.removeValue(forKey: url) != nil {
                logger.debug(
                    "Removed active bookmark for: \(url.path)",
                    file: #file,
                    function: #function,
                    line: #line
                )
            }
        }
    }

    /// Create a security-scoped bookmark for a URL
    /// - Parameter url: URL to create bookmark for
    /// - Returns: Bookmark data
    /// - Throws: SecurityError if bookmark creation fails
    func createBookmark(for url: URL) throws -> Data {
        try validateUsable(for: "createBookmark")

        logger.debug(
            "Creating bookmark for: \(url.path)",
            file: #file,
            function: #function,
            line: #line
        )

        do {
            let bookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            setActiveBookmark(bookmark, for: url)
            return bookmark
        } catch {
            logger.error(
                """
                Failed to create bookmark for \(url.path): \
                \(error.localizedDescription)
                """,
                file: #file,
                function: #function,
                line: #line
            )
            throw SecurityError.bookmarkCreationFailed(error.localizedDescription)
        }
    }

    /// Resolve a security-scoped bookmark
    /// - Parameter bookmark: Bookmark data to resolve
    /// - Returns: Resolved URL
    /// - Throws: SecurityError if bookmark resolution fails
    func resolveBookmark(_ bookmark: Data) throws -> URL {
        try validateUsable(for: "resolveBookmark")

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmark,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                logger.warning(
                    "Bookmark is stale for: \(url.path)",
                    file: #file,
                    function: #function,
                    line: #line
                )
                throw SecurityError.bookmarkStale
            }

            return url
        } catch {
            logger.error(
                """
                Failed to resolve bookmark: \
                \(error.localizedDescription)
                """,
                file: #file,
                function: #function,
                line: #line
            )
            throw SecurityError.bookmarkResolutionFailed(error.localizedDescription)
        }
    }

    /// Start accessing a security-scoped resource
    /// - Parameter url: URL to access
    /// - Returns: true if access was started successfully
    func startAccessing(_ url: URL) -> Bool {
        bookmarkQueue.sync(flags: .barrier) {
            guard !accessedURLs.contains(url) else {
                return true
            }

            let success = url.startAccessingSecurityScopedResource()
            if success {
                accessedURLs.insert(url)
                logger.debug(
                    "Started accessing: \(url.path)",
                    file: #file,
                    function: #function,
                    line: #line
                )
            } else {
                logger.warning(
                    "Failed to start accessing: \(url.path)",
                    file: #file,
                    function: #function,
                    line: #line
                )
            }
            return success
        }
    }

    /// Stop accessing a security-scoped resource
    /// - Parameter url: URL to stop accessing
    func stopAccessing(_ url: URL) {
        bookmarkQueue.sync(flags: .barrier) {
            guard accessedURLs.contains(url) else {
                return
            }

            url.stopAccessingSecurityScopedResource()
            accessedURLs.remove(url)
            logger.debug(
                "Stopped accessing: \(url.path)",
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Check if currently accessing a URL
    /// - Parameter url: URL to check
    /// - Returns: true if currently accessing
    func isCurrentlyAccessing(_ url: URL) -> Bool {
        bookmarkQueue.sync {
            accessedURLs.contains(url)
        }
    }
}
