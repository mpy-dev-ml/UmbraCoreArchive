@preconcurrency import Foundation

// MARK: - ProgressTrackerProtocol

/// Protocol for tracking progress of operations
public protocol ProgressTrackerProtocol: Sendable {
    /// Start tracking an operation
    /// - Parameter operationID: ID of the operation
    func startOperation(_ operationID: UUID)

    /// Update progress for an operation
    /// - Parameters:
    ///   - operationID: ID of the operation
    ///   - progress: Progress value (0-100)
    func updateProgress(_ operationID: UUID, progress: Double)

    /// Complete an operation successfully
    /// - Parameter operationID: ID of the operation
    func completeOperation(_ operationID: UUID)

    /// Fail an operation with error
    /// - Parameters:
    ///   - operationID: ID of the operation
    ///   - error: Error that caused the failure
    func failOperation(_ operationID: UUID, error: Error)

    /// Get current state for an operation
    /// - Parameter operationID: ID of the operation
    /// - Returns: Operation state if found
    func getOperationState(_ operationID: UUID) -> OperationStateStruct?

    /// Get all operation states
    /// - Returns: Dictionary of operation states by ID
    func getAllOperationStates() -> [UUID: OperationStateStruct]
}

// MARK: - ProgressTracker

/// Tracks progress of operations
public final class ProgressTracker: ProgressTrackerProtocol, @unchecked Sendable {
    // MARK: - Types

    /// Represents the state of an operation
    @frozen
    public enum OperationState: String, Sendable {
        /// Operation is waiting to start
        case waiting
        /// Operation is in progress
        case inProgress
        /// Operation completed successfully
        case completed
        /// Operation failed
        case failed
        /// Operation was cancelled
        case cancelled
        /// Operation is paused
        case paused
    }

    /// State of an operation
    public struct OperationStateStruct: Sendable {
        /// Start time of the operation
        public let startTime: Date

        /// Current progress (0-100)
        public let progress: Double

        /// Current status
        public let status: OperationState

        /// Error if operation failed
        public let error: Error?

        public init(startTime: Date, progress: Double, status: OperationState, error: Error?) {
            self.startTime = startTime
            self.progress = progress
            self.status = status
            self.error = error
        }
    }

    // MARK: - Properties

    /// Queue for synchronizing access
    private let queue: DispatchQueue

    /// Operation states by ID
    private var operations: [UUID: OperationStateStruct]

    /// Notification center
    private let notificationCenter: NotificationCenter

    // MARK: - Initialization

    /// Initialize tracker
    /// - Parameters:
    ///   - queue: Queue for synchronization
    ///   - notificationCenter: Notification center
    public init(
        queue: DispatchQueue = DispatchQueue(
            label: "dev.mpy.umbracore.progress-tracker", attributes: .concurrent
        ),
        notificationCenter: NotificationCenter = .default
    ) {
        self.queue = queue
        operations = [:]
        self.notificationCenter = notificationCenter
    }

    // MARK: Public

    // MARK: - ProgressTrackerProtocol

    public func startOperation(_ operationID: UUID) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else {
                return
            }

            operations[operationID] = OperationStateStruct(
                startTime: Date(),
                progress: 0,
                status: .inProgress,
                error: nil
            )

            notificationCenter.post(
                name: .progressTrackerOperationStarted,
                object: self,
                userInfo: ["operationID": operationID]
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

            let clampedProgress = min(max(progress, 0), 100)

            operations[operationID] = OperationStateStruct(
                startTime: state.startTime,
                progress: clampedProgress,
                status: state.status,
                error: state.error
            )

            notificationCenter.post(
                name: .progressTrackerOperationProgressed,
                object: self,
                userInfo: [
                    "operationID": operationID,
                    "progress": clampedProgress
                ]
            )
        }
    }

    public func completeOperation(_ operationID: UUID) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else {
                return
            }

            guard let state = operations[operationID] else {
                return
            }

            operations[operationID] = OperationStateStruct(
                startTime: state.startTime,
                progress: 100,
                status: .completed,
                error: nil
            )

            notificationCenter.post(
                name: .progressTrackerOperationCompleted,
                object: self,
                userInfo: ["operationID": operationID]
            )
        }
    }

    public func failOperation(_ operationID: UUID, error: Error) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else {
                return
            }

            guard let state = operations[operationID] else {
                return
            }

            operations[operationID] = OperationStateStruct(
                startTime: state.startTime,
                progress: state.progress,
                status: .failed,
                error: error
            )

            notificationCenter.post(
                name: .progressTrackerOperationFailed,
                object: self,
                userInfo: [
                    "operationID": operationID,
                    "error": error
                ]
            )
        }
    }

    public func getOperationState(_ operationID: UUID) -> OperationStateStruct? {
        queue.sync {
            operations[operationID]
        }
    }

    public func getAllOperationStates() -> [UUID: OperationStateStruct] {
        queue.sync {
            operations
        }
    }
}

// MARK: - Notification Names

public extension Notification.Name {
    /// Posted when an operation starts
    static let progressTrackerOperationStarted =
        Notification
            .Name("progressTrackerOperationStarted")

    /// Posted when an operation progresses
    static let progressTrackerOperationProgressed =
        Notification
            .Name("progressTrackerOperationProgressed")

    /// Posted when an operation completes
    static let progressTrackerOperationCompleted =
        Notification
            .Name("progressTrackerOperationCompleted")

    /// Posted when an operation fails
    static let progressTrackerOperationFailed =
        Notification
            .Name("progressTrackerOperationFailed")
}

// MARK: - ProgressTracker2

/// Tracks progress of an operation
@objc
public final class ProgressTracker2: NSObject, @unchecked Sendable {
    // MARK: - Properties
    
    /// Current progress (0.0 to 1.0)
    @objc
    public private(set) var progress: Double
    
    /// Current state of the operation
    public let state: OperationState
    
    /// Start time of the operation
    public let startTime: Date
    
    /// Estimated completion time
    public private(set) var estimatedCompletion: Date?
    
    /// Operation description
    public let description: String
    
    // MARK: - Initialization
    
    /// Initialize progress tracker
    /// - Parameters:
    ///   - description: Operation description
    ///   - state: Initial state
    public init(
        description: String,
        state: OperationState = .waiting
    ) {
        self.description = description
        self.state = state
        self.progress = 0.0
        self.startTime = Date()
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Update progress
    /// - Parameter progress: New progress value (0.0 to 1.0)
    public func updateProgress(_ progress: Double) {
        self.progress = max(0.0, min(1.0, progress))
        updateEstimatedCompletion()
    }
    
    // MARK: - Private Methods
    
    private func updateEstimatedCompletion() {
        guard progress > 0 else {
            estimatedCompletion = nil
            return
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let total = elapsed / progress
        let remaining = total - elapsed
        
        estimatedCompletion = Date(timeIntervalSinceNow: remaining)
    }
}

// MARK: - OperationState

/// Represents the state of an operation
@frozen
public enum OperationState: String, Sendable {
    /// Operation is waiting to start
    case waiting
    /// Operation is in progress
    case inProgress
    /// Operation completed successfully
    case completed
    /// Operation failed
    case failed
    /// Operation was cancelled
    case cancelled
    /// Operation is paused
    case paused
}
