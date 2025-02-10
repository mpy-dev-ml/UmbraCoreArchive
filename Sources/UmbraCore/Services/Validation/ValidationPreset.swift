//
// ValidationPreset.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Preset validation rules
public enum ValidationPreset {
    // MARK: - Text Validation

    /// Create email validation rule
    /// - Parameter priority: Rule priority
    /// - Returns: Validation rule
    /// - Throws: ValidationError if build fails
    public static func email(
        priority: ValidationService.Priority = .normal
    ) throws -> ValidationService.ValidationRule {
        try ValidationRuleBuilder()
            .withId("email")
            .withDescription("Validate email format")
            .withPriority(priority)
            .withCondition(
                name: "emailFormat",
                errorMessage: "Invalid email format"
            ) { data in
                guard let email = data as? String else { return false }
                let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
                return email.range(of: pattern, options: .regularExpression) != nil
            }
            .build()
    }

    /// Create URL validation rule
    /// - Parameter priority: Rule priority
    /// - Returns: Validation rule
    /// - Throws: ValidationError if build fails
    public static func url(
        priority: ValidationService.Priority = .normal
    ) throws -> ValidationService.ValidationRule {
        try ValidationRuleBuilder()
            .withId("url")
            .withDescription("Validate URL format")
            .withPriority(priority)
            .withCondition(
                name: "urlFormat",
                errorMessage: "Invalid URL format"
            ) { data in
                guard let urlString = data as? String else { return false }
                return URL(string: urlString) != nil
            }
            .build()
    }

    /// Create phone number validation rule
    /// - Parameter priority: Rule priority
    /// - Returns: Validation rule
    /// - Throws: ValidationError if build fails
    public static func phoneNumber(
        priority: ValidationService.Priority = .normal
    ) throws -> ValidationService.ValidationRule {
        try ValidationRuleBuilder()
            .withId("phoneNumber")
            .withDescription("Validate phone number format")
            .withPriority(priority)
            .withCondition(
                name: "phoneFormat",
                errorMessage: "Invalid phone number format"
            ) { data in
                guard let phone = data as? String else { return false }
                let pattern = #"^\+?[1-9]\d{1,14}$"#
                return phone.range(of: pattern, options: .regularExpression) != nil
            }
            .build()
    }

    // MARK: - Number Validation

    /// Create range validation rule
    /// - Parameters:
    ///   - min: Minimum value
    ///   - max: Maximum value
    ///   - priority: Rule priority
    /// - Returns: Validation rule
    /// - Throws: ValidationError if build fails
    public static func range<T: Comparable>(
        min: T,
        max: T,
        priority: ValidationService.Priority = .normal
    ) throws -> ValidationService.ValidationRule {
        try ValidationRuleBuilder()
            .withId("range")
            .withDescription("Validate value range")
            .withPriority(priority)
            .withCondition(
                name: "rangeCheck",
                errorMessage: "Value must be between \(min) and \(max)"
            ) { data in
                guard let value = data as? T else { return false }
                return value >= min && value <= max
            }
            .build()
    }

    /// Create positive number validation rule
    /// - Parameter priority: Rule priority
    /// - Returns: Validation rule
    /// - Throws: ValidationError if build fails
    public static func positiveNumber(
        priority: ValidationService.Priority = .normal
    ) throws -> ValidationService.ValidationRule {
        try ValidationRuleBuilder()
            .withId("positiveNumber")
            .withDescription("Validate positive number")
            .withPriority(priority)
            .withCondition(
                name: "positiveCheck",
                errorMessage: "Value must be positive"
            ) { data in
                guard let number = data as? (any Numeric),
                      let comparable = number as? (any Comparable) else {
                    return false
                }
                return comparable > 0
            }
            .build()
    }

    // MARK: - Collection Validation

    /// Create non-empty collection validation rule
    /// - Parameter priority: Rule priority
    /// - Returns: Validation rule
    /// - Throws: ValidationError if build fails
    public static func nonEmptyCollection(
        priority: ValidationService.Priority = .normal
    ) throws -> ValidationService.ValidationRule {
        try ValidationRuleBuilder()
            .withId("nonEmptyCollection")
            .withDescription("Validate non-empty collection")
            .withPriority(priority)
            .withCondition(
                name: "nonEmptyCheck",
                errorMessage: "Collection must not be empty"
            ) { data in
                guard let collection = data as? any Collection else { return false }
                return !collection.isEmpty
            }
            .build()
    }

    /// Create collection size validation rule
    /// - Parameters:
    ///   - minSize: Minimum size
    ///   - maxSize: Maximum size
    ///   - priority: Rule priority
    /// - Returns: Validation rule
    /// - Throws: ValidationError if build fails
    public static func collectionSize(
        minSize: Int,
        maxSize: Int,
        priority: ValidationService.Priority = .normal
    ) throws -> ValidationService.ValidationRule {
        try ValidationRuleBuilder()
            .withId("collectionSize")
            .withDescription("Validate collection size")
            .withPriority(priority)
            .withCondition(
                name: "sizeCheck",
                errorMessage: "Collection size must be between \(minSize) and \(maxSize)"
            ) { data in
                guard let collection = data as? any Collection else { return false }
                return collection.count >= minSize && collection.count <= maxSize
            }
            .build()
    }

    // MARK: - Date Validation

    /// Create future date validation rule
    /// - Parameter priority: Rule priority
    /// - Returns: Validation rule
    /// - Throws: ValidationError if build fails
    public static func futureDate(
        priority: ValidationService.Priority = .normal
    ) throws -> ValidationService.ValidationRule {
        try ValidationRuleBuilder()
            .withId("futureDate")
            .withDescription("Validate future date")
            .withPriority(priority)
            .withCondition(
                name: "futureCheck",
                errorMessage: "Date must be in the future"
            ) { data in
                guard let date = data as? Date else { return false }
                return date > Date()
            }
            .build()
    }

    /// Create date range validation rule
    /// - Parameters:
    ///   - start: Start date
    ///   - end: End date
    ///   - priority: Rule priority
    /// - Returns: Validation rule
    /// - Throws: ValidationError if build fails
    public static func dateRange(
        start: Date,
        end: Date,
        priority: ValidationService.Priority = .normal
    ) throws -> ValidationService.ValidationRule {
        try ValidationRuleBuilder()
            .withId("dateRange")
            .withDescription("Validate date range")
            .withPriority(priority)
            .withCondition(
                name: "rangeCheck",
                errorMessage: "Date must be between \(start) and \(end)"
            ) { data in
                guard let date = data as? Date else { return false }
                return date >= start && date <= end
            }
            .build()
    }
}
