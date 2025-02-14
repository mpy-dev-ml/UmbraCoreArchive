@preconcurrency import Foundation

/// Service for managing application resources
public final class ResourceService: BaseSandboxedService {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - persistence: Persistence service
    ///   - security: Security service
    ///   - performanceMonitor: Performance monitor
    ///   - logger: Logger for tracking operations
    public init(
        persistence: PersistenceService,
        security: SecurityService,
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        self.persistence = persistence
        self.security = security
        self.performanceMonitor = performanceMonitor
        super.init(logger: logger)
        loadResourceCache()
    }

    // MARK: Public

    // MARK: - Types

    /// Resource type
    public enum ResourceType {
        /// Image resource
        case image
        /// Audio resource
        case audio
        /// Video resource
        case video
        /// Document resource
        case document
        /// Data resource
        case data
        /// Custom resource
        case custom(String)

        // MARK: Internal

        /// Get file extension for type
        var fileExtension: String {
            switch self {
            case .image:
                "image"

            case .audio:
                "audio"

            case .video:
                "video"

            case .document:
                "document"

            case .data:
                "data"

            case let .custom(ext):
                ext
            }
        }
    }

    /// Resource metadata
    public struct ResourceMetadata: Codable {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            identifier: String,
            type: String,
            creationDate: Date = Date(),
            modificationDate: Date = Date(),
            size: Int64,
            contentType: String,
            attributes: [String: String] = [:]
        ) {
            self.identifier = identifier
            self.type = type
            self.creationDate = creationDate
            self.modificationDate = modificationDate
            self.size = size
            self.contentType = contentType
            self.attributes = attributes
        }

        // MARK: Public

        /// Resource identifier
        public let identifier: String

        /// Resource type
        public let type: String

        /// Creation date
        public let creationDate: Date

        /// Last modified date
        public let modificationDate: Date

        /// Resource size in bytes
        public let size: Int64

        /// Content type
        public let contentType: String

        /// Additional attributes
        public let attributes: [String: String]
    }

    // MARK: - Public Methods

    /// Store resource
    /// - Parameters:
    ///   - data: Resource data
    ///   - type: Resource type
    ///   - identifier: Optional resource identifier
    ///   - contentType: Content type
    ///   - attributes: Additional attributes
    /// - Returns: Resource metadata
    /// - Throws: Error if store fails
    public func storeResource(
        _ data: Data,
        type: ResourceType,
        identifier: String? = nil,
        contentType: String,
        attributes: [String: String] = [:]
    ) async throws -> ResourceMetadata {
        try validateUsable(for: "storeResource")

        return try await performanceMonitor.trackDuration("resource.store") {
            // Generate identifier if needed
            let resourceID = identifier ?? UUID().uuidString

            // Create metadata
            let metadata = ResourceMetadata(
                identifier: resourceID,
                type: type.fileExtension,
                size: Int64(data.count),
                contentType: contentType,
                attributes: attributes
            )

            // Store data
            try await persistence.save(
                data,
                forKey: getStorageKey(for: resourceID, type: type)
            )

            // Update cache
            queue.async(flags: .barrier) {
                self.resourceCache[resourceID] = metadata
            }

            // Log operation
            logger.debug(
                """
                Stored resource:
                ID: \(resourceID)
                Type: \(type)
                Size: \(data.count) bytes
                """,
                file: #file,
                function: #function,
                line: #line
            )

            return metadata
        }
    }

    /// Load resource
    /// - Parameter identifier: Resource identifier
    /// - Returns: Resource data and metadata
    /// - Throws: Error if load fails
    public func loadResource(
        _ identifier: String
    ) async throws -> (Data, ResourceMetadata) {
        try validateUsable(for: "loadResource")

        return try await performanceMonitor.trackDuration("resource.load") {
            // Get metadata
            guard let metadata = resourceCache[identifier] else {
                throw ResourceError.resourceNotFound(identifier)
            }

            // Load data
            let data = try await persistence.load(
                forKey: getStorageKey(
                    for: identifier,
                    type: ResourceType.custom(metadata.type)
                )
            )

            // Log operation
            logger.debug(
                """
                Loaded resource:
                ID: \(identifier)
                Type: \(metadata.type)
                Size: \(data.count) bytes
                """,
                file: #file,
                function: #function,
                line: #line
            )

            return (data, metadata)
        }
    }

    /// Remove resource
    /// - Parameter identifier: Resource identifier
    /// - Throws: Error if removal fails
    public func removeResource(
        _ identifier: String
    ) async throws {
        try validateUsable(for: "removeResource")

        try await performanceMonitor.trackDuration("resource.remove") {
            // Get metadata
            guard let metadata = resourceCache[identifier] else {
                throw ResourceError.resourceNotFound(identifier)
            }

            // Remove data
            try await persistence.remove(
                forKey: getStorageKey(
                    for: identifier,
                    type: ResourceType.custom(metadata.type)
                )
            )

            // Update cache
            queue.async(flags: .barrier) {
                self.resourceCache.removeValue(forKey: identifier)
            }

            // Log operation
            logger.debug(
                """
                Removed resource:
                ID: \(identifier)
                Type: \(metadata.type)
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Get resource metadata
    /// - Parameter identifier: Resource identifier
    /// - Returns: Resource metadata
    /// - Throws: Error if metadata not found
    public func getResourceMetadata(
        _ identifier: String
    ) throws -> ResourceMetadata {
        guard let metadata = resourceCache[identifier] else {
            throw ResourceError.resourceNotFound(identifier)
        }
        return metadata
    }

    /// List resources by type
    /// - Parameter type: Resource type
    /// - Returns: Array of resource metadata
    public func listResources(
        ofType type: ResourceType
    ) -> [ResourceMetadata] {
        queue.sync {
            resourceCache.values.filter { $0.type == type.fileExtension }
        }
    }

    // MARK: Private

    /// Persistence service
    private let persistence: PersistenceService

    /// Security service
    private let security: SecurityService

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.resource",
        qos: .userInitiated,
        attributes: .concurrent
    )

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    /// Resource cache
    private var resourceCache: [String: ResourceMetadata] = [:]

    // MARK: - Private Methods

    /// Load resource cache
    private func loadResourceCache() {
        // TODO: Implement persistent cache loading
    }

    /// Get storage key for resource
    private func getStorageKey(
        for identifier: String,
        type: ResourceType
    ) -> String {
        "resources/\(type.fileExtension)/\(identifier)"
    }
}
