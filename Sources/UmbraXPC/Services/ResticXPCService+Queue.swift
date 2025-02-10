import Foundation

@available(macOS 13.0, *)
extension ResticXPCService {
    // MARK: - Queue Processing

    /// Process the next message in the queue
    func processNextMessage() async {
        guard let message = await messageQueue.nextPendingMessage() else {
            return
        }

        do {
            let result = try await executeCommand(message.command)
            await messageQueue.completeMessage(message.id)

            // Notify success
            let successInfo: [String: Any] = [
                "messageId": message.id,
                "result": result
            ]
            NotificationCenter.default.post(
                name: .xpcCommandCompleted,
                object: nil,
                userInfo: successInfo
            )
        } catch {
            await messageQueue.completeMessage(message.id, error: error)

            // Notify failure
            let failureInfo: [String: Any] = [
                "messageId": message.id,
                "error": error
            ]
            NotificationCenter.default.post(
                name: .xpcCommandFailed,
                object: nil,
                userInfo: failureInfo
            )
        }
    }

    /// Start the queue processor
    func startQueueProcessor() {
        guard queueProcessor == nil else {
            return
        }

        queueProcessor = Task {
            while !Task.isCancelled {
                await processNextMessage()
                // 100ms delay between processing messages
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }

    /// Stop the queue processor
    func stopQueueProcessor() {
        queueProcessor?.cancel()
        queueProcessor = nil
    }

    // MARK: - Queue Management

    /// Enqueue a command for execution
    /// - Parameter command: The command to execute
    /// - Returns: The ID of the queued message
    func enqueueCommand(_ command: XPCCommandConfig) async -> UUID {
        let messageID = await messageQueue.enqueue(command)
        startQueueProcessor()
        return messageID
    }

    /// Get the current status of the message queue
    /// - Returns: The current queue status
    func getQueueStatus() async -> XPCMessageQueue.QueueStatus {
        await messageQueue.queueStatus()
    }

    /// Clean up completed and failed messages
    func cleanupQueue() async {
        await messageQueue.cleanup()
    }
}

extension ResticXPCService {
    func enqueueOperation(_ operation: ResticOperation) throws {
        let validStates = [
            OperationState.ready,
            OperationState.pending,
            OperationState.queued
        ]
        
        guard validStates.contains(operation.state) else {
            throw ResticXPCError.invalidOperationState
        }
        
        operationQueue.addOperation(operation)
    }
    
    func cancelOperation(_ identifier: UUID) throws {
        let validStates = [
            OperationState.queued,
            OperationState.running,
            OperationState.suspended
        ]
        
        guard let operation = findOperation(identifier),
              validStates.contains(operation.state) else {
            throw ResticXPCError.operationNotFound
        }
        
        operation.cancel()
    }
    
    private func findOperation(_ identifier: UUID) -> ResticOperation? {
        operationQueue.operations.first { operation in
            guard let resticOperation = operation as? ResticOperation else {
                return false
            }
            return resticOperation.identifier == identifier
        }
    }
}
