@preconcurrency import Foundation

/// Service for managing processes
public final class ProcessService: BaseSandboxedService {
    // MARK: Lifecycle

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

    // MARK: - Deinitializer

    deinit {
        terminateAllProcesses()
    }

    // MARK: Public

    // MARK: - Types

    /// Process configuration
    public struct Configuration {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            executableURL: URL,
            arguments: [String] = [],
            environment: [String: String]? = nil,
            workingDirectoryURL: URL? = nil,
            standardInput: Pipe? = nil,
            standardOutput: Pipe? = nil,
            standardError: Pipe? = nil
        ) {
            self.executableURL = executableURL
            self.arguments = arguments
            self.environment = environment
            self.workingDirectoryURL = workingDirectoryURL
            self.standardInput = standardInput
            self.standardOutput = standardOutput
            self.standardError = standardError
        }

        // MARK: Public

        /// Executable URL
        public let executableURL: URL

        /// Arguments
        public let arguments: [String]

        /// Environment variables
        public let environment: [String: String]?

        /// Working directory URL
        public let workingDirectoryURL: URL?

        /// Standard input pipe
        public let standardInput: Pipe?

        /// Standard output pipe
        public let standardOutput: Pipe?

        /// Standard error pipe
        public let standardError: Pipe?
    }

    /// Process result
    public struct Result {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            exitCode: Int32,
            standardOutput: Data,
            standardError: Data,
            duration: TimeInterval
        ) {
            self.exitCode = exitCode
            self.standardOutput = standardOutput
            self.standardError = standardError
            self.duration = duration
        }

        // MARK: Public

        /// Exit code
        public let exitCode: Int32

        /// Standard output data
        public let standardOutput: Data

        /// Standard error data
        public let standardError: Data

        /// Duration in seconds
        public let duration: TimeInterval
    }

    // MARK: - Public Methods

    /// Run process
    /// - Parameter configuration: Process configuration
    /// - Returns: Process result
    /// - Throws: Error if process fails
    @discardableResult
    public func runProcess(
        _ configuration: Configuration
    ) async throws -> Result {
        try validateUsable(for: "runProcess")

        return try await performanceMonitor.trackDuration(
            "process.run"
        ) {
            // Create process
            let process = Process()
            process.executableURL = configuration.executableURL
            process.arguments = configuration.arguments
            process.environment = configuration.environment
            process.currentDirectoryURL = configuration.workingDirectoryURL

            // Set up pipes
            let standardInput = configuration.standardInput ?? Pipe()
            let standardOutput = configuration.standardOutput ?? Pipe()
            let standardError = configuration.standardError ?? Pipe()

            process.standardInput = standardInput
            process.standardOutput = standardOutput
            process.standardError = standardError

            // Track process
            queue.async(flags: .barrier) {
                self.processes.append(process)
            }

            // Log process start
            logger.info(
                """
                Starting process:
                Executable: \(configuration.executableURL.path)
                Arguments: \(configuration.arguments)
                Working Directory: \(configuration.workingDirectoryURL?.path ?? "default")
                """,
                file: #file,
                function: #function,
                line: #line
            )

            // Run process
            let result = try await executeProcess(process, config: configuration)

            // Log process completion
            logger.info(
                """
                Process completed:
                Exit Code: \(result.exitCode)
                Duration: \(result.duration)s
                Output Size: \(result.standardOutput.count) bytes
                Error Size: \(result.standardError.count) bytes
                """,
                file: #file,
                function: #function,
                line: #line
            )

            // Remove process
            queue.async(flags: .barrier) {
                self.processes.removeAll { $0 === process }
            }

            return result
        }
    }

    /// Terminate all processes
    public func terminateAllProcesses() {
        queue.async(flags: .barrier) {
            for process in self.processes {
                process.terminate()
            }
            self.processes.removeAll()

            self.logger.debug(
                "Terminated all processes",
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Get active process count
    /// - Returns: Number of active processes
    public func getActiveProcessCount() -> Int {
        queue.sync { processes.count }
    }

    // MARK: Private

    /// Active processes
    private var processes: [Process] = []

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.process",
        qos: .userInitiated,
        attributes: .concurrent
    )

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    /// Execute process with configuration
    private func executeProcess(
        _ process: Process,
        config: Configuration
    ) async throws -> Result {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let result = try executeProcessSync(process, config: config)
                continuation.resume(returning: result)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Execute process synchronously
    private func executeProcessSync(
        _ process: Process,
        config _: Configuration
    ) throws -> Result {
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        let startTime = Date()
        process.launch()

        let outputData = try readProcessOutput(outputPipe)
        let errorData = try readProcessOutput(errorPipe)

        process.waitUntilExit()
        let duration = Date().timeIntervalSince(startTime)

        return try createProcessResult(
            process: process,
            outputData: outputData,
            errorData: errorData,
            duration: duration
        )
    }

    /// Read process output from pipe
    private func readProcessOutput(_ pipe: Pipe) throws -> Data {
        let handle = pipe.fileHandleForReading
        let data = handle.readDataToEndOfFile()
        try handle.close()
        return data
    }

    /// Create process result from execution data
    private func createProcessResult(
        process: Process,
        outputData: Data,
        errorData: Data,
        duration: TimeInterval
    ) throws -> Result {
        let output = String(
            data: outputData,
            encoding: .utf8
        ) ?? ""

        let error = String(
            data: errorData,
            encoding: .utf8
        ) ?? ""

        return Result(
            exitCode: Int(process.terminationStatus),
            standardOutput: outputData,
            standardError: errorData,
            duration: duration
        )
    }
}
