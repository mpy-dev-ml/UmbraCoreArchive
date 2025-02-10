# Development Services

Development implementations of core services for testing and development purposes.

## Overview

Located in `UmbraCore/Sources/UmbraCore/Services/Development`, these services provide controlled, in-memory implementations of core system services without requiring actual system access or security credentials. They are designed to facilitate rapid development and reliable testing.

## Available Services

### Security Service
`DevelopmentSecurityService` provides:
- Simulated security checks and validations
- Configurable access patterns for testing
- In-memory permission tracking
- Sandbox compliance verification
- Simulated XPC communication

### Bookmark Service
`DevelopmentBookmarkService` implements:
- Security-scoped bookmark simulation
- In-memory bookmark storage and retrieval
- Configurable staleness scenarios
- Access tracking and validation
- Performance metrics collection

## Implementation

### Service Configuration
Each service accepts a configuration object:
```swift
let config = ServiceFactory.DevelopmentConfiguration(
    shouldSimulatePermissionFailures: false,
    shouldSimulateBookmarkFailures: false,
    artificialDelay: 0.5
)
```

### Service Factory Integration
Development services are automatically used when:
```swift
ServiceFactory.configureDevelopment(
    simulatePermissionFailures: false,
    simulateBookmarkFailures: false,
    artificialDelay: 0.5
)
```

### Metrics and Monitoring
Development services include:
- Operation timing
- Resource usage tracking
- Access pattern analysis
- Error simulation and handling

### Testing Support
Development services facilitate:
- Unit testing without system dependencies
- Integration testing with controlled failures
- Performance testing with metrics
- Error handling verification

## Best Practices

1. Error Simulation
   - Use `simulatePermissionFailures` to test error handling
   - Use `simulateBookmarkFailures` for bookmark edge cases
   - Set `artificialDelay` to test timeout handling

2. Resource Management
   - Monitor resource usage with `ResourceMonitor`
   - Track performance with `PerformanceTracker`
   - Clean up resources after tests

3. Testing
   - Use development services in unit tests
   - Verify error handling paths
   - Test timeout scenarios
   - Validate resource cleanup

4. Debugging
   - Enable detailed logging
   - Monitor operation metrics
   - Track access patterns
   - Analyze performance data
