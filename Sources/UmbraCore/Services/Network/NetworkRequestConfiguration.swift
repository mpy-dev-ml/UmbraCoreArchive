import Foundation

/// Network request configuration
public struct NetworkRequestConfiguration {
    // MARK: Lifecycle

    /// Initialize with values
    public init(
        url: URL,
        method: String = "GET",
        headers: [String: String] = [:],
        body: Data? = nil,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        timeoutInterval: TimeInterval = 60.0
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.cachePolicy = cachePolicy
        self.timeoutInterval = timeoutInterval
    }

    // MARK: Public

    /// URL for the request
    public let url: URL

    /// HTTP method (GET, POST, etc.)
    public let method: String

    /// HTTP headers
    public let headers: [String: String]

    /// Request body data
    public let body: Data?

    /// Cache policy for the request
    public let cachePolicy: URLRequest.CachePolicy

    /// Timeout interval in seconds
    public let timeoutInterval: TimeInterval
}
