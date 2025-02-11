import Foundation

/// Network request configuration
public struct RequestConfiguration {
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

    /// Request URL
    public let url: URL

    /// HTTP method
    public let method: String

    /// Request headers
    public let headers: [String: String]

    /// Request body
    public let body: Data?

    /// Cache policy
    public let cachePolicy: URLRequest.CachePolicy

    /// Timeout interval
    public let timeoutInterval: TimeInterval
}

/// Network response
public struct Response {
    // MARK: Lifecycle

    /// Initialize with values
    public init(
        data: Data,
        metadata: ResponseMetadata,
        metrics: URLSessionTaskMetrics?
    ) {
        self.data = data
        self.metadata = metadata
        self.metrics = metrics
    }

    // MARK: Public

    /// Response data
    public let data: Data

    /// Response metadata
    public let metadata: ResponseMetadata

    /// Response metrics
    public let metrics: URLSessionTaskMetrics?
}

/// Response metadata
public struct ResponseMetadata {
    // MARK: Lifecycle

    /// Initialize with values
    public init(
        statusCode: Int,
        headers: [AnyHashable: Any],
        size: Int64,
        mimeType: String?,
        textEncoding: String?
    ) {
        self.statusCode = statusCode
        self.headers = headers
        self.size = size
        self.mimeType = mimeType
        self.textEncoding = textEncoding
    }

    // MARK: Public

    /// HTTP status code
    public let statusCode: Int

    /// Response headers
    public let headers: [AnyHashable: Any]

    /// Response size in bytes
    public let size: Int64

    /// Response MIME type
    public let mimeType: String?

    /// Response text encoding
    public let textEncoding: String?
}
