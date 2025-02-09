//
// FileManager+DiskSpace.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

extension FileManager {
    /// Get available disk space at a URL
    /// - Parameter url: URL to check
    /// - Returns: Available space in bytes
    /// - Throws: If unable to get disk space information
    func availableSpace(at url: URL) async throws -> Int64 {
        let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityKey])
        guard let capacity = values.volumeAvailableCapacity else {
            throw FileManagerError.failedToGetDiskSpace
        }
        return Int64(capacity)
    }
}

/// Errors that can occur during file manager operations
public enum FileManagerError: LocalizedError {
    case failedToGetDiskSpace
    
    public var errorDescription: String? {
        switch self {
        case .failedToGetDiskSpace:
            return "Failed to get available disk space"
        }
    }
}
