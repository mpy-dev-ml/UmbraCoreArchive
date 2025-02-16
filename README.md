# UmbraCore

A Swift library that extends and adapts [Restic](https://restic.net) for macOS application developers. UmbraCore provides a type-safe, Swift-native interface to Restic's powerful backup capabilities.

## Core Applications
UmbraCore powers several macOS backup management tools:
- ResticBar (macOS menu bar app)
- Rbx (VS Code extension)
- Rbum (consumer GUI)

## Requirements
- macOS 14.0+
- Xcode 15.0+
- Swift 5.9.2+

## Overview

UmbraCore is designed to work alongside Restic, providing Swift developers with a native interface to Restic's robust backup functionality. It does not replace or modify Restic itself, but rather provides a Swift-friendly layer for integrating Restic's capabilities into macOS applications.

This library serves as the foundation for macOS Restic-based applications while maintaining strict separation from UI and platform-specific concerns.

## Features

- **Restic CLI Integration**: Type-safe wrapper around Restic commands
- **Repository Management**: Secure handling of Restic repositories
- **Snapshot Management**: Swift-native interface to Restic snapshots
- **Configuration**: Thread-safe configuration for Restic operations
- **Autocompletion**: Dynamic command completion for Restic commands
- **Error Handling**: Swift-native error handling with recovery suggestions
- **Logging**: Privacy-aware, structured logging of Restic operations

## Installation

### Swift Package Manager

Add UmbraCore as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/mpy-dev-ml/UmbraCore.git", from: "1.0.0")
]
```

### Restic Installation

Restic must be installed separately. We recommend using Homebrew:
```bash
brew install restic
```

For other installation methods, please refer to the [official Restic documentation](https://restic.readthedocs.io/en/latest/020_installation.html).

## Module Structure

```
UmbraCore/
├── ResticCLIHelper/  # Swift interface to Restic commands
├── Repositories/     # Repository management
├── Snapshots/       # Snapshot operations
├── Config/          # Configuration handling
├── Logging/         # Structured logging
├── ErrorHandling/   # Error types and reporting
└── Autocomplete/    # Command completion
```

## Usage

### Basic Example

```swift
import ResticCLIHelper
import Repositories
import ErrorHandling

// Create a repository
let manager = try await RepositoryManager()
try await manager.initializeRepository(at: repositoryURL, password: "secure-password")

// Create a backup using Restic
let backup = try await manager.backup(
    paths: ["/path/to/backup"],
    tags: ["documents", "important"]
)

// List snapshots from Restic
let snapshots = try await manager.listSnapshots(
    matching: .init(tags: ["documents"])
)
```

### Error Handling

```swift
do {
    try await manager.backup(paths: ["/path/to/backup"])
} catch let error as RepositoryError {
    // Handle repository-specific errors
    logger.error("Repository error: \(error.localizedDescription)")
} catch {
    // Handle other errors
    logger.error("Unexpected error: \(error.localizedDescription)")
}
```

## Best Practices

1. **Restic Integration**
   - Always check Restic is installed
   - Handle Restic version compatibility
   - Respect Restic's locking mechanism
   - Follow Restic's security model

2. **Concurrency**
   - Use structured concurrency with async/await
   - Respect actor isolation
   - Handle task cancellation

3. **Error Handling**
   - Use specific error types
   - Include context in errors
   - Handle all error cases

4. **Security**
   - Secure credential storage
   - Handle sensitive data appropriately
   - Validate user input

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Acknowledgements

UmbraCore is built upon the excellent work of the Restic project. We are grateful to Alexander Neumann and all Restic contributors for creating such a robust and reliable backup tool.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Related Projects

- [ResticBar](https://github.com/mpy-dev-ml/ResticBar) - macOS menu bar application
- [Rbum](https://github.com/mpy-dev-ml/Rbum) - macOS Restic backup manager
- [Rbx](https://github.com/mpy-dev-ml/Rbx) - VS Code extension

## Support Restic

If you find UmbraCore useful, please consider [supporting the Restic project](https://github.com/sponsors/fd0).
