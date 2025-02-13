@preconcurrency import Foundation
import os.log

/// Service responsible for discovering and managing Restic repositories
public final class RepositoryDiscoveryService: RepositoryDiscoveryProtocol {
    // MARK: Lifecycle

    // MARK: - Initialisation

    /// Creates a new repository discovery service
    /// - Parameters:
    ///   - xpcConnection: The XPC connection to use
    ///   - securityService: Service for handling security operations
    ///   - bookmarkStorage: Storage for security-scoped bookmarks
    ///   - logger: Logger instance
    public init(
        xpcConnection: NSXPCConnection,
        securityService: SecurityServiceProtocol,
        bookmarkStorage: BookmarkStorageProtocol,
        logger: Logger = Logger(subsystem: "dev.mpy.rBUM", category: "RepositoryDiscovery")
    ) {
        self.xpcConnection = xpcConnection
        self.securityService = securityService
        self.bookmarkStorage = bookmarkStorage
        self.logger = logger

        setupXPCConnection()
    }

    // MARK: Public

    // MARK: - RepositoryDiscoveryProtocol

    public func scanLocation(_ url: URL, recursive: Bool) async throws -> [DiscoveredRepository] {
        logger.info("Starting repository scan at \(url.path)")

        guard let bookmark = try? await requestAccessAndCreateBookmark(for: url) else {
            throw RepositoryDiscoveryError.accessDenied(url)
        }

        return try await performScan(at: url, recursive: recursive)
    }

    /// Perform repository scan at location
    /// - Parameters:
    ///   - url: Location to scan
    ///   - recursive: Whether to scan recursively
    /// - Returns: Array of discovered repositories
    private func performScan(
        at url: URL,
        recursive: Bool
    ) async throws -> [DiscoveredRepository] {
        try await withCheckedThrowingContinuation { continuation in
            executeScan(url: url, recursive: recursive) { result in
                handleScanResult(result, continuation: continuation)
            }
        }
    }

    /// Execute repository scan
    /// - Parameters:
    ///   - url: Location to scan
    ///   - recursive: Whether to scan recursively
    ///   - completion: Completion handler with scan result
    private func executeScan(
        url: URL,
        recursive: Bool,
        completion: @escaping (Result<[URL]?, Error>) -> Void
    ) {
        proxy?.scanLocation(url, recursive: recursive) { urls, error in
            if let error {
                completion(.failure(error))
                return
            }
            completion(.success(urls))
        }
    }

    /// Handle scan result
    /// - Parameters:
    ///   - result: Scan result
    ///   - continuation: Async continuation
    private func handleScanResult(
        _ result: Result<[URL]?, Error>,
        continuation: CheckedContinuation<[DiscoveredRepository], Error>
    ) {
        Task {
            do {
                switch result {
                case let .success(urls):
                    guard let urls else {
                        continuation.resume(returning: [])
                        return
                    }
                    let repositories = try await processDiscoveredURLs(urls)
                    continuation.resume(returning: repositories)

                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    public func verifyRepository(_ repository: DiscoveredRepository) async throws -> Bool {
        logger.info("Verifying repository at \(repository.url.path)")

        try await withCheckedThrowingContinuation { continuation in
            executeVerification(for: repository) { result in
                handleVerificationResult(result, continuation: continuation)
            }
        }
    }

    /// Execute repository verification
    /// - Parameters:
    ///   - repository: Repository to verify
    ///   - completion: Completion handler with verification result
    private func executeVerification(
        for repository: DiscoveredRepository,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        proxy?.verifyRepository(at: repository.url) { isValid, error in
            if let error {
                completion(.failure(error))
                return
            }
            completion(.success(isValid))
        }
    }

    /// Handle verification result
    /// - Parameters:
    ///   - result: Verification result
    ///   - continuation: Async continuation
    private func handleVerificationResult(
        _ result: Result<Bool, Error>,
        continuation: CheckedContinuation<Bool, Error>
    ) {
        switch result {
        case let .success(isValid):
            continuation.resume(returning: isValid)
        case let .failure(error):
            continuation.resume(throwing: error)
        }
    }

    public func indexRepository(_ repository: DiscoveredRepository) async throws {
        logger.info("Indexing repository at \(repository.url.path)")

        try await withCheckedThrowingContinuation { continuation in
            executeIndexing(for: repository) { result in
                handleIndexingResult(result, continuation: continuation)
            }
        }
    }

    /// Execute repository indexing
    /// - Parameters:
    ///   - repository: Repository to index
    ///   - completion: Completion handler with indexing result
    private func executeIndexing(
        for repository: DiscoveredRepository,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        proxy?.indexRepository(at: repository.url) { error in
            if let error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }

    /// Handle indexing result
    /// - Parameters:
    ///   - result: Indexing result
    ///   - continuation: Async continuation
    private func handleIndexingResult(
        _ result: Result<Void, Error>,
        continuation: CheckedContinuation<Void, Error>
    ) {
        switch result {
        case .success:
            continuation.resume()
        case let .failure(error):
            continuation.resume(throwing: error)
        }
    }

    public func cancelDiscovery() {
        logger.info("Cancelling discovery operations")
        proxy?.cancelOperations()
    }

    // MARK: Private

    private let xpcConnection: NSXPCConnection
    private let logger: Logger
    private let securityService: SecurityServiceProtocol
    private let bookmarkStorage: BookmarkStorageProtocol

    private var proxy: RepositoryDiscoveryXPCProtocol? {
        xpcConnection.remoteObjectProxyWithErrorHandler { [weak self] error in
            self?.logger.error("XPC connection failed: \(error.localizedDescription)")
        } as? RepositoryDiscoveryXPCProtocol
    }

    // MARK: - Private Methods

    private func setupXPCConnection() {
        xpcConnection
            .remoteObjectInterface = NSXPCInterface(with: RepositoryDiscoveryXPCProtocol.self)
        xpcConnection.resume()
    }

    private func requestAccessAndCreateBookmark(for url: URL) async throws -> Data {
        // First check if we already have a bookmark
        if let existingBookmark = try? await bookmarkStorage.getBookmark(for: url) {
            return existingBookmark
        }

        // Request access and create new bookmark
        guard url.startAccessingSecurityScopedResource() else {
            throw RepositoryDiscoveryError.accessDenied(url)
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let bookmark = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        try await bookmarkStorage.storeBookmark(bookmark, for: url)
        return bookmark
    }

    /// Process discovered URLs into repositories
    /// - Parameter urls: Array of discovered URLs
    /// - Returns: Array of valid repositories
    private func processDiscoveredURLs(_ urls: [URL]) async throws -> [DiscoveredRepository] {
        let validRepositories = await validateAndCreateRepositories(from: urls)
        return validRepositories.compactMap { $0 }
    }

    /// Validate and create repositories from URLs
    /// - Parameter urls: Array of URLs to process
    /// - Returns: Array of optional repositories
    private func validateAndCreateRepositories(
        from urls: [URL]
    ) async -> [DiscoveredRepository?] {
        await withTaskGroup(of: DiscoveredRepository?.self) { group in
            for url in urls {
                group.addTask {
                    try? await self.createRepository(from: url)
                }
            }

            var repositories: [DiscoveredRepository?] = []
            for await repository in group {
                repositories.append(repository)
            }
            return repositories
        }
    }

    /// Create repository from URL
    /// - Parameter url: URL to create repository from
    /// - Returns: Created repository if valid
    private func createRepository(from url: URL) async throws -> DiscoveredRepository {
        guard let metadata = try? await getRepositoryMetadata(for: url) else {
            throw RepositoryDiscoveryError.invalidRepository(url)
        }

        return DiscoveredRepository(
            url: url,
            type: .local,
            discoveredAt: Date(),
            isVerified: false,
            metadata: metadata
        )
    }

    private func getRepositoryMetadata(for url: URL) async throws -> RepositoryMetadata {
        try await withCheckedThrowingContinuation { continuation in
            proxy?.getRepositoryMetadata(at: url) { metadata, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let metadata else {
                    continuation.resume(throwing: RepositoryDiscoveryError.invalidRepository(url))
                    return
                }

                let repositoryMetadata = createRepositoryMetadata(from: metadata)
                continuation.resume(returning: repositoryMetadata)
            }
        }
    }

    /// Create repository metadata from dictionary
    /// - Parameter metadata: Dictionary containing metadata values
    /// - Returns: Structured repository metadata
    private func createRepositoryMetadata(from metadata: [String: Any]) -> RepositoryMetadata {
        RepositoryMetadata(
            size: metadata["size"] as? UInt64,
            lastModified: metadata["lastModified"] as? Date,
            snapshotCount: metadata["snapshotCount"] as? Int
        )
    }
}
