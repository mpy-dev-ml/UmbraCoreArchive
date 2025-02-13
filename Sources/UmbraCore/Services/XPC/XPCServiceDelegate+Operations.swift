@preconcurrency import Foundation
import os.log

// MARK: - Operation Tracking

extension XPCServiceDelegate {
    /// Start tracking an operation
    func startTracking(_ operation: Operation) {
        queue.async { [weak self] in
            guard let self else {
                return
            }
            activeOperations[operation.identifier] = operation
            logger.info(
                "Started tracking operation",
                metadata: [
                    "operation_id": operation.identifier,
                    "operation_type": operation.type
                ]
            )
        }
    }

    /// Stop tracking an operation
    func stopTracking(_ operation: Operation) {
        queue.async { [weak self] in
            guard let self else {
                return
            }
            activeOperations.removeValue(forKey: operation.identifier)
            logger.info(
                "Stopped tracking operation",
                metadata: [
                    "operation_id": operation.identifier,
                    "operation_type": operation.type
                ]
            )
        }
    }

    /// Cancel all active operations
    func cancelAllOperations() {
        queue.async { [weak self] in
            guard let self else {
                return
            }
            for operation in activeOperations.values {
                cancelOperation(operation)
            }
            activeOperations.removeAll()
        }
    }

    /// Cancel a specific operation
    func cancelOperation(_ operation: Operation) {
        operation.cancel()
        logger.info(
            "Cancelled operation",
            metadata: [
                "operation_id": operation.identifier,
                "operation_type": operation.type
            ]
        )
    }
}
