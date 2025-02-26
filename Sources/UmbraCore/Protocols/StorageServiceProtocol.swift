import Foundation

// MARK: - StorageServiceProtocol

/// Protocol for managing persistent storage operations
public protocol StorageServiceProtocol {
    /// Save data to storage
    /// - Parameters:
    ///   - data: Data to save
    ///   - key: Storage key
    /// - Throws: StorageError if save fails
    func save(_ data: Data, forKey key: String) throws

    /// Load data from storage
    /// - Parameter key: Storage key
    /// - Returns: Retrieved data
    /// - Throws: StorageError if load fails
    func load(forKey key: String) throws -> Data

    /// Delete data from storage
    /// - Parameter key: Storage key
    /// - Throws: StorageError if deletion fails
    func delete(forKey key: String) throws
}

// MARK: - StorageError

/// Error types for storage operations
public enum StorageError: LocalizedError {
    case fileOperationFailed(String)
    case invalidData
    case accessDenied
    case notFound

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case let .fileOperationFailed(operation):
            "File operation failed: \(operation)"

        case .invalidData:
            "Invalid data format"

        case .accessDenied:
            "Access denied"

        case .notFound:
            "Data not found"
        }
    }
}
