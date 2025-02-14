@preconcurrency import Foundation

/// Protocol defining process management functionality
public protocol ProcessServiceProtocol: LoggingServiceProtocol {
    /// Start a process with the given configuration
    /// - Parameter configuration: Process configuration
    /// - Returns: Process handle
    /// - Throws: Error if process start fails
    func startProcess(configuration: ProcessConfiguration) async throws -> ProcessHandle

    /// Stop a running process
    /// - Parameter handle: Process handle
    /// - Throws: Error if process stop fails
    func stopProcess(_ handle: ProcessHandle) async throws

    /// Get the status of a process
    /// - Parameter handle: Process handle
    /// - Returns: Process status
    /// - Throws: Error if status check fails
    func getProcessStatus(_ handle: ProcessHandle) async throws -> ProcessStatus
}

/// Configuration for starting a process
public struct ProcessConfiguration {
    /// Executable path
    public let executablePath: String

    /// Arguments to pass to the executable
    public let arguments: [String]

    /// Working directory for the process
    public let workingDirectory: String?

    /// Environment variables to set
    public let environment: [String: String]?

    /// Initialize a process configuration
    /// - Parameters:
    ///   - executablePath: Path to the executable
    ///   - arguments: Arguments to pass
    ///   - workingDirectory: Working directory
    ///   - environment: Environment variables
    public init(
        executablePath: String,
        arguments: [String] = [],
        workingDirectory: String? = nil,
        environment: [String: String]? = nil
    ) {
        self.executablePath = executablePath
        self.arguments = arguments
        self.workingDirectory = workingDirectory
        self.environment = environment
    }
}

/// Handle for a running process
public struct ProcessHandle: Hashable {
    /// Process identifier
    public let processId: Int32

    /// Initialize a process handle
    /// - Parameter processId: Process ID
    public init(processId: Int32) {
        self.processId = processId
    }
}

/// Status of a process
public enum ProcessStatus {
    /// Process is running
    case running
    /// Process has terminated
    case terminated(exitCode: Int32)
    /// Process state is unknown
    case unknown
}
