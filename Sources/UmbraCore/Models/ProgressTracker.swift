import Foundation

// MARK: - ProgressTrackerProtocol

/// Protocol for tracking progress of operations
public protocol ProgressTrackerProtocol {
    /// Start tracking an operation
    /// - Parameter operationId: Unique identifier for the operation
    func startOperation(_ operationID: UUID)

    /// Update progress for an operation
    /// - Parameters:
    ///   - operationId: Operation identifier
    ///   - progress: Progress value between 0 and 1
    func updateProgress(_ operationID: UUID, progress: Double)

    /// Mark an operation as failed
    /// - Parameters:
    ///   - operationId: Operation identifier
    ///   - error: Error that caused the failure
    func failOperation(_ operationID: UUID, error: Error)

    /// Reset all progress tracking
    func reset()
}

// MARK: - ProgressTracker

/// Default implementation of progress tracker
public final class ProgressTracker: ProgressTrackerProtocol {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Create a new progress tracker
    /// - Parameter notificationCenter: Center for posting notifications
    public init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    // MARK: Public

    // MARK: - ProgressTrackerProtocol

    public func startOperation(_ operationID: UUID) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else {
                return
            }

            operations[operationID] = OperationState(
                startTime: Date(),
                progress: 0,
                status: .running
            )

            notificationCenter.post(
                name: .progressTrackerOperationStarted,
                object: self,
                userInfo: [
                    "operationId": operationID
                ]
            )
        }
    }

    public func updateProgress(_ operationID: UUID, progress: Double) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else {
                return
            }

            guard var state = operations[operationID] else {
                return
            }
            state.progress = progress
            operations[operationID] = state

            let userInfo: [String: Any] = [
                "operationId": operationID,
                "progress": progress
            ]

            notificationCenter.post(
                name: .progressTrackerProgressUpdated,
                object: self,
                userInfo: userInfo
            )
        }
    }

    public func failOperation(_ operationID: UUID, error: Error) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else {
                return
            }

            guard var state = operations[operationID] else {
                return
            }
            state.status = .failed(error)
            operations[operationID] = state

            let userInfo: [String: Any] = [
                "operationId": operationID,
                "error": error
            ]

            notificationCenter.post(
                name: .progressTrackerOperationFailed,
                object: self,
                userInfo: userInfo
            )
        }
    }

    public func reset() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else {
                return
            }

            operations.removeAll()

            notificationCenter.post(name: .progressTrackerReset, object: self)
        }
    }

    // MARK: Private

    private let notificationCenter: NotificationCenter
    private var operations: [UUID: OperationState] = [:]
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.rBUM.ProgressTracker",
        attributes: .concurrent
    )
}

// MARK: - OperationState

private struct OperationState {
    let startTime: Date
    var progress: Double
    var status: OperationStatus
}

// MARK: - OperationStatus

private enum OperationStatus {
    case running
    case failed(Error)
}

// MARK: - Notification Names

public extension Notification.Name {
    /// Posted when an operation starts
    static let progressTrackerOperationStarted = Notification
        .Name("progressTrackerOperationStarted")

    /// Posted when progress is updated
    static let progressTrackerProgressUpdated = Notification.Name("progressTrackerProgressUpdated")

    /// Posted when an operation fails
    static let progressTrackerOperationFailed = Notification.Name("progressTrackerOperationFailed")

    /// Posted when progress is reset
    static let progressTrackerReset = Notification.Name("progressTrackerReset")
}
