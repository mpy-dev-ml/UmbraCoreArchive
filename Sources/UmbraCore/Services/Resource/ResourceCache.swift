import Foundation

/// Service for caching resource data
public final class ResourceCache: BaseSandboxedService {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - configuration: Cache configuration
    ///   - persistence: Persistence service
    ///   - performanceMonitor: Performance monitor
    ///   - logger: Logger for tracking operations
    public init(
        configuration: Configuration = Configuration(),
        persistence: PersistenceService,
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        self.configuration = configuration
        self.persistence = persistence
        self.performanceMonitor = performanceMonitor
        super.init(logger: logger)
        setupCleanupTimer()
    }

    // MARK: - Deinitializer

    deinit {
        cleanupTimer?.invalidate()
    }

    // MARK: Public

    // MARK: - Types

    /// Cache configuration
    public struct Configuration {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            maxSize: Int64 = 100 * 1_024 * 1_024, // 100MB
            maxItems: Int = 1_000,
            cleanupInterval: TimeInterval = 300, // 5 minutes
            useMemoryCache: Bool = true,
            useDiskCache: Bool = true
        ) {
            self.maxSize = maxSize
            self.maxItems = maxItems
            self.cleanupInterval = cleanupInterval
            self.useMemoryCache = useMemoryCache
            self.useDiskCache = useDiskCache
        }

        // MARK: Public

        /// Maximum cache size in bytes
        public let maxSize: Int64

        /// Maximum number of items
        public let maxItems: Int

        /// Cache cleanup interval
        public let cleanupInterval: TimeInterval

        /// Whether to use memory cache
        public let useMemoryCache: Bool

        /// Whether to use disk cache
        public let useDiskCache: Bool
    }

    // MARK: - Public Methods

    /// Store resource in cache
    /// - Parameters:
    ///   - data: Resource data
    ///   - metadata: Resource metadata
    /// - Throws: Error if store fails
    public func storeResource(
        _ data: Data,
        metadata: ResourceService.ResourceMetadata
    ) async throws {
        try validateUsable(for: "storeResource")

        try await performanceMonitor.trackDuration("resource.cache.store") {
            // Create entry
            let entry = CacheEntry(
                data: data,
                metadata: metadata
            )

            // Store in memory cache
            if configuration.useMemoryCache {
                queue.async(flags: .barrier) {
                    self.memoryCache[metadata.identifier] = entry
                    self.currentSize += Int64(data.count)
                }
            }

            // Store in disk cache
            if configuration.useDiskCache {
                try await persistence.save(
                    data,
                    forKey: getCacheKey(for: metadata.identifier)
                )
            }

            // Log operation
            logger.debug(
                """
                Cached resource:
                ID: \(metadata.identifier)
                Size: \(data.count) bytes
                """,
                file: #file,
                function: #function,
                line: #line
            )

            // Check cache limits
            if currentSize > configuration.maxSize ||
                memoryCache.count > configuration.maxItems {
                try await cleanup()
            }
        }
    }

    /// Load resource from cache
    /// - Parameter identifier: Resource identifier
    /// - Returns: Resource data and metadata
    /// - Throws: Error if load fails
    public func loadResource(
        _ identifier: String
    ) async throws -> (Data, ResourceService.ResourceMetadata) {
        try validateUsable(for: "loadResource")

        return try await performanceMonitor.trackDuration("resource.cache.load") {
            // Try memory cache
            if configuration.useMemoryCache,
               var entry = memoryCache[identifier] {
                // Update access info
                entry.lastAccess = Date()
                entry.accessCount += 1

                queue.async(flags: .barrier) {
                    self.memoryCache[identifier] = entry
                }

                return (entry.data, entry.metadata)
            }

            // Try disk cache
            if configuration.useDiskCache {
                let data = try await persistence.load(
                    forKey: getCacheKey(for: identifier)
                )

                // TODO: Load metadata from disk
                throw ResourceError.cacheError("Disk cache not implemented")
            }

            throw ResourceError.resourceNotFound(identifier)
        }
    }

    /// Remove resource from cache
    /// - Parameter identifier: Resource identifier
    /// - Throws: Error if removal fails
    public func removeResource(
        _ identifier: String
    ) async throws {
        try validateUsable(for: "removeResource")

        try await performanceMonitor.trackDuration("resource.cache.remove") {
            // Remove from memory cache
            if configuration.useMemoryCache {
                queue.async(flags: .barrier) {
                    if let entry = self.memoryCache.removeValue(forKey: identifier) {
                        self.currentSize -= Int64(entry.data.count)
                    }
                }
            }

            // Remove from disk cache
            if configuration.useDiskCache {
                try await persistence.remove(
                    forKey: getCacheKey(for: identifier)
                )
            }

            // Log operation
            logger.debug(
                """
                Removed cached resource:
                ID: \(identifier)
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Clear cache
    /// - Throws: Error if clear fails
    public func clearCache() async throws {
        try validateUsable(for: "clearCache")

        try await performanceMonitor.trackDuration("resource.cache.clear") {
            // Clear memory cache
            if configuration.useMemoryCache {
                queue.async(flags: .barrier) {
                    self.memoryCache.removeAll()
                    self.currentSize = 0
                }
            }

            // Clear disk cache
            if configuration.useDiskCache {
                try await persistence.clearAll()
            }

            // Log operation
            logger.debug(
                "Cleared resource cache",
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    // MARK: Private

    /// Cache entry
    private struct CacheEntry {
        // MARK: Lifecycle

        /// Initialize with values
        init(
            data: Data,
            metadata: ResourceService.ResourceMetadata,
            lastAccess: Date = Date(),
            accessCount: Int = 0
        ) {
            self.data = data
            self.metadata = metadata
            self.lastAccess = lastAccess
            self.accessCount = accessCount
        }

        // MARK: Internal

        /// Resource data
        let data: Data

        /// Resource metadata
        let metadata: ResourceService.ResourceMetadata

        /// Last access date
        var lastAccess: Date

        /// Access count
        var accessCount: Int
    }

    /// Cache configuration
    private let configuration: Configuration

    /// Persistence service
    private let persistence: PersistenceService

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.resource.cache",
        qos: .utility,
        attributes: .concurrent
    )

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    /// Memory cache
    private var memoryCache: [String: CacheEntry] = [:]

    /// Current cache size
    private var currentSize: Int64 = 0

    /// Cleanup timer
    private var cleanupTimer: Timer?

    // MARK: - Private Methods

    /// Set up cleanup timer
    private func setupCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(
            withTimeInterval: configuration.cleanupInterval,
            repeats: true
        ) { [weak self] _ in
            Task {
                try? await self?.cleanup()
            }
        }
    }

    /// Clean up cache
    private func cleanup() async throws {
        try await performanceMonitor.trackDuration("resource.cache.cleanup") {
            guard configuration.useMemoryCache else {
                return
            }

            // Sort entries by last access and count
            let sortedEntries = memoryCache.sorted { first, second in
                let firstScore = first.value.lastAccess.timeIntervalSinceNow +
                    Double(first.value.accessCount)
                let secondScore = second.value.lastAccess.timeIntervalSinceNow +
                    Double(second.value.accessCount)
                return firstScore < secondScore
            }

            // Remove oldest entries until within limits
            var removedCount = 0
            var removedSize: Int64 = 0

            queue.async(flags: .barrier) {
                while self.currentSize - removedSize > self.configuration.maxSize ||
                    self.memoryCache.count - removedCount > self.configuration.maxItems,
                    removedCount < sortedEntries.count {
                    let entry = sortedEntries[removedCount]
                    self.memoryCache.removeValue(forKey: entry.key)
                    removedSize += Int64(entry.value.data.count)
                    removedCount += 1
                }

                self.currentSize -= removedSize
            }

            // Log operation
            logger.debug(
                """
                Cleaned up cache:
                Removed: \(removedCount) items
                Size: \(removedSize) bytes
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Get cache key for identifier
    private func getCacheKey(
        for identifier: String
    ) -> String {
        "cache/resources/\(identifier)"
    }
}
