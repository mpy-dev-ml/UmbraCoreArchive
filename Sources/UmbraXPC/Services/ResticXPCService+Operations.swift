//
// ResticXPCService+Operations.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

//
// ResticXPCService+Operations.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

@available(macOS 13.0, *)
extension ResticXPCService {
    // MARK: - Operation Types

    /// Represents a pending Restic XPC operation
    struct ResticXPCOperation: Identifiable {
        let id: UUID
        let type: OperationType
        let startTime: Date
        var status: OperationStatus
        var progress: Double
        var error: Error?

        init(type: OperationType) {
            self.id = UUID()
            self.type = type
            self.startTime = Date()
            self.status = .pending
            self.progress = 0.0
        }
    }

    /// Types of operations that can be performed
    enum OperationType {
        case backup(source: URL, destination: URL)
        case restore(source: URL, destination: URL)
        case initialize(url: URL)
        case list
        case check
        case prune

        var description: String {
            switch self {
            case let .backup(source, destination):
                return """
                    Backup from \(source.path) to \
                    \(destination.path)
                    """
            case let .restore(source, destination):
                return """
                    Restore from \(source.path) to \
                    \(destination.path)
                    """
            case let .initialize(url):
                return "Initialize repository at \(url.path)"
            case .list:
                return "List snapshots"
            case .check:
                return "Check repository"
            case .prune:
                return "Prune repository"
            }
        }
    }

    /// Status of an operation
    enum OperationStatus {
        case pending
        case running
        case completed
        case failed
        case cancelled
    }

    // MARK: - Operation Management

    /// Start tracking a new operation
    /// - Parameter type: Type of operation to track
    /// - Returns: ID of the new operation
    func startOperation(_ type: OperationType) -> UUID {
        let operation = ResticXPCOperation(type: type)
        queue.sync {
            pendingOperations.append(operation)
        }

        let message = "Started operation: \(type.description)"
        let metadata = ["operation_id": operation.id.uuidString]
        let config = LogConfig(metadata: metadata)
        logger.info(message, config: config)
        return operation.id
    }

    /// Update the status of an operation
    /// - Parameters:
    ///   - id: Operation ID
    ///   - status: New status
    ///   - error: Optional error if operation failed
    func updateOperation(
        _ id: UUID,
        status: OperationStatus,
        error: Error? = nil
    ) {
        queue.sync {
            guard let index = pendingOperations.firstIndex(
                where: { $0.id == id }
            ) else { return }

            pendingOperations[index].status = status
            pendingOperations[index].error = error

            let metadata: [String: String] = [
                "operation_id": id.uuidString,
                "status": String(describing: status)
            ]
            let config = LogConfig(metadata: metadata)
            let message = "Updated operation status"
            logger.info(message, config: config)

            if case .completed = status,
               case .failed = status,
               case .cancelled = status {
                cleanupOperation(id)
            }
        }
    }

    /// Update the progress of an operation
    /// - Parameters:
    ///   - id: Operation ID
    ///   - progress: Progress value between 0 and 1
    func updateOperationProgress(_ id: UUID, progress: Double) {
        queue.sync {
            guard let index = pendingOperations.firstIndex(
                where: { $0.id == id }
            ) else { return }

            pendingOperations[index].progress = progress

            let metadata: [String: String] = [
                "operation_id": id.uuidString,
                "progress": String(format: "%.2f", progress)
            ]
            let config = LogConfig(metadata: metadata)
            let message = "Updated operation progress"
            logger.debug(message, config: config)
        }
    }

    /// Cancel an operation
    /// - Parameter id: Operation ID
    func cancelOperation(_ id: UUID) {
        queue.sync {
            guard let index = pendingOperations.firstIndex(
                where: { $0.id == id }
            ) else { return }

            pendingOperations[index].status = .cancelled

            let metadata = ["operation_id": id.uuidString]
            let config = LogConfig(metadata: metadata)
            let message = "Operation cancelled"
            logger.info(message, config: config)

            cleanupOperation(id)
        }
    }

    /// Get the status of an operation
    /// - Parameter id: Operation ID
    /// - Returns: Current operation status and progress
    func getOperationStatus(
        _ id: UUID
    ) -> (status: OperationStatus, progress: Double)? {
        queue.sync {
            guard let operation = pendingOperations.first(
                where: { $0.id == id }
            ) else { return nil }

            return (operation.status, operation.progress)
        }
    }

    /// Clean up completed or failed operations
    /// - Parameter id: Operation ID to clean up
    private func cleanupOperation(_ id: UUID) {
        pendingOperations.removeAll { $0.id == id }
        let metadata = ["operation_id": id.uuidString]
        let config = LogConfig(metadata: metadata)
        let message = "Operation cleaned up"
        logger.debug(message, config: config)
    }
}
