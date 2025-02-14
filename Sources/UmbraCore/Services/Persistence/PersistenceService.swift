import Foundation

/// Service for managing data persistence
public final class PersistenceService: BaseSandboxedService {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - configuration: Storage configuration
    ///   - security: Security service
    ///   - crypto: Crypto service
    ///   - performanceMonitor: Performance monitor
    ///   - logger: Logger for tracking operations
    public init(
        configuration: Configuration,
        security: SecurityService,
        crypto: SecurityCrypto,
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        self.configuration = configuration
        self.security = security
        self.crypto = crypto
        self.performanceMonitor = performanceMonitor
        super.init(logger: logger)
        setupDirectory()
    }

    // MARK: Public

    // MARK: - Types

    /// Storage location
    public enum StorageLocation {
        /// Application support directory
        case applicationSupport
        /// Documents directory
        case documents
        /// Cache directory
        case cache
        /// Temporary directory
        case temporary
        /// Custom directory
        case custom(URL)

        // MARK: Internal

        /// Get URL for location
        func getURL() throws -> URL {
            switch self {
            case .applicationSupport:
                try FileManager.default.url(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )

            case .documents:
                try FileManager.default.url(
                    for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )

            case .cache:
                try FileManager.default.url(
                    for: .cachesDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )

            case .temporary:
                FileManager.default.temporaryDirectory

            case let .custom(url):
                url
            }
        }
    }

    /// Storage configuration
    public struct Configuration {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            location: StorageLocation = .applicationSupport,
            directory: String,
            fileExtension: String = "data",
            useEncryption: Bool = false,
            useCompression: Bool = false
        ) {
            self.location = location
            self.directory = directory
            self.fileExtension = fileExtension
            self.useEncryption = useEncryption
            self.useCompression = useCompression
        }

        // MARK: Public

        /// Base location
        public let location: StorageLocation

        /// Directory name
        public let directory: String

        /// File extension
        public let fileExtension: String

        /// Whether to use encryption
        public let useEncryption: Bool

        /// Whether to use compression
        public let useCompression: Bool
    }

    // MARK: - Public Methods

    /// Save data
    /// - Parameters:
    ///   - data: Data to save
    ///   - key: Storage key
    /// - Throws: Error if save fails
    public func save(
        _ data: Data,
        forKey key: String
    ) async throws {
        try validateUsable(for: "save")

        return try await performanceMonitor.trackDuration("persistence.save") {
            // Get file URL
            let fileURL = try getFileURL(for: key)

            // Process data
            var processedData = data

            if configuration.useCompression {
                processedData = try compress(data)
            }

            if configuration.useEncryption {
                let key = crypto.generateKey(identifier: "persistence")
                let encrypted = try await crypto.encrypt(processedData, using: key)
                processedData = encrypted.ciphertext
            }

            // Create directory if needed
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            // Write data
            try processedData.write(
                to: fileURL,
                options: .atomic
            )

            // Log operation
            logger.debug(
                """
                Saved data:
                Key: \(key)
                Size: \(data.count) bytes
                Location: \(fileURL.path)
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Load data
    /// - Parameter key: Storage key
    /// - Returns: Loaded data
    /// - Throws: Error if load fails
    public func load(
        forKey key: String
    ) async throws -> Data {
        try validateUsable(for: "load")

        return try await performanceMonitor.trackDuration("persistence.load") {
            // Get file URL
            let fileURL = try getFileURL(for: key)

            // Read data
            let data = try Data(contentsOf: fileURL)

            // Process data
            var processedData = data

            if configuration.useEncryption {
                guard let key = crypto.getKey(identifier: "persistence") else {
                    throw PersistenceError.decryptionFailed("Key not found")
                }

                let encrypted = try EncryptedData(
                    ciphertext: data,
                    nonce: .init(),
                    tag: Data(),
                    keyIdentifier: "persistence"
                )

                processedData = try await crypto.decrypt(encrypted, using: key)
            }

            if configuration.useCompression {
                processedData = try decompress(processedData)
            }

            // Log operation
            logger.debug(
                """
                Loaded data:
                Key: \(key)
                Size: \(processedData.count) bytes
                Location: \(fileURL.path)
                """,
                file: #file,
                function: #function,
                line: #line
            )

            return processedData
        }
    }

    /// Remove data
    /// - Parameter key: Storage key
    /// - Throws: Error if removal fails
    public func remove(
        forKey key: String
    ) async throws {
        try validateUsable(for: "remove")

        try await performanceMonitor.trackDuration("persistence.remove") {
            // Get file URL
            let fileURL = try getFileURL(for: key)

            // Remove file
            try FileManager.default.removeItem(at: fileURL)

            // Log operation
            logger.debug(
                """
                Removed data:
                Key: \(key)
                Location: \(fileURL.path)
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Clear all data
    /// - Throws: Error if clear fails
    public func clearAll() async throws {
        try validateUsable(for: "clearAll")

        try await performanceMonitor.trackDuration("persistence.clear") {
            guard let baseURL else {
                throw PersistenceError.directoryNotFound
            }

            // Remove directory
            try FileManager.default.removeItem(at: baseURL)

            // Recreate directory
            try FileManager.default.createDirectory(
                at: baseURL,
                withIntermediateDirectories: true
            )

            // Log operation
            logger.debug(
                """
                Cleared all data:
                Location: \(baseURL.path)
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    // MARK: Private

    /// Storage configuration
    private let configuration: Configuration

    /// Security service
    private let security: SecurityService

    /// Crypto service
    private let crypto: SecurityCrypto

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.persistence",
        qos: .utility,
        attributes: .concurrent
    )

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    /// Base directory URL
    private var baseURL: URL?

    // MARK: - Private Methods

    /// Set up storage directory
    private func setupDirectory() {
        do {
            let url = try configuration.location.getURL()
                .appendingPathComponent(configuration.directory)

            try FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: true
            )

            baseURL = url

            logger.debug(
                """
                Set up persistence directory:
                Location: \(url.path)
                """,
                file: #file,
                function: #function,
                line: #line
            )
        } catch {
            logger.error(
                "Failed to set up persistence directory: \(error)",
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Get file URL for key
    private func getFileURL(for key: String) throws -> URL {
        guard let baseURL else {
            throw PersistenceError.directoryNotFound
        }

        return baseURL
            .appendingPathComponent(key)
            .appendingPathExtension(configuration.fileExtension)
    }

    /// Compress data
    private func compress(_ data: Data) throws -> Data {
        // TODO: Implement compression
        data
    }

    /// Decompress data
    private func decompress(_ data: Data) throws -> Data {
        // TODO: Implement decompression
        data
    }
}
