import Foundation
import Logging

/// Result of an XPC service operation
@frozen
public enum XPCServiceResult: Sendable {
    /// Operation completed successfully
    case success(data: Data?)
    /// Operation failed with error
    case failure(error: Error)

    // MARK: - Properties

    /// Whether the result is successful
    public var isSuccess: Bool {
        switch self {
        case .success:
            true

        case .failure:
            false
        }
    }

    /// Result data if successful
    public var data: Data? {
        switch self {
        case let .success(data):
            data

        case .failure:
            nil
        }
    }

    /// Error if failed
    public var error: Error? {
        switch self {
        case .success:
            nil

        case let .failure(error):
            error
        }
    }

    // MARK: - Methods

    /// Convert result to metadata for logging
    /// - Returns: Logger metadata
    public func toMetadata() -> Logger.Metadata {
        switch self {
        case let .success(data):
            [
                "status": "success",
                "data_size": .string(data.map { String($0.count) } ?? "nil")
            ]

        case let .failure(error):
            [
                "status": "failure",
                "error": .string(error.localizedDescription)
            ]
        }
    }
}

/// Result of an XPC service operation with a specific value type
@frozen
public enum XPCServiceTypedResult<T>: Sendable where T: Sendable {
    /// Operation completed successfully
    case success(value: T)
    /// Operation failed with error
    case failure(error: Error)

    // MARK: - Properties

    /// Whether the result is successful
    public var isSuccess: Bool {
        switch self {
        case .success:
            true

        case .failure:
            false
        }
    }

    /// Result value if successful
    public var value: T? {
        switch self {
        case let .success(value):
            value

        case .failure:
            nil
        }
    }

    /// Error if failed
    public var error: Error? {
        switch self {
        case .success:
            nil

        case let .failure(error):
            error
        }
    }

    // MARK: - Methods

    /// Convert result to metadata for logging
    /// - Returns: Logger metadata
    public func toMetadata() -> Logger.Metadata {
        switch self {
        case .success:
            [
                "status": "success",
                "type": .string(String(describing: T.self))
            ]

        case let .failure(error):
            [
                "status": "failure",
                "type": .string(String(describing: T.self)),
                "error": .string(error.localizedDescription)
            ]
        }
    }

    /// Map successful result to a new type
    /// - Parameter transform: Transform function
    /// - Returns: New result type
    public func map<U>(_ transform: (T) -> U) -> XPCServiceTypedResult<U> {
        switch self {
        case let .success(value):
            .success(value: transform(value))

        case let .failure(error):
            .failure(error: error)
        }
    }

    /// Flat map successful result to a new result type
    /// - Parameter transform: Transform function
    /// - Returns: New result type
    public func flatMap<U>(_ transform: (T) -> XPCServiceTypedResult<U>) -> XPCServiceTypedResult<U> {
        switch self {
        case let .success(value):
            transform(value)

        case let .failure(error):
            .failure(error: error)
        }
    }
}

// MARK: - CustomStringConvertible

extension XPCServiceResult: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .success(data):
            "success(data: \(data?.count ?? 0) bytes)"

        case let .failure(error):
            "failure(error: \(error.localizedDescription))"
        }
    }
}

extension XPCServiceTypedResult: CustomStringConvertible {
    public var description: String {
        switch self {
        case .success:
            "success(type: \(T.self))"

        case let .failure(error):
            "failure(error: \(error.localizedDescription))"
        }
    }
}

// MARK: - CustomDebugStringConvertible

extension XPCServiceResult: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case let .success(data):
            "XPCServiceResult.success(data: \(data?.count ?? 0) bytes)"

        case let .failure(error):
            "XPCServiceResult.failure(error: \(String(reflecting: error)))"
        }
    }
}

extension XPCServiceTypedResult: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case let .success(value):
            "XPCServiceTypedResult<\(T.self)>.success(value: \(String(reflecting: value)))"

        case let .failure(error):
            "XPCServiceTypedResult<\(T.self)>.failure(error: \(String(reflecting: error)))"
        }
    }
}

// MARK: - Equatable

// We compare errors by their string description since Error doesn't conform to Equatable.
// This is a reasonable approximation for equality but may not catch all edge cases.
extension XPCServiceResult: Equatable {
    public static func == (lhs: XPCServiceResult, rhs: XPCServiceResult) -> Bool {
        switch (lhs, rhs) {
        case let (.success(lhsData), .success(rhsData)):
            lhsData == rhsData

        case let (.failure(lhsError), .failure(rhsError)):
            // Compare error types and descriptions for better equality check
            type(of: lhsError) == type(of: rhsError) &&
            lhsError.localizedDescription == rhsError.localizedDescription

        default:
            false
        }
    }
}

extension XPCServiceTypedResult: Equatable where T: Equatable {
    public static func == (lhs: XPCServiceTypedResult<T>, rhs: XPCServiceTypedResult<T>) -> Bool {
        switch (lhs, rhs) {
        case let (.success(lhsValue), .success(rhsValue)):
            lhsValue == rhsValue

        case let (.failure(lhsError), .failure(rhsError)):
            // Compare error types and descriptions for better equality check
            type(of: lhsError) == type(of: rhsError) &&
            lhsError.localizedDescription == rhsError.localizedDescription

        default:
            false
        }
    }
}
