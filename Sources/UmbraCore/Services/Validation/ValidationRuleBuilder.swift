import Foundation

/// Builder for creating validation rules
public final class ValidationRuleBuilder {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with configuration
    /// - Parameter configuration: Builder configuration
    public init(configuration: Configuration = Configuration(id: "", description: "")) {
        self.configuration = configuration
    }

    // MARK: Public

    // MARK: - Types

    /// Builder configuration
    public struct Configuration {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            id: String,
            description: String,
            priority: ValidationService.Priority = .normal,
            conditions: [ValidationCondition] = []
        ) {
            self.id = id
            self.description = description
            self.priority = priority
            self.conditions = conditions
        }

        // MARK: Public

        /// Rule identifier
        public var id: String

        /// Rule description
        public var description: String

        /// Priority level
        public var priority: ValidationService.Priority

        /// Validation conditions
        public var conditions: [ValidationCondition]
    }

    /// Validation condition
    public struct ValidationCondition {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            name: String,
            validate: @escaping (Any) async throws -> Bool,
            errorMessage: String
        ) {
            self.name = name
            self.validate = validate
            self.errorMessage = errorMessage
        }

        // MARK: Public

        /// Condition name
        public let name: String

        /// Validation function
        public let validate: (Any) async throws -> Bool

        /// Error message
        public let errorMessage: String
    }

    // MARK: - Public Methods

    /// Set rule identifier
    /// - Parameter id: Rule identifier
    /// - Returns: Builder instance
    @discardableResult
    public func withID(_ id: String) -> ValidationRuleBuilder {
        configuration.id = id
        return self
    }

    /// Set rule description
    /// - Parameter description: Rule description
    /// - Returns: Builder instance
    @discardableResult
    public func withDescription(_ description: String) -> ValidationRuleBuilder {
        configuration.description = description
        return self
    }

    /// Set priority level
    /// - Parameter priority: Priority level
    /// - Returns: Builder instance
    @discardableResult
    public func withPriority(
        _ priority: ValidationService.Priority
    ) -> ValidationRuleBuilder {
        configuration.priority = priority
        return self
    }

    /// Add validation condition
    /// - Parameters:
    ///   - name: Condition name
    ///   - errorMessage: Error message
    ///   - validate: Validation function
    /// - Returns: Builder instance
    @discardableResult
    public func withCondition(
        name: String,
        errorMessage: String,
        validate: @escaping (Any) async throws -> Bool
    ) -> ValidationRuleBuilder {
        let condition = ValidationCondition(
            name: name,
            validate: validate,
            errorMessage: errorMessage
        )
        configuration.conditions.append(condition)
        return self
    }

    /// Build validation rule
    /// - Returns: Validation rule
    /// - Throws: ValidationError if build fails
    public func build() throws -> ValidationService.ValidationRule {
        // Validate configuration
        guard !configuration.id.isEmpty else {
            throw ValidationError.invalidValidationRule("Rule ID is required")
        }

        guard !configuration.description.isEmpty else {
            throw ValidationError.invalidValidationRule("Rule description is required")
        }

        guard !configuration.conditions.isEmpty else {
            throw ValidationError.invalidValidationRule("At least one condition is required")
        }

        // Create validation function
        let validate: (Any) async throws -> ValidationService.ValidationResult = { data in
            var details: [String: Any] = [:]

            for condition in self.configuration.conditions {
                do {
                    let passed = try await condition.validate(data)
                    details[condition.name] = passed

                    if !passed {
                        return ValidationService.ValidationResult(
                            passed: false,
                            message: condition.errorMessage,
                            details: details
                        )
                    }
                } catch {
                    details[condition.name] = error.localizedDescription
                    throw error
                }
            }

            return ValidationService.ValidationResult(
                passed: true,
                message: "All conditions passed",
                details: details
            )
        }

        return ValidationService.ValidationRule(
            id: configuration.id,
            description: configuration.description,
            priority: configuration.priority,
            validate: validate
        )
    }

    // MARK: - Convenience Methods

    /// Create not nil validation
    /// - Parameters:
    ///   - keyPath: Key path to check
    ///   - name: Optional condition name
    /// - Returns: Builder instance
    @discardableResult
    public func notNil<T>(
        _ keyPath: KeyPath<T, Any?>,
        name: String? = nil
    ) -> ValidationRuleBuilder {
        let conditionName = name ?? "notNil"
        return withCondition(
            name: conditionName,
            errorMessage: "Value cannot be nil"
        ) { data in
            guard let value = data as? T else {
                return false
            }
            return value[keyPath: keyPath] != nil
        }
    }

    /// Create string validation
    /// - Parameters:
    ///   - keyPath: Key path to check
    ///   - minLength: Minimum length
    ///   - maxLength: Maximum length
    ///   - name: Optional condition name
    /// - Returns: Builder instance
    @discardableResult
    public func string<T>(
        _ keyPath: KeyPath<T, String>,
        minLength: Int = 0,
        maxLength: Int = .max,
        name: String? = nil
    ) -> ValidationRuleBuilder {
        let conditionName = name ?? "string"
        return withCondition(
            name: conditionName,
            errorMessage: "String length must be between \(minLength) and \(maxLength)"
        ) { data in
            guard let value = data as? T else {
                return false
            }
            let string = value[keyPath: keyPath]
            return string.count >= minLength && string.count <= maxLength
        }
    }

    /// Create number range validation
    /// - Parameters:
    ///   - keyPath: Key path to check
    ///   - min: Minimum value
    ///   - max: Maximum value
    ///   - name: Optional condition name
    /// - Returns: Builder instance
    @discardableResult
    public func numberRange<T, N: Comparable>(
        _ keyPath: KeyPath<T, N>,
        min: N,
        max: N,
        name: String? = nil
    ) -> ValidationRuleBuilder {
        let conditionName = name ?? "numberRange"
        return withCondition(
            name: conditionName,
            errorMessage: "Number must be between \(min) and \(max)"
        ) { data in
            guard let value = data as? T else {
                return false
            }
            let number = value[keyPath: keyPath]
            return number >= min && number <= max
        }
    }

    /// Create regex validation
    /// - Parameters:
    ///   - keyPath: Key path to check
    ///   - pattern: Regex pattern
    ///   - name: Optional condition name
    /// - Returns: Builder instance
    @discardableResult
    public func regex<T>(
        _ keyPath: KeyPath<T, String>,
        pattern: String,
        name: String? = nil
    ) -> ValidationRuleBuilder {
        let conditionName = name ?? "regex"
        return withCondition(
            name: conditionName,
            errorMessage: "String must match pattern: \(pattern)"
        ) { data in
            guard let value = data as? T else {
                return false
            }
            let string = value[keyPath: keyPath]
            return string.range(of: pattern, options: .regularExpression) != nil
        }
    }

    // MARK: Private

    /// Current configuration
    private var configuration: Configuration
}
