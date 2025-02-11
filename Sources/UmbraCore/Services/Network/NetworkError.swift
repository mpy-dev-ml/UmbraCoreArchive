import Foundation

/// Errors that can occur during network operations
public enum NetworkError: Error {
    /// Invalid HTTP response
    case invalidResponse

    /// Invalid status code
    case invalidStatusCode(Int)

    /// File operation failed
    case fileOperationFailed(Error)

    /// Network operation failed
    case networkOperationFailed(Error)
}
