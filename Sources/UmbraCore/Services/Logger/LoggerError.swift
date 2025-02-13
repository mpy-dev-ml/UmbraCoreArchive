@preconcurrency import Foundation

/// Errors that can occur during logging operations
public enum LoggerError: LocalizedError {
    /// Failed to write to log destination
    case writeFailure(Error)
    /// Invalid log configuration
    case invalidConfiguration(String)
    /// Log destination not accessible
    case destinationNotAccessible(URL)
    /// Permission denied
    case permissionDenied(URL)

    // MARK: Public

    /// Localized description of the error
    public var errorDescription: String? {
        switch self {
        case let .writeFailure(error):
            "Failed to write to log: \(error.localizedDescription)"
        case let .invalidConfiguration(reason):
            "Invalid log configuration: \(reason)"
        case let .destinationNotAccessible(url):
            "Log destination not accessible: \(url.path)"
        case let .permissionDenied(url):
            "Permission denied for log destination: \(url.path)"
        }
    }

    /// Failure reason for the error
    public var failureReason: String? {
        switch self {
        case .writeFailure:
            "The system was unable to write to the log destination"
        case .invalidConfiguration:
            "The provided logging configuration is invalid"
        case .destinationNotAccessible:
            "The specified log destination cannot be accessed"
        case .permissionDenied:
            "The application does not have permission to access the log destination"
        }
    }

    /// Recovery suggestion for the error
    public var recoverySuggestion: String? {
        switch self {
        case .writeFailure:
            "Check disk space and permissions"
        case .invalidConfiguration:
            "Review logging configuration settings"
        case .destinationNotAccessible:
            "Verify the log destination exists and is accessible"
        case .permissionDenied:
            "Request necessary permissions or use a different log destination"
        }
    }
}
