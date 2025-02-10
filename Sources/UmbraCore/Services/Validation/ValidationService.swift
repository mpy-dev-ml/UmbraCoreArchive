//
// ValidationService.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Service for validating data and operations
public final class ValidationService: BaseSandboxedService {
    // MARK: - Types

    /// Validation rule
    public struct ValidationRule {
        /// Rule identifier
        public let id: String

        /// Rule description
        public let description: String

        /// Priority level
        public let priority: Priority

        /// Validation function
        public let validate: (Any) async throws -> ValidationResult

        /// Initialize with values
        public init(
            id: String,
            description: String,
            priority: Priority = .normal,
            validate: @escaping (Any) async throws -> ValidationResult
        ) {
            self.id = id
            self.description = description
            self.priority = priority
            self.validate = validate
        }
    }

    /// Validation result
    public struct ValidationResult {
        /// Whether validation passed
        public let passed: Bool

        /// Validation message
        public let message: String

        /// Additional details
        public let details: [String: Any]

        /// Initialize with values
        public init(
            passed: Bool,
            message: String,
            details: [String: Any] = [:]
        ) {
            self.passed = passed
            self.message = message
            self.details = details
        }
    }

    /// Priority level
    public enum Priority: Int, Comparable {
        case low = 0
        case normal = 1
        case high = 2
        case critical = 3

        public static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: - Properties

    /// Validation rules by type
    private var rules: [String: [ValidationRule]] = [:]

    /// Queue for synchronizing operations
    private let queue = DispatchQueue(
        label: "dev.mpy.umbracore.validation",
        qos: .userInitiated,
        attributes: .concurrent
    )

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - performanceMonitor: Performance monitor
    ///   - logger: Logger for tracking operations
    public init(
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        self.performanceMonitor = performanceMonitor
        super.init(logger: logger)
    }

    // MARK: - Public Methods

    /// Register a validation rule
    /// - Parameters:
    ///   - rule: Rule to register
    ///   - type: Type identifier
    public func registerRule(_ rule: ValidationRule, forType type: String) {
        queue.async(flags: .barrier) {
            self.rules[type, default: []].append(rule)
            self.rules[type]?.sort { $0.priority > $1.priority }

            self.logger.debug(
                """
                Registered validation rule:
                Type: \(type)
                ID: \(rule.id)
                Description: \(rule.description)
                Priority: \(rule.priority)
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Validate data
    /// - Parameters:
    ///   - data: Data to validate
    ///   - type: Type identifier
    /// - Returns: Array of validation results
    /// - Throws: ValidationError if validation fails
    public func validate(
        _ data: Any,
        forType type: String
    ) async throws -> [ValidationResult] {
        try validateUsable(for: "validate")

        return try await performanceMonitor.trackDuration(
            "validation.\(type)"
        ) {
            let rules = queue.sync { self.rules[type] ?? [] }

            var results: [ValidationResult] = []

            for rule in rules {
                do {
                    let result = try await rule.validate(data)
                    results.append(result)

                    if !result.passed && rule.priority == .critical {
                        throw ValidationError.criticalValidationFailed(
                            rule.id,
                            result.message
                        )
                    }
                } catch {
                    logger.error(
                        """
                        Validation failed:
                        Type: \(type)
                        Rule: \(rule.id)
                        Error: \(error.localizedDescription)
                        """,
                        file: #file,
                        function: #function,
                        line: #line
                    )
                    throw error
                }
            }

            return results
        }
    }

    /// Get registered rules
    /// - Parameter type: Optional type filter
    /// - Returns: Dictionary of rules by type
    public func getRegisteredRules(
        forType type: String? = nil
    ) -> [String: [ValidationRule]] {
        queue.sync {
            if let type = type {
                return [type: rules[type] ?? []]
            }
            return rules
        }
    }

    /// Remove rule
    /// - Parameters:
    ///   - ruleId: ID of rule to remove
    ///   - type: Type identifier
    public func removeRule(withId ruleId: String, forType type: String) {
        queue.async(flags: .barrier) {
            self.rules[type]?.removeAll { $0.id == ruleId }

            self.logger.debug(
                """
                Removed validation rule:
                Type: \(type)
                ID: \(ruleId)
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Clear all rules
    /// - Parameter type: Optional type filter
    public func clearRules(forType type: String? = nil) {
        queue.async(flags: .barrier) {
            if let type = type {
                self.rules[type]?.removeAll()

                self.logger.debug(
                    "Cleared validation rules for type: \(type)",
                    file: #file,
                    function: #function,
                    line: #line
                )
            } else {
                self.rules.removeAll()

                self.logger.debug(
                    "Cleared all validation rules",
                    file: #file,
                    function: #function,
                    line: #line
                )
            }
        }
    }
}

/// Errors that can occur during validation
public enum ValidationError: LocalizedError {
    /// Critical validation failed
    case criticalValidationFailed(String, String)
    /// Invalid validation rule
    case invalidValidationRule(String)
    /// Validation type not found
    case validationTypeNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .criticalValidationFailed(let rule, let message):
            return "Critical validation failed - Rule \(rule): \(message)"
        case .invalidValidationRule(let reason):
            return "Invalid validation rule: \(reason)"
        case .validationTypeNotFound(let type):
            return "Validation type not found: \(type)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .criticalValidationFailed:
            return "Fix the validation issues and try again"
        case .invalidValidationRule:
            return "Check the validation rule configuration"
        case .validationTypeNotFound:
            return "Register validation rules for this type"
        }
    }
}
