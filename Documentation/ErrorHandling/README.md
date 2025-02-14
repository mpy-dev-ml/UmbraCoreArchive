# UmbraCore Error Handling Guide

This guide outlines the error handling patterns and best practices used in UmbraCore.

## Table of Contents
1. [Error System Overview](#error-system-overview)
2. [Error Categories](#error-categories)
3. [Error Patterns](#error-patterns)
4. [Logging Integration](#logging-integration)
5. [Best Practices](#best-practices)
6. [Migration Guide](#migration-guide)

## Error System Overview

UmbraCore's error handling system is designed around these key principles:
- Strong type safety
- Comprehensive error information
- Consistent error patterns
- Integrated logging
- Recovery suggestions

### Key Components

1. **Errors Module**: Central location for all error types
2. **Error Categories**: Structured categorisation of errors
3. **Logging Integration**: Automatic error logging with metadata
4. **Recovery Handling**: Built-in recovery suggestions

## Error Categories

UmbraCore defines several error categories to help organize and handle different types of errors:

1. **Service Errors**
   - `ServiceDependencyError`
   - `ServiceStateError`
   - `ServiceOperationError`

2. **XPC Errors**
   - `XPCError`
   - `XPCServiceError`
   - `ResticXPCError`

3. **Resource Errors**
   - `ResourceError`
   - `PerformanceError`
   - `SystemError`

4. **Security Errors**
   - `SecurityError`
   - `EncryptionError`
   - `PermissionError`

5. **Data Errors**
   - `PersistenceError`
   - `CoreError`
   - `ProcessError`

## Error Patterns

### Standard Error Structure

All errors in UmbraCore should conform to this pattern:

```swift
public enum MyError: LocalizedError {
    // MARK: - Categories
    
    public enum Category: String {
        case validation = "Validation Error"
        case processing = "Processing Error"
        // ...
    }
    
    public enum Severity: String {
        case critical = "Critical"
        case error = "Error"
        case warning = "Warning"
        case info = "Info"
    }
    
    // MARK: - Cases
    
    case someError(reason: String)
    case anotherError(reason: String)
    
    // MARK: - Properties
    
    public var category: Category {
        // Return appropriate category
    }
    
    public var severity: Severity {
        // Return appropriate severity
    }
    
    // MARK: - LocalizedError
    
    public var errorDescription: String? {
        // Return localized description
    }
    
    public var failureReason: String? {
        // Return failure reason
    }
    
    public var recoverySuggestion: String? {
        // Return recovery suggestion
    }
}
```

### Error Metadata

Each error includes standard metadata for logging:

```swift
public var metadata: Logger.Metadata {
    [
        "error.category": .string(category.rawValue),
        "error.severity": .string(severity.rawValue),
        "error.type": .string(String(describing: type(of: self))),
        "error.description": .string(errorDescription ?? "Unknown"),
        "error.reason": .string(failureReason ?? "Unknown"),
        "error.recovery": .string(recoverySuggestion ?? "Unknown"),
        "error.timestamp": .string(ISO8601DateFormatter().string(from: Date())),
        "error.id": .string(UUID().uuidString)
    ]
}
```

## Logging Integration

Errors are automatically logged when thrown using the UmbraLogging system:

```swift
do {
    try someOperation()
} catch let error as LocalizedError {
    logger.error("Operation failed", metadata: error.metadata)
    throw error
}
```

## Best Practices

1. **Error Creation**
   - Use meaningful error cases
   - Include detailed reason strings
   - Set appropriate severity levels
   - Provide recovery suggestions

2. **Error Handling**
   - Handle errors at appropriate levels
   - Log errors with context
   - Provide user-friendly messages
   - Implement recovery where possible

3. **Error Documentation**
   - Document all error cases
   - Include example scenarios
   - Explain recovery steps
   - Document any side effects

4. **Testing**
   - Test error conditions
   - Verify error messages
   - Check recovery paths
   - Validate logging

## Migration Guide

### From Old Error System

1. Replace custom attributes:
   ```swift
   // Old
   @Error
   enum OldError {
       @ErrorCase("Something went wrong: {reason}")
       case someError(reason: String)
   }
   
   // New
   enum NewError: LocalizedError {
       case someError(reason: String)
       
       var errorDescription: String? {
           switch self {
           case let .someError(reason):
               "Something went wrong: \(reason)"
           }
       }
   }
   ```

2. Add standard metadata:
   ```swift
   extension NewError {
       var metadata: Logger.Metadata {
           // Standard metadata structure
       }
   }
   ```

3. Update error handling:
   ```swift
   // Old
   throw OldError.someError(reason: "failed")
   
   // New
   let error = NewError.someError(reason: "failed")
   logger.error("Operation failed", metadata: error.metadata)
   throw error
   ```

### Best Practices for New Code

1. Use the standard error pattern
2. Include comprehensive metadata
3. Integrate with logging system
4. Provide recovery suggestions
5. Document error cases

## Contributing

When adding new error types:

1. Follow the standard error pattern
2. Add appropriate categories and severities
3. Include comprehensive metadata
4. Write tests for error conditions
5. Update this documentation

## Questions and Support

For questions about error handling in UmbraCore:

1. Check this documentation
2. Review error type documentation
3. Look at example implementations
4. Contact the development team
