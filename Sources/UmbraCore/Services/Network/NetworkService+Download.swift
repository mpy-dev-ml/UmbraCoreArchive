@preconcurrency import Foundation

extension NetworkService {
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
            // Create request and log
            let request = URLRequest(url: url)
            logDownloadStart(url: url, destination: destination)

            // Download file
            let (tempURL, response, metrics) = try await session.download(
                for: request,
                delegate: nil
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            // Process download
            return try await processDownload(
                tempURL: tempURL,
                destination: destination,
                response: httpResponse,
                metrics: metrics
            )
        }
    }

    // MARK: - Private Methods

    /// Log the start of a download
    /// - Parameters:
    ///   - url: Source URL
    ///   - destination: Destination URL
    private func logDownloadStart(url: URL, destination: URL) {
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
    }

    /// Process downloaded file and create response
    /// - Parameters:
    ///   - tempURL: Temporary file URL
    ///   - destination: Final destination URL
    ///   - response: HTTP response
    ///   - metrics: Download metrics
    /// - Returns: Download response
    /// - Throws: Error if file processing fails
    private func processDownload(
        tempURL: URL,
        destination: URL,
        response: HTTPURLResponse,
        metrics: URLSessionTaskMetrics
    ) async throws -> Response {
        // Move file to destination
        try moveDownloadedFile(from: tempURL, to: destination)

        // Get file metadata
        let fileSize = try getFileSize(at: destination)

        // Create response
        let metadata = ResponseMetadata(
            statusCode: response.statusCode,
            headers: response.allHeaderFields,
            size: fileSize,
            mimeType: response.mimeType,
            textEncoding: response.textEncodingName
        )

        let networkResponse = Response(
            data: Data(),
            metadata: metadata,
            metrics: metrics
        )

        // Log completion and validate
        logDownloadCompletion(response: networkResponse)
        try validateStatusCode(networkResponse.metadata.statusCode)

        return networkResponse
    }

    /// Move downloaded file from temporary to final location
    /// - Parameters:
    ///   - source: Source URL
    ///   - destination: Destination URL
    /// - Throws: Error if move fails
    private func moveDownloadedFile(
        from source: URL,
        to destination: URL
    ) throws {
        do {
            try FileManager.default.moveItem(
                at: source,
                to: destination
            )
        } catch {
            throw NetworkError.fileOperationFailed(error)
        }
    }

    /// Get size of file at specified URL
    /// - Parameter url: File URL
    /// - Returns: File size in bytes
    /// - Throws: Error if file attributes cannot be read
    private func getFileSize(at url: URL) throws -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(
                atPath: url.path
            )
            return attributes[.size] as? Int64 ?? 0
        } catch {
            throw NetworkError.fileOperationFailed(error)
        }
    }

    /// Log download completion
    /// - Parameter response: Download response
    private func logDownloadCompletion(response: Response) {
        logger.debug(
            """
            Download completed:
            Status: \(response.metadata.statusCode)
            Size: \(response.metadata.size) bytes
            Duration: \(response.metrics?.taskInterval.duration ?? 0)s
            """,
            file: #file,
            function: #function,
            line: #line
        )
    }
}
