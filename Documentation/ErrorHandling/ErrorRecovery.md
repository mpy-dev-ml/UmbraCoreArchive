# Error Recovery Strategies

This guide outlines common error recovery strategies in UmbraCore.

## Table of Contents
1. [Overview](#overview)
2. [Common Recovery Patterns](#common-recovery-patterns)
3. [Service-Specific Strategies](#service-specific-strategies)
4. [Implementation Guide](#implementation-guide)

## Overview

Error recovery in UmbraCore follows these principles:
- Graceful degradation
- User-friendly recovery options
- Automatic recovery where safe
- Clear documentation of recovery steps

## Common Recovery Patterns

### 1. Retry Operations

```swift
func retryableOperation(maxAttempts: Int = 3) throws -> Result {
    var lastError: Error?
    
    for attempt in 1...maxAttempts {
        do {
            return try operation()
        } catch let error as RecoverableError {
            lastError = error
            logger.warning("Operation failed, attempt \(attempt)/\(maxAttempts)",
                         metadata: error.metadata)
            Thread.sleep(forTimeInterval: Double(attempt) * 2)
            continue
        }
    }
    
    throw lastError ?? SystemError.maxRetriesExceeded
}
```

### 2. Fallback Options

```swift
func operationWithFallback() throws -> Result {
    do {
        return try primaryOperation()
    } catch {
        logger.warning("Primary operation failed, trying fallback",
                      metadata: error.metadata)
        return try fallbackOperation()
    }
}
```

### 3. Resource Cleanup

```swift
func resourceOperation() throws -> Result {
    var resource: Resource?
    defer {
        resource?.cleanup()
    }
    
    do {
        resource = try acquireResource()
        return try useResource(resource)
    } catch {
        logger.error("Resource operation failed",
                    metadata: error.metadata)
        throw error
    }
}
```

## Service-Specific Strategies

### XPC Service Recovery

1. **Connection Issues**
   ```swift
   func handleXPCConnectionFailure(_ error: XPCError) {
       switch error {
       case .notConnected:
           reconnectXPCService()
       case .timeout:
           resetXPCConnection()
       case .invalidState:
           reinitializeXPCService()
       default:
           reportUnrecoverableError(error)
       }
   }
   ```

2. **Resource Constraints**
   ```swift
   func handleResourceConstraint(_ error: ResourceError) {
       switch error {
       case .memoryPressure:
           releaseMemoryPressure()
       case .diskSpace:
           cleanupTemporaryFiles()
       case .cpuUsage:
           throttleOperations()
       }
   }
   ```

### Security Service Recovery

1. **Authentication**
   ```swift
   func handleAuthenticationFailure(_ error: SecurityError) {
       switch error {
       case .invalidCredentials:
           refreshCredentials()
       case .tokenExpired:
           renewToken()
       case .sessionInvalid:
           initiateReauthentication()
       }
   }
   ```

2. **Permissions**
   ```swift
   func handlePermissionFailure(_ error: PermissionError) {
       switch error {
       case .insufficientPrivileges:
           requestElevatedPrivileges()
       case .resourceAccess:
           requestResourceAccess()
       case .sandboxViolation:
           updateSandboxConfiguration()
       }
   }
   ```

## Implementation Guide

### 1. Define Recovery Options

```swift
protocol RecoverableError: Error {
    var recoveryOptions: [RecoveryOption] { get }
    func attemptRecovery(option: RecoveryOption) -> Bool
}

enum RecoveryOption {
    case retry
    case useAlternative
    case reset
    case ignore
}
```

### 2. Implement Recovery Logic

```swift
extension ServiceError: RecoverableError {
    var recoveryOptions: [RecoveryOption] {
        switch self {
        case .connectionFailed:
            [.retry, .reset]
        case .resourceUnavailable:
            [.retry, .useAlternative]
        case .invalidState:
            [.reset, .ignore]
        default:
            []
        }
    }
    
    func attemptRecovery(option: RecoveryOption) -> Bool {
        switch (self, option) {
        case (.connectionFailed, .retry):
            return retryConnection()
        case (.connectionFailed, .reset):
            return resetConnection()
        case (.resourceUnavailable, .retry):
            return retryResourceAccess()
        case (.resourceUnavailable, .useAlternative):
            return useAlternativeResource()
        case (.invalidState, .reset):
            return resetState()
        default:
            return false
        }
    }
}
```

### 3. Use in Practice

```swift
func handleError(_ error: Error) {
    guard let recoverable = error as? RecoverableError,
          !recoverable.recoveryOptions.isEmpty else {
        reportUnrecoverableError(error)
        return
    }
    
    for option in recoverable.recoveryOptions {
        if recoverable.attemptRecovery(option: option) {
            logger.info("Recovery successful using option: \(option)")
            return
        }
    }
    
    logger.error("All recovery attempts failed", metadata: error.metadata)
    reportUnrecoverableError(error)
}
```

## Best Practices

1. **Always Log Recovery Attempts**
   ```swift
   func attemptRecovery(error: Error) {
       logger.info("Attempting recovery", metadata: [
           "error.type": .string(String(describing: type(of: error))),
           "recovery.attempt": .string("1"),
           "recovery.strategy": .string("retry")
       ])
   }
   ```

2. **Implement Graceful Degradation**
   ```swift
   func degradeGracefully() {
       disableNonEssentialFeatures()
       notifyUserOfLimitedFunctionality()
       continueCriticalOperations()
   }
   ```

3. **Handle Nested Errors**
   ```swift
   func handleNestedError(_ error: Error) {
       if let nested = error as? NestedError {
           handleError(nested.underlyingError)
       } else {
           handleError(error)
       }
   }
   ```

## Testing Recovery Strategies

```swift
func testRecoveryStrategy() {
    let error = ServiceError.connectionFailed
    
    XCTAssertTrue(error.recoveryOptions.contains(.retry))
    XCTAssertTrue(error.attemptRecovery(option: .retry))
    
    // Verify system state after recovery
    XCTAssertTrue(isSystemInValidState())
}
```
