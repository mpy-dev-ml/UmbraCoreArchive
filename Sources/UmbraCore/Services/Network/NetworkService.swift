import Foundation

// MARK: - NetworkService

/// Service for managing network operations
public final class NetworkService: BaseSandboxedService {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - configuration: URL session configuration
    ///   - performanceMonitor: Performance monitor
    ///   - logger: Logger for tracking operations
    public init(
        configuration: URLSessionConfiguration = .default,
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        session = URLSession(configuration: configuration)
        self.performanceMonitor = performanceMonitor
        super.init(logger: logger)
    }

    // MARK: Public

    // MARK: - Types

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

    // MARK: - Public Methods

    /// Send network request
    /// - Parameter configuration: Request configuration
    /// - Returns: Network response
    /// - Throws: Error if request fails
    public func sendRequest(
        _ configuration: RequestConfiguration
    ) async throws -> Response {
        try validateUsable(for: "sendRequest")

        return try await performanceMonitor.trackDuration(
            "network.request"
        ) {
            // Create request
            var request = URLRequest(
                url: configuration.url,
                cachePolicy: configuration.cachePolicy,
                timeoutInterval: configuration.timeoutInterval
            )
            request.httpMethod = configuration.method
            request.httpBody = configuration.body

            // Add headers
            for (key, value) in configuration.headers {
                request.setValue(value, forHTTPHeaderField: key)
            }

            // Log request
            logger.debug(
                """
                Sending request:
                URL: \(configuration.url)
                Method: \(configuration.method)
                Headers: \(configuration.headers)
                Body Size: \(configuration.body?.count ?? 0) bytes
                """,
                file: #file,
                function: #function,
                line: #line
            )

            // Send request
            let (data, response, metrics) = try await session.data(
                for: request,
                delegate: nil
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            // Create metadata
            let metadata = ResponseMetadata(
                statusCode: httpResponse.statusCode,
                headers: httpResponse.allHeaderFields,
                size: Int64(data.count),
                mimeType: httpResponse.mimeType,
                textEncoding: httpResponse.textEncodingName
            )

            // Create response
            let networkResponse = Response(
                data: data,
                metadata: metadata,
                metrics: metrics
            )

            // Log response
            logger.debug(
                """
                Received response:
                Status: \(metadata.statusCode)
                Size: \(metadata.size) bytes
                Type: \(metadata.mimeType ?? "unknown")
                Duration: \(metrics?.taskInterval.duration ?? 0)s
                """,
                file: #file,
                function: #function,
                line: #line
            )

            // Validate status code
            guard (200 ... 299).contains(metadata.statusCode) else {
                throw NetworkError.httpError(metadata.statusCode)
            }

            return networkResponse
        }
    }

    /// Download file
    /// - Parameters:
    ///   - url: File URL
    ///   - destination: Destination URL
    /// - Returns: Download response
    /// - Throws: Error if download fails
    public func downloadFile(
        from url: URL,
        to destination: URL
    ) async throws -> Response {
        try validateUsable(for: "downloadFile")

        return try await performanceMonitor.trackDuration(
            "network.download"
        ) {
            // Create request
            let request = URLRequest(url: url)

            // Log download start
            logger.debug(
                """
                Starting download:
                URL: \(url)
                Destination: \(destination)
                """,
                file: #file,
                function: #function,
                line: #line
            )

            // Download file
            let (tempURL, response, metrics) = try await session.download(
                for: request,
                delegate: nil
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            // Move file to destination
            try FileManager.default.moveItem(
                at: tempURL,
                to: destination
            )

            // Get file size
            let attributes = try FileManager.default.attributesOfItem(
                atPath: destination.path
            )
            let fileSize = attributes[.size] as? Int64 ?? 0

            // Create metadata
            let metadata = ResponseMetadata(
                statusCode: httpResponse.statusCode,
                headers: httpResponse.allHeaderFields,
                size: fileSize,
                mimeType: httpResponse.mimeType,
                textEncoding: httpResponse.textEncodingName
            )

            // Create response
            let networkResponse = Response(
                data: Data(),
                metadata: metadata,
                metrics: metrics
            )

            // Log download completion
            logger.debug(
                """
                Download completed:
                Status: \(metadata.statusCode)
                Size: \(metadata.size) bytes
                Duration: \(metrics?.taskInterval.duration ?? 0)s
                """,
                file: #file,
                function: #function,
                line: #line
            )

            // Validate status code
            guard (200 ... 299).contains(metadata.statusCode) else {
                throw NetworkError.httpError(metadata.statusCode)
            }

            return networkResponse
        }
    }

    /// Upload file
    /// - Parameters:
    ///   - url: File URL
    ///   - fileURL: URL of file to upload
    /// - Returns: Upload response
    /// - Throws: Error if upload fails
    public func uploadFile(
        to url: URL,
        from fileURL: URL
    ) async throws -> Response {
        try validateUsable(for: "uploadFile")

        return try await performanceMonitor.trackDuration(
            "network.upload"
        ) {
            // Create request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            // Log upload start
            logger.debug(
                """
                Starting upload:
                URL: \(url)
                File: \(fileURL)
                """,
                file: #file,
                function: #function,
                line: #line
            )

            // Upload file
            let (data, response, metrics) = try await session.upload(
                for: request,
                fromFile: fileURL,
                delegate: nil
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            // Create metadata
            let metadata = ResponseMetadata(
                statusCode: httpResponse.statusCode,
                headers: httpResponse.allHeaderFields,
                size: Int64(data.count),
                mimeType: httpResponse.mimeType,
                textEncoding: httpResponse.textEncodingName
            )

            // Create response
            let networkResponse = Response(
                data: data,
                metadata: metadata,
                metrics: metrics
            )

            // Log upload completion
            logger.debug(
                """
                Upload completed:
                Status: \(metadata.statusCode)
                Size: \(metadata.size) bytes
                Duration: \(metrics?.taskInterval.duration ?? 0)s
                """,
                file: #file,
                function: #function,
                line: #line
            )

            // Validate status code
            guard (200 ... 299).contains(metadata.statusCode) else {
                throw NetworkError.httpError(metadata.statusCode)
            }

            return networkResponse
        }
    }

    // MARK: Private

    /// URL session
    private let session: URLSession

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.network",
        qos: .userInitiated,
        attributes: .concurrent
    )
}

// MARK: - NetworkError

/// Errors that can occur during network operations
public enum NetworkError: LocalizedError {
    /// Invalid response
    case invalidResponse
    /// HTTP error
    case httpError(Int)
    /// Download error
    case downloadError(String)
    /// Upload error
    case uploadError(String)

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Invalid network response"
        case let .httpError(code):
            "HTTP error: \(code)"
        case let .downloadError(reason):
            "Download error: \(reason)"
        case let .uploadError(reason):
            "Upload error: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidResponse:
            "Check network connection"
        case .httpError:
            "Check server status"
        case .downloadError:
            "Check file permissions and disk space"
        case .uploadError:
            "Check file permissions and server status"
        }
    }
}
