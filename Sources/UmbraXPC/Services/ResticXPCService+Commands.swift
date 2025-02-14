//
//  ResticXPCService+Commands.swift
//
//
import Foundation
import os.log

// MARK: - Constants

private extension ResticXPCService {
    /// Minimum required memory in bytes (512MB)
    static let minimumMemoryRequired: UInt64 = 512 * 1_024 * 1_024

    /// Minimum required disk space in bytes (1GB)
    static let minimumDiskSpaceRequired: Int64 = 1_024 * 1_024 * 1_024

    /// Cache directory name
    static let cacheDirName = "ResticCache"
}

// MARK: - Properties

extension ResticXPCService {
    /// Cache directory for Restic operations
    var cacheDirectory: URL {
        get throws {
            let fileManager = FileManager.default
            let cacheDir = try fileManager.url(
                for: .cachesDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let resticCacheDir = cacheDir.appendingPathComponent(Self.cacheDirName)

            if !fileManager.fileExists(atPath: resticCacheDir.path) {
                try fileManager.createDirectory(
                    at: resticCacheDir,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }

            return resticCacheDir
        }
    }
}

// MARK: - ResticServiceProtocol Implementation

@available(macOS 13.0, *)
public extension ResticXPCService {
    /// Initializes a new Restic repository at the specified URL
    /// - Parameter url: The URL where the repository should be initialized
    /// - Throws: ProcessError if the initialization fails
    func initializeRepository(at url: URL) async throws {
        let message = "Initializing repository at \(url.path)"
        logger.info(message, file: #file, function: #function, line: #line)

        // Initialize repository
        let command = XPCCommandConfig(
            command: "init",
            arguments: [],
            environment: [:],
            workingDirectory: url.path,
            bookmarks: [:],
            timeout: 30,
            auditSessionID: au_session_self()
        )
        _ = try await executeResticCommand(command)
    }

    /// Creates a backup from the source directory to the destination repository
    /// - Parameters:
    ///   - source: The URL of the directory to backup
    ///   - destination: The URL of the Restic repository
    /// - Throws: ProcessError if the backup operation fails
    func backup(from source: URL, to destination: URL) async throws {
        let message = "Backing up \(source.path) to \(destination.path)"
        logger.info(message, file: #file, function: #function, line: #line)

        let command = XPCCommandConfig(
            command: "backup",
            arguments: [source.path],
            environment: [:],
            workingDirectory: destination.path,
            bookmarks: [:],
            timeout: 3_600,
            auditSessionID: au_session_self()
        )
        let result = try await executeResticCommand(command)

        if !result.succeeded {
            let message = "Backup command failed with exit code: \(result.exitCode)"
            throw ProcessError.executionFailed(message)
        }
    }

    /// Lists all snapshots in the repository
    /// - Returns: An array of snapshot IDs
    /// - Throws: ProcessError if the list operation fails
    func listSnapshots() async throws -> [String] {
        let command = XPCCommandConfig(
            command: "snapshots",
            arguments: ["--json"],
            environment: [:],
            workingDirectory: "/",
            bookmarks: [:],
            timeout: 30,
            auditSessionID: au_session_self()
        )
        let result = try await executeResticCommand(command)

        // Parse JSON output to extract snapshot IDs
        return result.output
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
    }

    /// Restores data from a repository snapshot to a destination directory
    /// - Parameters:
    ///   - source: The URL of the Restic repository containing the snapshot
    ///   - destination: The URL where the data should be restored
    /// - Throws: ProcessError if the restore operation fails
    func restore(from source: URL, to destination: URL) async throws {
        let message = "Restoring from \(source.path) to \(destination.path)"
        logger.info(message, file: #file, function: #function, line: #line)

        let command = XPCCommandConfig(
            command: "restore",
            arguments: ["latest", "--target", destination.path],
            environment: [:],
            workingDirectory: source.path,
            bookmarks: [:],
            timeout: 3_600,
            auditSessionID: au_session_self()
        )
        let result = try await executeResticCommand(command)

        if !result.succeeded {
            let message = "Restore command failed with exit code: \(result.exitCode)"
            throw ProcessError.executionFailed(message)
        }
    }
}

private extension ResticXPCService {
    private func executeResticCommand(_ command: XPCCommandConfig) async throws -> ProcessResult {
        try await validateCommandPrerequisites(command)
        let preparedCommand = try await prepareCommand(command)
        return try await executeCommand(preparedCommand)
    }

    private func validateCommandPrerequisites(_ command: XPCCommandConfig) async throws {
        // Check connection state
        guard connectionState == .connected else {
            let message = "Service is not connected"
            throw ResticXPCError.serviceUnavailable(message)
        }

        // Validate command parameters
        try validateCommandParameters(command)

        // Check resource availability
        guard try await checkResourceAvailability(for: command) else {
            let message = "Required resources are not available"
            throw ResticXPCError.resourceUnavailable(message)
        }
    }

    private func validateCommandParameters(_ command: XPCCommandConfig) throws {
        // Validate required parameters
        guard !command.command.isEmpty else {
            let message = "Command cannot be empty"
            throw ResticXPCError.invalidArguments(message)
        }

        // Check for unsafe arguments
        let unsafeArguments = ["--no-cache", "--no-lock", "--force"]
        let hasUnsafeArgs = command.arguments.contains {
            unsafeArguments.contains($0)
        }
        guard !hasUnsafeArgs else {
            let message = "Command contains unsafe arguments"
            throw ResticXPCError.unsafeArguments(message)
        }

        // Validate environment variables
        try validateEnvironmentVariables(command.environment)
    }

    private func validateEnvironmentVariables(_ environment: [String: String]) throws {
        let requiredVariables = ["RESTIC_PASSWORD", "RESTIC_REPOSITORY"]
        for variable in requiredVariables {
            guard environment[variable] != nil else {
                let message = "Missing required environment variable: \(variable)"
                throw ResticXPCError.missingEnvironment(message)
            }
        }
    }

    private func checkResourceAvailability(for command: XPCCommandConfig) async throws -> Bool {
        // Check system resources
        let resources = try await systemMonitor.checkResources()
        guard resources.memoryAvailable > Self.minimumMemoryRequired else {
            logger.error("Insufficient memory available")
            return false
        }

        // Check disk space
        guard try await checkDiskSpace(for: command) else {
            logger.error("Insufficient disk space")
            return false
        }

        return true
    }

    private func checkDiskSpace(for command: XPCCommandConfig) async throws -> Bool {
        // Get repository path
        guard let repoPath = command.environment["RESTIC_REPOSITORY"] else {
            return false
        }

        // Check available space
        let url = URL(fileURLWithPath: repoPath)
        let availableSpace = try await fileManager.availableSpace(at: url)
        return availableSpace > Self.minimumDiskSpaceRequired
    }

    private func prepareCommand(_ command: XPCCommandConfig) async throws -> PreparedCommand {
        // Build command arguments
        var arguments = command.arguments
        arguments.insert(contentsOf: ["--json", "--quiet"], at: 0)

        // Add default environment variables
        var environment = command.environment
        environment["RESTIC_PROGRESS_FPS"] = "1"
        environment["RESTIC_CACHE_DIR"] = try cacheDirectory.path

        return PreparedCommand(
            command: "restic",
            arguments: arguments,
            environment: environment,
            workingDirectory: command.workingDirectory
        )
    }

    private func executeCommand(_ command: PreparedCommand) async throws -> ProcessResult {
        let operationID = UUID()

        // Start progress tracking
        progressTracker.startOperation(operationID)

        do {
            // Execute command
            let process = try await processExecutor.execute(
                command: command.command,
                arguments: command.arguments,
                environment: command.environment,
                workingDirectory: command.workingDirectory
            )

            // Update progress
            progressTracker.updateProgress(operationID, progress: 1.0)

            return process
        } catch {
            // Handle execution error
            progressTracker.failOperation(operationID, error: error)
            let errorDesc = error.localizedDescription
            let message = "Command execution failed: \(errorDesc)"
            throw ResticXPCError.executionFailed(message)
        }
    }
}
