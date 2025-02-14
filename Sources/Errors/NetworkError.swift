@preconcurrency import Foundation

/// Errors that can occur during network operations
public enum NetworkError: LocalizedError {
    /// Invalid HTTP response received
    case invalidHTTPResponse

    /// HTTP error with specific status code
    case httpError(statusCode: Int)

    /// File operation failed with underlying error
    case fileOperationFailed(Error)

    /// Network operation failed with underlying error
    case networkOperationFailed(Error)

    /// Localized description of the error
    public var errorDescription: String? {
        switch self {
        case .invalidHTTPResponse:
            "Invalid HTTP response received"

        case let .httpError(statusCode):
            "HTTP error with status code: \(statusCode)"

        case let .fileOperationFailed(error):
            "File operation failed: \(error.localizedDescription)"

        case let .networkOperationFailed(error):
            "Network operation failed: \(error.localizedDescription)"
        }
    }

    /// Failure reason of the error
    public var failureReason: String? {
        switch self {
        case .invalidHTTPResponse:
            "The server response was not a valid HTTP response"

        case let .httpError(statusCode):
            "The server returned an error status code: \(statusCode)"

        case .fileOperationFailed:
            "A file system operation failed"

        case .networkOperationFailed:
            "A network operation failed"
        }
    }

    /// Recovery suggestion for the error
    public var recoverySuggestion: String? {
        switch self {
        case .invalidHTTPResponse:
            "Please try the request again. If the problem persists, contact support."

        case let .httpError(statusCode):
            switch statusCode {
            case 401:
                "Please check your authentication credentials and try again."

            case 403:
                "You do not have permission to access this resource."

            case 404:
                "The requested resource could not be found. Please verify the URL."

            case 500 ... 599:
                "The server encountered an error. Please try again later."

            default:
                "Please check the error details and try again."
            }

        case .fileOperationFailed:
            "Please check file permissions and available disk space."

        case .networkOperationFailed:
            "Please check your network connection and try again."
        }
    }
}
