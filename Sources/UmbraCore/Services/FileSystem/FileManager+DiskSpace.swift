@preconcurrency import Foundation

// MARK: - FileManager + DiskSpace

extension FileManager {
    /// Retrieves the available disk space at a specified URL location
    /// - Parameter url: The URL location to check available space
    /// - Returns: Available space in bytes as a 64-bit integer
    /// - Throws: `FileManagerError.failedToGetDiskSpace` if unable to retrieve space information
    func availableSpace(at url: URL) async throws -> Int64 {
        do {
            let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            if let capacity = values.volumeAvailableCapacity {
                return Int64(capacity)
            }
            throw FileManagerError.failedToGetDiskSpace
        } catch {
            throw FileManagerError.failedToGetDiskSpace
        }
    }
}

// MARK: - FileManagerError

/// Errors that can occur during file system operations
public enum FileManagerError: LocalizedError {
    /// Failed to retrieve available disk space information
    case failedToGetDiskSpace
    
    public var errorDescription: String? {
        switch self {
        case .failedToGetDiskSpace:
            return "Failed to retrieve available disk space information"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .failedToGetDiskSpace:
            return "Verify the path exists and you have appropriate permissions to access disk space information"
        }
    }
}
