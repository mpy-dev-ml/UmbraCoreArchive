@preconcurrency import Foundation

// MARK: - FileManager + DiskSpace

extension FileManager {
    /// Retrieves the available disk space at a specified URL location
    /// - Parameter url: The URL location to check available space
    /// - Returns: Available space in bytes as a 64-bit integer
    /// - Throws: `FileManagerError.failedToGetDiskSpace` if unable to retrieve space information
    func availableSpace(at url: URL) async throws -> Int64 {
        let resourceKeys: Set<URLResourceKey> = [.volumeAvailableCapacityKey]
        let values = try url.resourceValues(forKeys: resourceKeys)

        guard let capacity = values.volumeAvailableCapacity else {
            throw FileManagerError.failedToGetDiskSpace
        }

        return Int64(capacity)
    }
}

// MARK: - FileManagerError

/// Errors that can occur during file system operations
public enum FileManagerError: LocalizedError {
    /// Failed to retrieve available disk space information
    case failedToGetDiskSpace

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .failedToGetDiskSpace:
            "Failed to retrieve available disk space information"
        }
    }
}
