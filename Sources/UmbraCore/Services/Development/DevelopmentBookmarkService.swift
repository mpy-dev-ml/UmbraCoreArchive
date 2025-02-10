import Foundation

/// Development implementation of BookmarkServiceProtocol for testing and debugging
@objc public final class DevelopmentBookmarkService: BaseSandboxedService, BookmarkServiceProtocol {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with logger and configuration
    /// - Parameters:
    ///   - logger: Logger for tracking operations
    ///   - configuration: Development configuration
    public init(
        logger: LoggerProtocol,
        configuration: ServiceFactory.DevelopmentConfiguration
    ) {
        self.configuration = configuration
        super.init(logger: logger)
    }

    // MARK: - Cleanup

    deinit {
        queue.sync(flags: .barrier) {
            bookmarks.removeAll()
            accessedURLs.removeAll()
        }
    }

    // MARK: Public

    // MARK: - BookmarkServiceProtocol

    public func createBookmark(for url: URL) throws -> Data {
        try simulateDelay()

        if configuration.shouldSimulateBookmarkFailures {
            throw BookmarkError.bookmarkCreationFailed("Simulated failure")
        }

        return try queue.sync(flags: .barrier) {
            let bookmark = try performanceTracker.track("createBookmark") {
                try url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
            }

            bookmarks[url] = bookmark
            return bookmark
        }
    }

    public func resolveBookmark(_ bookmark: Data) throws -> URL {
        try simulateDelay()

        if configuration.shouldSimulateBookmarkFailures {
            throw BookmarkError.bookmarkResolutionFailed("Simulated failure")
        }

        return try queue.sync {
            try performanceTracker.track("resolveBookmark") {
                var isStale = false
                let url = try URL(
                    resolvingBookmarkData: bookmark,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )

                if isStale {
                    throw BookmarkError.bookmarkStale
                }

                return url
            }
        }
    }

    public func startAccessing(_ url: URL) -> Bool {
        queue.sync(flags: .barrier) {
            performanceTracker.track("startAccessing") {
                accessedURLs.insert(url)
                return true
            }
        }
    }

    public func stopAccessing(_ url: URL) {
        queue.sync(flags: .barrier) {
            performanceTracker.track("stopAccessing") {
                accessedURLs.remove(url)
            }
        }
    }

    public func isCurrentlyAccessing(_ url: URL) -> Bool {
        queue.sync {
            performanceTracker.track("isCurrentlyAccessing") {
                accessedURLs.contains(url)
            }
        }
    }

    // MARK: Private

    /// Configuration for the service
    private let configuration: ServiceFactory.DevelopmentConfiguration

    /// In-memory storage for bookmarks
    private var bookmarks: [URL: Data] = [:]

    /// Currently accessed URLs
    private var accessedURLs: Set<URL> = []

    /// Queue for synchronizing access
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.development.bookmark",
        qos: .userInitiated,
        attributes: .concurrent
    )

    /// Performance tracker
    private let performanceTracker: PerformanceTracker = .init()

    /// Resource monitor
    private let resourceMonitor: ResourceMonitor = .init()

    // MARK: - Private Methods

    /// Simulate artificial delay if configured
    private func simulateDelay() throws {
        guard configuration.artificialDelay > 0 else {
            return
        }

        try Task.sleep(
            nanoseconds: UInt64(configuration.artificialDelay * 1_000_000_000)
        )
    }
}
