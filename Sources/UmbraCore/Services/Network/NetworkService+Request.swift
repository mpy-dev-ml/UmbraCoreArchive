import Foundation

extension NetworkService {
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
            // Create and send request
            let request = createURLRequest(from: configuration)
            logRequest(configuration)

            // Process response
            let (data, response, metrics) = try await session.data(
                for: request,
                delegate: nil
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            return try await processResponse(
                data: data,
                response: httpResponse,
                metrics: metrics
            )
        }
    }

    // MARK: - Private Methods

    /// Create URLRequest from configuration
    /// - Parameter configuration: Request configuration
    /// - Returns: Configured URLRequest
    private func createURLRequest(from configuration: RequestConfiguration) -> URLRequest {
        var request = URLRequest(
            url: configuration.url,
            cachePolicy: configuration.cachePolicy,
            timeoutInterval: configuration.timeoutInterval
        )
        request.httpMethod = configuration.method
        request.httpBody = configuration.body
        configuration.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return request
    }

    /// Log request details
    /// - Parameter configuration: Request configuration
    private func logRequest(_ configuration: RequestConfiguration) {
        logger.debug(
            """
            Sending request:
            URL: \(configuration.url)
            Method: \(configuration.method)
            Headers: \(configuration.headers)
            """,
            file: #file,
            function: #function,
            line: #line
        )
    }

    /// Process response data and create response object
    /// - Parameters:
    ///   - data: Response data
    ///   - response: HTTP response
    ///   - metrics: Response metrics
    /// - Returns: Network response
    /// - Throws: Error if response validation fails
    private func processResponse(
        data: Data,
        response: HTTPURLResponse,
        metrics: URLSessionTaskMetrics
    ) async throws -> Response {
        let metadata = createResponseMetadata(
            response: response,
            dataSize: data.count
        )

        let networkResponse = Response(
            data: data,
            metadata: metadata,
            metrics: metrics
        )

        try validateStatusCode(networkResponse.metadata.statusCode)
        return networkResponse
    }

    /// Create response metadata from HTTP response
    /// - Parameters:
    ///   - response: HTTP response
    ///   - dataSize: Size of response data
    /// - Returns: Response metadata
    private func createResponseMetadata(
        response: HTTPURLResponse,
        dataSize: Int
    ) -> ResponseMetadata {
        ResponseMetadata(
            statusCode: response.statusCode,
            headers: response.allHeaderFields,
            size: Int64(dataSize),
            mimeType: response.mimeType,
            textEncoding: response.textEncodingName
        )
    }

    /// Validate HTTP status code
    /// - Parameter statusCode: HTTP status code
    /// - Throws: NetworkError if status code is invalid
    private func validateStatusCode(_ statusCode: Int) throws {
        guard (200 ... 299).contains(statusCode) else {
            throw NetworkError.invalidStatusCode(statusCode)
        }
    }
}
