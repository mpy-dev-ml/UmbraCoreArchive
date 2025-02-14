import Foundation
import Logging

/// Represents an operation to be executed by the XPC service
@Observable
@MainActor
public final class XPCServiceOperation: NSObject, NSSecureCoding {
    // MARK: - Types

    /// Operation status
    @frozen
    public enum Status: String, Sendable, Codable {
        /// Operation is queued
        case queued
        /// Operation is running
        case running
        /// Operation completed successfully
        case completed
        /// Operation failed
        case failed
        /// Operation was cancelled
        case cancelled

        /// Whether the operation is finished
        public var isFinished: Bool {
            switch self {
            case .queued, .running:
                false

            case .completed, .failed, .cancelled:
                true
            }
        }

        /// Whether the operation completed successfully
        public var isSuccessful: Bool {
            self == .completed
        }
    }

    /// Operation type
    @frozen
    public enum OperationType: String, Sendable, Codable {
        /// File operation
        case file
        /// Process operation
        case process
        /// Resource operation
        case resource
        /// Health check operation
        case healthCheck
        /// Custom operation
        case custom
    }

    /// Operation priority
    @frozen
    public enum Priority: Int, Sendable, Codable, Comparable {
        /// Low priority
        case low = 0
        /// Normal priority
        case normal = 1
        /// High priority
        case high = 2
        /// Critical priority
        case critical = 3

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: - Properties

    /// Unique identifier for the operation
    @Published
    public private(set) var id: UUID

    /// Type of operation
    @Published
    public private(set) var type: OperationType

    /// Current status
    @Published
    public private(set) var status: Status

    /// Operation priority
    @Published
    public private(set) var priority: Priority

    /// Creation timestamp
    @Published
    public private(set) var createdAt: Date

    /// Start timestamp
    @Published
    public private(set) var startedAt: Date?

    /// Completion timestamp
    @Published
    public private(set) var completedAt: Date?

    /// Operation error if any
    @Published
    public private(set) var error: Error?

    /// Operation progress (0.0 to 1.0)
    @Published
    public private(set) var progress: Double

    /// Operation metadata
    @Published
    public private(set) var metadata: [String: String]

    // MARK: - Computed Properties

    /// Whether the operation is finished
    public var isFinished: Bool {
        status.isFinished
    }

    /// Whether the operation completed successfully
    public var isSuccessful: Bool {
        status.isSuccessful
    }

    /// Duration in seconds if operation has started
    public var duration: TimeInterval? {
        guard let start = startedAt else { return nil }
        let end = completedAt ?? Date()
        return end.timeIntervalSince(start)
    }

    // MARK: - Private Properties

    /// Logger for operations
    private let logger: any LoggerProtocol

    // MARK: - Initialization

    /// Initialize with parameters
    /// - Parameters:
    ///   - id: Operation identifier
    ///   - type: Operation type
    ///   - priority: Operation priority
    ///   - metadata: Operation metadata
    ///   - logger: Logger for operations
    public init(
        id: UUID = UUID(),
        type: OperationType,
        priority: Priority = .normal,
        metadata: [String: String] = [:],
        logger: any LoggerProtocol
    ) {
        self.id = id
        self.type = type
        status = .queued
        self.priority = priority
        createdAt = Date()
        progress = 0.0
        self.metadata = metadata
        self.logger = logger
        super.init()

        logStatusChange()
    }

    // MARK: - NSSecureCoding

    private enum CodingKeys: String {
        case id
        case type
        case status
        case priority
        case createdAt
        case startedAt
        case completedAt
        case progress
        case metadata
    }

    public static var supportsSecureCoding: Bool { true }

    public func encode(with coder: NSCoder) {
        coder.encode(id.uuidString, forKey: CodingKeys.id.rawValue)
        coder.encode(type.rawValue, forKey: CodingKeys.type.rawValue)
        coder.encode(status.rawValue, forKey: CodingKeys.status.rawValue)
        coder.encode(priority.rawValue, forKey: CodingKeys.priority.rawValue)
        coder.encode(createdAt, forKey: CodingKeys.createdAt.rawValue)
        coder.encode(startedAt, forKey: CodingKeys.startedAt.rawValue)
        coder.encode(completedAt, forKey: CodingKeys.completedAt.rawValue)
        coder.encode(progress, forKey: CodingKeys.progress.rawValue)
        coder.encode(metadata, forKey: CodingKeys.metadata.rawValue)
    }

    public required init?(coder: NSCoder) {
        guard
            let idString = coder.decodeObject(of: NSString.self, forKey: CodingKeys.id.rawValue) as String?,
            let id = UUID(uuidString: idString),
            let typeString = coder.decodeObject(of: NSString.self, forKey: CodingKeys.type.rawValue) as String?,
            let type = OperationType(rawValue: typeString),
            let statusString = coder.decodeObject(of: NSString.self, forKey: CodingKeys.status.rawValue) as String?,
            let status = Status(rawValue: statusString),
            let createdAt = coder.decodeObject(of: NSDate.self, forKey: CodingKeys.createdAt.rawValue) as Date?,
            let metadata = coder.decodeObject(of: [NSString.self, NSString.self].self, forKey: CodingKeys.metadata.rawValue) as? [String: String]
        else {
            return nil
        }

        self.id = id
        self.type = type
        self.status = status
        priority = Priority(rawValue: coder.decodeInteger(forKey: CodingKeys.priority.rawValue)) ?? .normal
        self.createdAt = createdAt
        startedAt = coder.decodeObject(of: NSDate.self, forKey: CodingKeys.startedAt.rawValue) as Date?
        completedAt = coder.decodeObject(of: NSDate.self, forKey: CodingKeys.completedAt.rawValue) as Date?
        progress = coder.decodeDouble(forKey: CodingKeys.progress.rawValue)
        self.metadata = metadata
        logger = Logger(label: "dev.mpy.umbra.xpc-service-operation")

        super.init()
    }

    // MARK: - Public Methods

    /// Start the operation
    public func start() {
        guard status == .queued else { return }
        status = .running
        startedAt = Date()
        logStatusChange()
    }

    /// Complete the operation successfully
    public func complete() {
        guard status == .running else { return }
        status = .completed
        completedAt = Date()
        progress = 1.0
        logStatusChange()
    }

    /// Fail the operation with error
    /// - Parameter error: Operation error
    public func fail(_ error: Error) {
        guard status == .running else { return }
        status = .failed
        completedAt = Date()
        self.error = error
        logStatusChange()
    }

    /// Cancel the operation
    public func cancel() {
        guard status == .queued || status == .running else { return }
        status = .cancelled
        completedAt = Date()
        logStatusChange()
    }

    /// Update operation progress
    /// - Parameter progress: New progress value (0.0 to 1.0)
    public func updateProgress(_ progress: Double) {
        guard status == .running else { return }
        self.progress = min(max(progress, 0.0), 1.0)

        logger.debug(
            "Operation progress updated",
            metadata: [
                "operation_id": .string(id.uuidString),
                "progress": .string(String(progress))
            ]
        )
    }

    /// Update operation metadata
    /// - Parameter metadata: New metadata
    public func updateMetadata(_ metadata: [String: String]) {
        self.metadata = metadata

        logger.debug(
            "Operation metadata updated",
            metadata: [
                "operation_id": .string(id.uuidString),
                "metadata": .string(String(describing: metadata))
            ]
        )
    }

    // MARK: - Private Methods

    /// Log status change
    private func logStatusChange() {
        let metadata: Logger.Metadata = [
            "operation_id": .string(id.uuidString),
            "type": .string(type.rawValue),
            "status": .string(status.rawValue),
            "priority": .string(String(priority.rawValue))
        ]

        switch status {
        case .queued:
            logger.debug("Operation queued", metadata: metadata)

        case .running:
            logger.info("Operation started", metadata: metadata)

        case .completed:
            logger.info(
                "Operation completed",
                metadata: metadata.merging([
                    "duration": .string(String(duration ?? 0))
                ]) { $1 }
            )

        case .failed:
            logger.error(
                "Operation failed",
                metadata: metadata.merging([
                    "error": .string(error?.localizedDescription ?? "Unknown error"),
                    "duration": .string(String(duration ?? 0))
                ]) { $1 }
            )

        case .cancelled:
            logger.warning(
                "Operation cancelled",
                metadata: metadata.merging([
                    "duration": .string(String(duration ?? 0))
                ]) { $1 }
            )
        }
    }
}
