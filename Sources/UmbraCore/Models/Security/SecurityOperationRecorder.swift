//
// SecurityOperationRecorder.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation
import os.log

// MARK: - Security Operation Recorder

/// Records and logs security-related operations in the system
@available(macOS 13.0, *)
public struct SecurityOperationRecorder {
    // MARK: - Properties
    
    /// Logger instance for recording operations
    private let logger: Logger
    
    /// Queue for synchronizing operation recording
    private let queue: DispatchQueue
    
    // MARK: - Initialization
    
    /// Creates a new security operation recorder
    /// - Parameters:
    ///   - logger: Logger instance for recording operations
    ///   - label: Queue label for synchronization (defaults to bundle identifier)
    public init(
        logger: Logger,
        label: String = Bundle.main.bundleIdentifier ?? "com.umbra.core"
    ) {
        self.logger = logger
        self.queue = DispatchQueue(
            label: "\(label).security-recorder",
            qos: .utility
        )
    }
    
    // MARK: - Recording Operations
    
    /// Records a security operation
    /// - Parameters:
    ///   - url: URL associated with the operation
    ///   - type: Type of security operation
    ///   - status: Operation status
    ///   - error: Optional error message
    ///   - metadata: Additional metadata
    public func recordOperation(
        url: URL,
        type: SecurityOperationType,
        status: SecurityOperationStatus,
        error: String? = nil,
        metadata: [String: String] = [:]
    ) {
        queue.async {
            let operation = SecurityOperation(
                url: url,
                operationType: type,
                timestamp: Date(),
                status: status,
                error: error
            )
            
            self.logOperation(operation, metadata: metadata)
        }
    }
    
    /// Records a security operation with error
    /// - Parameters:
    ///   - url: URL associated with the operation
    ///   - type: Type of security operation
    ///   - error: Error that occurred
    ///   - metadata: Additional metadata
    public func recordError(
        url: URL,
        type: SecurityOperationType,
        error: Error,
        metadata: [String: String] = [:]
    ) {
        recordOperation(
            url: url,
            type: type,
            status: .failure,
            error: error.localizedDescription,
            metadata: metadata
        )
    }
    
    // MARK: - Private Methods
    
    /// Logs a security operation with metadata
    /// - Parameters:
    ///   - operation: Operation to log
    ///   - metadata: Additional metadata
    private func logOperation(
        _ operation: SecurityOperation,
        metadata: [String: String]
    ) {
        var logMetadata = [
            "type": operation.operationType.rawValue,
            "url": operation.url.lastPathComponent,
            "status": operation.status.rawValue,
            "timestamp": operation.timestamp.ISO8601Format()
        ]
        
        // Add error if present
        if let error = operation.error {
            logMetadata["error"] = error
        }
        
        // Add custom metadata
        logMetadata.merge(metadata) { current, _ in current }
        
        // Create log configuration
        let config = LogConfig(metadata: logMetadata)
        
        // Log with appropriate level
        switch operation.status {
        case .success:
            logger.info("Security operation completed", config: config)
            
        case .failure:
            logger.error(
                "Security operation failed: \(operation.error ?? "Unknown error")",
                config: config
            )
            
        case .pending:
            logger.debug("Security operation pending", config: config)
            
        case .cancelled:
            logger.notice("Security operation cancelled", config: config)
        }
    }
}

// MARK: - Supporting Types

/// Configuration for security operation logging
private struct LogConfig {
    /// Metadata for the log entry
    let metadata: [String: String]
}
