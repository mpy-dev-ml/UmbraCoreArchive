import Foundation

// MARK: - NetworkService+Operations

public extension NetworkService {
    // MARK: - Download Operations

    /// Download a file from a URL
    /// - Parameters:
    ///   - configuration: Request configuration
    ///   - destination: Local file URL for downloaded content
    /// - Returns: Response with download details
    func downloadFile(
        configuration: NetworkRequestConfiguration,
        destination: URL
    ) async throws -> Response {
        try validateUsable(for: "downloadFile")

        return try await performanceMonitor.trackDuration(
            "network.download"
        ) { [weak self] in
            guard let self else {
                throw NetworkError.serviceUnavailable
            }

            let request = try createRequest(from: configuration)
            let (data, response) = try await session.data(for: request)
            let metrics = try await getMetrics(for: response)

            try await writeDownloadedData(data, to: destination)

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

    // MARK: - Upload Operations

    /// Upload a file to a URL
    /// - Parameters:
    ///   - configuration: Request configuration
    ///   - source: Local file URL to upload
    /// - Returns: Response with upload details
    func uploadFile(
        configuration: NetworkRequestConfiguration,
        source: URL
    ) async throws -> Response {
        try validateUsable(for: "uploadFile")

        return try await performanceMonitor.trackDuration(
            "network.upload"
        ) { [weak self] in
            guard let self else {
                throw NetworkError.serviceUnavailable
            }

            let request = try createRequest(from: configuration)
            let data = try Data(contentsOf: source)
            let (responseData, response) = try await session.upload(
                for: request,
                from: data
            )
            let metrics = try await getMetrics(for: response)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            return try await processResponse(
                data: responseData,
                response: httpResponse,
                metrics: metrics
            )
        }
    }
}
