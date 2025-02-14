@preconcurrency import Foundation

// MARK: - NetworkService

/// Service for managing network operations
public final class NetworkService: BaseSandboxedService, NetworkServiceProtocol {
    // MARK: Lifecycle

    /// Initialize with dependencies
    /// - Parameters:
    ///   - configuration: URL session configuration
    ///   - performanceMonitor: Performance monitor
    ///   - logger: Logger for tracking operations
    public init(
        configuration: URLSessionConfiguration = .default,
        performanceMonitor: PerformanceMonitorProtocol,
        logger: LoggerProtocol
    ) {
        session = URLSession(configuration: configuration)
        self.performanceMonitor = performanceMonitor
        super.init(logger: logger)
    }

    // MARK: - Properties

    public let session: URLSession
    public let performanceMonitor: PerformanceMonitorProtocol
    private var activeTasks: [UUID: Task<Response, Error>] = [:]
    public let taskQueue = DispatchQueue(label: "dev.mpy.umbracore.network.tasks")

    // MARK: - Public Methods

    /// Performs a network request with cancellation support
    /// - Parameters:
    ///   - configuration: Request configuration
    ///   - taskId: Optional identifier for the task
    /// - Returns: Network response and task identifier
    /// - Throws: NetworkError if the request fails
    public func performRequest(
        _ configuration: NetworkRequestConfiguration,
        taskId: UUID = UUID()
    ) async throws -> (Response, UUID) {
        let task = Task { () -> Response in
            let request = try createRequest(from: configuration)

            do {
                let (data, response) = try await withTimeout(
                    configuration.timeoutInterval
                ) {
                    try await session.data(for: request)
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }

                let metrics = try await getMetrics(for: response)
                return try await processResponse(
                    data: data,
                    response: httpResponse,
                    metrics: metrics
                )
            } catch is TimeoutError {
                throw NetworkError.timeout
            } catch let error as NetworkError {
                throw error
            } catch {
                throw NetworkError.requestError(
                    error.localizedDescription
                )
            }
        }

        // Store task for cancellation support
        taskQueue.sync {
            activeTasks[taskId] = task
        }

        do {
            let response = try await task.value

            // Remove completed task
            taskQueue.sync {
                activeTasks.removeValue(forKey: taskId)
            }

            return (response, taskId)
        } catch {
            // Remove failed task
            taskQueue.sync {
                activeTasks.removeValue(forKey: taskId)
            }
            throw error
        }
    }

    /// Cancels a specific network request
    /// - Parameter taskId: The identifier of the task to cancel
    public func cancelRequest(taskId: UUID) {
        taskQueue.sync {
            activeTasks[taskId]?.cancel()
            activeTasks.removeValue(forKey: taskId)
        }
    }

    /// Cancels all active network requests
    public func cancelAllRequests() {
        taskQueue.sync {
            activeTasks.values.forEach { $0.cancel() }
            activeTasks.removeAll()
        }
    }

    /// Downloads data from a URL
    /// - Parameters:
    ///   - configuration: Request configuration
    ///   - destination: Local file URL to save the downloaded data
    /// - Throws: NetworkError if the download fails
    public func downloadData(
        _ configuration: NetworkRequestConfiguration,
        to destination: URL
    ) async throws {
        let (response, _) = try await performRequest(configuration)
        try await writeDownloadedData(response.data, to: destination)
    }

    // MARK: - Private Methods

    private func createRequest(
        from configuration: NetworkRequestConfiguration
    ) throws -> URLRequest {
        // Create request with basic configuration
        let request = URLRequest(
            url: configuration.url,
            cachePolicy: configuration.cachePolicy,
            timeoutInterval: configuration.timeoutInterval
        )

        // Configure request properties
        var mutableRequest = request
        mutableRequest.httpMethod = configuration.method
        mutableRequest.allHTTPHeaderFields = configuration.headers
        mutableRequest.httpBody = configuration.body

        return mutableRequest
    }

    private func getMetrics(for response: URLResponse) async throws -> URLSessionTaskMetrics {
        guard let metrics = response.metrics else {
            throw NetworkError.metricsUnavailable
        }
        return metrics
    }

    private func processResponse(
        data: Data,
        response: HTTPURLResponse,
        metrics: URLSessionTaskMetrics
    ) async throws -> Response {
        let statusCode = response.statusCode
        guard (200 ... 299).contains(statusCode) else {
            let error: NetworkError = .httpError(statusCode: statusCode)
            throw error
        }

        return Response(
            data: data,
            statusCode: statusCode,
            headers: response.allHeaderFields as? [String: String] ?? [:],
            metrics: metrics
        )
    }

    private func writeDownloadedData(_ data: Data, to destination: URL) async throws {
        try data.write(to: destination, options: .atomic)
    }

    private func withTimeout<T>(
        _ seconds: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // Start the actual operation
            group.addTask {
                try await operation()
            }

            // Start timeout task
            group.addTask {
                let nanoseconds = UInt64(seconds * 1_000_000_000)
                try await Task.sleep(nanoseconds: nanoseconds)
                throw TimeoutError()
            }

            // Get first result or timeout
            guard let result = try await group.next() else {
                throw TimeoutError()
            }

            // Cancel remaining task
            group.cancelAll()
            return result
        }
    }
}

// MARK: - NetworkService.Response

public extension NetworkService {
    /// Response from a network request
    struct Response {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            data: Data,
            statusCode: Int,
            headers: [String: String],
            metrics: URLSessionTaskMetrics
        ) {
            self.data = data
            self.statusCode = statusCode
            self.headers = headers
            self.metrics = metrics
        }

        // MARK: Public

        /// Response data
        public let data: Data

        /// HTTP status code
        public let statusCode: Int

        /// Response headers
        public let headers: [String: String]

        /// Performance metrics
        public let metrics: URLSessionTaskMetrics
    }
}

// MARK: - NetworkError

/// Errors that can occur during network operations
public enum NetworkError: LocalizedError {
    /// Invalid response from server
    case invalidResponse
    /// HTTP error with status code
    case httpError(statusCode: Int)
    /// Error during download operation
    case downloadError(String)
    /// Error during upload operation
    case uploadError(String)
    /// Performance metrics unavailable
    case metricsUnavailable
    /// General request error
    case requestError(String)
    /// Request timeout
    case timeout

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "The server returned an invalid response"

        case let .httpError(code):
            "The server returned an error (HTTP \(code))"

        case let .downloadError(reason):
            "Failed to download file: \(reason)"

        case let .uploadError(reason):
            "Failed to upload file: \(reason)"

        case .metricsUnavailable:
            "Unable to collect performance metrics"

        case let .requestError(reason):
            "Request failed: \(reason)"

        case .timeout:
            "The request timed out"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidResponse:
            "Please check your network connection and try again"

        case .httpError:
            "Please verify the request and try again. If the problem persists, contact support"

        case .downloadError:
            "Please check available disk space and file permissions, then try again"

        case .uploadError:
            "Please verify the file exists and you have permission to upload"

        case .metricsUnavailable:
            "Please check your network connection and try again"

        case .requestError:
            "Please verify the request parameters and try again"

        case .timeout:
            "Please check your network connection or try again later"
        }
    }
}

// MARK: - TimeoutError

private struct TimeoutError: Error {}
