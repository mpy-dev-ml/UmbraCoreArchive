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
        _ = try await validateUsable(for: "downloadFile")

        return try await performanceMonitor.trackDuration(
            "network.download"
        ) {
            // Create request and log
            let request = URLRequest(url: url)
            logDownloadStart(url: url, destination: destination)

            // Download file
            let (tempURL, response) = try await session.download(for: request)

            // Validate response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidHTTPResponse
            }

            // Check status code
            guard (200 ... 299).contains(httpResponse.statusCode) else {
                let error: NetworkError = NetworkService.NetworkError.httpError(
                    statusCode: httpResponse.statusCode)
                throw error
            }

            // Move file to destination
            try FileManager.default.moveItem(at: tempURL, to: destination)

            // Log success and return response
            logDownloadSuccess(url: url, destination: destination)
            return try Response(
                statusCode: httpResponse.statusCode,
                data: Data(contentsOf: destination),
                headers: httpResponse.allHeaderFields
            )
        }
    }

    // MARK: - Private

    private func logDownloadStart(url: URL, destination: URL) {
        logger.info(
            """
            Starting download:
            From: \(url)
            To: \(destination)
            """
        )
    }

    private func logDownloadSuccess(url: URL, destination: URL) {
        logger.info(
            """
            Download completed:
            From: \(url)
            To: \(destination)
            """
        )
    }
}
