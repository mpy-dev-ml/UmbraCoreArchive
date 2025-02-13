@preconcurrency import Foundation

// MARK: - SecurityScopedAccess

/// Manages security-scoped access to files and directories in a thread-safe manner.
/// This type provides secure access to files and directories outside the application's sandbox.
/// Access is automatically managed and cleaned up when the instance is deallocated.
public final class SecurityScopedAccess: Codable, CustomStringConvertible {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialise with URL and options
    /// - Parameters:
    ///   - url: URL to create bookmark for
    ///   - isDirectory: Whether URL is a directory
    /// - Throws: SecurityScopedAccessError if bookmark creation fails
    public init(url: URL, isDirectory: Bool = false) throws {
        self.url = url
        self.isDirectory = isDirectory
        isAccessing = false

        do {
            let options: URL.BookmarkCreationOptions = isDirectory
                ? [.withSecurityScope, .securityScopeAllowOnlyReadAccess]
                : [.withSecurityScope]

            bookmarkData = try url.bookmarkData(
                options: options,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            throw SecurityScopedAccessError.bookmarkCreationFailed(
                url: url,
                underlyingError: error
            )
        }
    }

    /// Initialise with bookmark data
    /// - Parameters:
    ///   - bookmarkData: Security-scoped bookmark data
    ///   - isDirectory: Whether bookmark is for directory
    /// - Throws: SecurityScopedAccessError if bookmark resolution fails
    public init(bookmarkData: Data, isDirectory: Bool = false) throws {
        self.bookmarkData = bookmarkData
        self.isDirectory = isDirectory
        isAccessing = false

        do {
            var isStale = false
            let resolvedURL = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                throw SecurityScopedAccessError.staleBookmark(
                    url: resolvedURL,
                    reason: "Bookmark data is stale and needs to be recreated"
                )
            }

            url = resolvedURL
        } catch let error as SecurityScopedAccessError {
            throw error
        } catch {
            throw SecurityScopedAccessError.bookmarkResolutionFailed(
                underlyingError: error
            )
        }
    }

    deinit {
        // Ensure we stop accessing when deallocated
        if isAccessing {
            stopAccessing()
        }
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        url = try container.decode(URL.self, forKey: .url)
        bookmarkData = try container.decode(Data.self, forKey: .bookmarkData)
        isDirectory = try container.decode(Bool.self, forKey: .isDirectory)
        isAccessing = false

        // Verify bookmark still resolves to same URL
        var isStale = false
        let resolvedURL = try URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        guard resolvedURL == url else {
            throw SecurityScopedAccessError.urlMismatch(
                expected: url,
                got: resolvedURL
            )
        }

        if isStale {
            throw SecurityScopedAccessError.staleBookmark(
                url: url,
                reason: "Bookmark data is stale and needs to be recreated"
            )
        }
    }

    // MARK: Public

    /// The URL being accessed
    public let url: URL

    /// Whether this bookmark is currently being accessed
    public private(set) var isAccessing: Bool

    // MARK: - Public Methods

    /// Start accessing security-scoped resource
    /// - Throws: SecurityScopedAccessError if access is denied
    public func startAccessing() throws {
        try Self.accessQueue.sync(flags: .barrier) { [self] in
            guard !isAccessing else {
                return
            }

            guard url.startAccessingSecurityScopedResource() else {
                throw SecurityScopedAccessError.accessDenied(
                    url: url,
                    reason: "Failed to start accessing security-scoped resource"
                )
            }

            isAccessing = true
        }
    }

    /// Stop accessing security-scoped resource
    public func stopAccessing() {
        Self.accessQueue.sync(flags: .barrier) { [self] in
            guard isAccessing else {
                return
            }

            url.stopAccessingSecurityScopedResource()
            isAccessing = false
        }
    }

    /// Perform an operation with security-scoped access
    /// - Parameter operation: The operation to perform
    /// - Throws: Any error thrown by the operation
    public func withAccess<T>(_ operation: () throws -> T) throws -> T {
        try startAccessing()
        defer { stopAccessing() }
        return try operation()
    }

    /// Perform an async operation with security-scoped access
    /// - Parameter operation: The async operation to perform
    /// - Throws: Any error thrown by the operation
    public func withAccess<T>(_ operation: () async throws -> T) async throws -> T {
        try startAccessing()
        defer { stopAccessing() }
        return try await operation()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        try container.encode(bookmarkData, forKey: .bookmarkData)
        try container.encode(isDirectory, forKey: .isDirectory)
    }

    // MARK: Private

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case url
        case bookmarkData
        case isDirectory
    }

    /// Queue for synchronising access operations
    private static let accessQueue: DispatchQueue = .init(
        label: "dev.mpy.rBUM.SecurityScopedAccess",
        qos: .userInitiated,
        attributes: .concurrent
    )

    /// The security-scoped bookmark data
    private let bookmarkData: Data

    /// Whether this bookmark was created for a directory
    private let isDirectory: Bool
}

// MARK: Equatable

extension SecurityScopedAccess: Equatable {
    public static func == (lhs: SecurityScopedAccess, rhs: SecurityScopedAccess) -> Bool {
        lhs.url == rhs.url &&
            lhs.bookmarkData == rhs.bookmarkData &&
            lhs.isDirectory == rhs.isDirectory
    }
}

// MARK: - CustomStringConvertible

public extension SecurityScopedAccess {
    var description: String {
        """
        SecurityScopedAccess(
            url: \(url.path),
            isDirectory: \(isDirectory),
            isAccessing: \(isAccessing)
        )
        """
    }
}

// MARK: - SecurityScopedAccessError

/// Errors that can occur during security-scoped access operations
public enum SecurityScopedAccessError: LocalizedError {
    /// Failed to create bookmark
    case bookmarkCreationFailed(url: URL, underlyingError: Error)

    /// Failed to resolve bookmark
    case bookmarkResolutionFailed(underlyingError: Error)

    /// Access was denied to URL
    case accessDenied(url: URL, reason: String)

    /// URL mismatch during resolution
    case urlMismatch(expected: URL, got: URL)

    /// Bookmark is stale
    case staleBookmark(url: URL, reason: String)

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case let .bookmarkCreationFailed(url, error):
            """
            Failed to create security-scoped bookmark for \(url.path): \
            \(error.localizedDescription)
            """

        case let .bookmarkResolutionFailed(error):
            """
            Failed to resolve security-scoped bookmark: \
            \(error.localizedDescription)
            """

        case let .accessDenied(url, reason):
            """
            Access denied to security-scoped resource at \(url.path): \
            \(reason)
            """

        case let .urlMismatch(expected, got):
            """
            URL mismatch during bookmark resolution.
            Expected: \(expected.path)
            Got: \(got.path)
            """

        case let .staleBookmark(url, reason):
            """
            Security-scoped bookmark is stale for \(url.path): \
            \(reason)
            """
        }
    }

    public var failureReason: String? {
        switch self {
        case .bookmarkCreationFailed:
            "Failed to create security-scoped bookmark data"

        case .bookmarkResolutionFailed:
            "Failed to resolve security-scoped bookmark data"

        case .accessDenied:
            "Access to security-scoped resource was denied"

        case .urlMismatch:
            "Bookmark resolved to unexpected URL"

        case .staleBookmark:
            "Security-scoped bookmark data is no longer valid"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .bookmarkCreationFailed:
            """
            - Check file permissions
            - Verify the file exists
            - Request access to the file again
            """

        case .bookmarkResolutionFailed:
            """
            - Check if the file still exists
            - Verify file permissions
            - Create a new bookmark
            """

        case .accessDenied:
            """
            - Request access to the file again
            - Check application sandbox settings
            - Verify file permissions
            """

        case .urlMismatch:
            """
            - Create a new bookmark
            - Check if file was moved
            - Verify file still exists
            """

        case .staleBookmark:
            """
            - Create a new bookmark
            - Request access to the file again
            - Check if file was moved or modified
            """
        }
    }
}
