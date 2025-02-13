@preconcurrency import Foundation

extension NetworkService {
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
            // Create request and log
            let request = createUploadRequest(url: url)
            logUploadStart(url: url, fileURL: fileURL)

            // Upload file
            let (data, response, metrics) = try await session.upload(
                for: request,
                fromFile: fileURL,
                delegate: nil
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            // Process upload
            return try await processUpload(
                data: data,
                response: httpResponse,
                metrics: metrics
            )
        }
    }

    // MARK: - Private Methods

    /// Create request for file upload
    /// - Parameter url: Target URL
    /// - Returns: Configured URLRequest
    private func createUploadRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }

    /// Log the start of an upload
    /// - Parameters:
    ///   - url: Target URL
    ///   - fileURL: Source file URL
    private func logUploadStart(url: URL, fileURL: URL) {
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
    }

    /// Process uploaded data and create response
    /// - Parameters:
    ///   - data: Response data
    ///   - response: HTTP response
    ///   - metrics: Upload metrics
    /// - Returns: Upload response
    /// - Throws: Error if response validation fails
    private func processUpload(
        data: Data,
        response: HTTPURLResponse,
        metrics: URLSessionTaskMetrics
    ) async throws -> Response {
        // Create response
        let metadata = createResponseMetadata(
            response: response,
            dataSize: data.count
        )

        let networkResponse = Response(
            data: data,
            metadata: metadata,
            metrics: metrics
        )

        // Log completion and validate
        logUploadCompletion(response: networkResponse)
        try validateStatusCode(networkResponse.metadata.statusCode)

        return networkResponse
    }

    /// Log upload completion
    /// - Parameter response: Upload response
    private func logUploadCompletion(response: Response) {
        logger.debug(
            """
            Upload completed:
            Status: \(response.metadata.statusCode)
            Size: \(response.metadata.size) bytes
            Duration: \(response.metrics?.taskInterval.duration ?? 0)s
            """,
            file: #file,
            function: #function,
            line: #line
        )
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
