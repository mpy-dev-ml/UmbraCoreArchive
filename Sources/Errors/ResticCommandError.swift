@preconcurrency import Foundation

/// Error thrown when a restic command fails
public final class ResticCommandError: Error, ResticErrorProtocol, @unchecked Sendable {
    // MARK: - Properties

    /// Command that failed
    public let command: String

    /// Arguments passed to the command
    public let arguments: [String]

    /// Exit code of the command
    public let exitCode: Int32

    /// Standard output of the command
    public let stdout: String?

    /// Standard error output of the command
    public let stderr: String?

    // MARK: - ResticErrorProtocol Conformance

    /// The output from the command
    public var output: String? {
        [stdout, stderr].compactMap(\.self).joined(separator: "\n").nilIfEmpty
    }

    /// A localized message describing what error occurred
    override public var localizedDescription: String {
        "Restic command '\(command)' failed with exit code \(exitCode)"
    }

    /// A localized message describing the reason for the failure
    override public var localizedFailureReason: String? {
        stderr ?? stdout
    }

    /// A localized message describing how to recover from the error
    override public var localizedRecoverySuggestion: String? {
        "Check the command output and arguments for errors, then try again"
    }

    /// The underlying error, if any
    public var underlyingError: Error? {
        nil
    }

    // MARK: - Initialization

    /// Initialize a restic command error
    /// - Parameters:
    ///   - command: Command that failed
    ///   - arguments: Arguments passed to the command
    ///   - exitCode: Exit code of the command
    ///   - stdout: Standard output of the command
    ///   - stderr: Standard error output of the command
    public init(
        command: String,
        arguments: [String],
        exitCode: Int32,
        stdout: String?,
        stderr: String?
    ) {
        self.command = command
        self.arguments = arguments
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr

        let domain = "dev.mpy.umbracore.restic.command"
        let code = Int(exitCode)
        let userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: String(format: "Restic command '%@' failed with exit code %d", command, exitCode),
            NSLocalizedFailureReasonErrorKey: stderr ?? stdout as Any,
            NSLocalizedRecoverySuggestionErrorKey:
                "Check the command output and arguments for errors, then try again",
            "command": command,
            "arguments": arguments,
            "exitCode": exitCode,
            "stdout": stdout as Any,
            "stderr": stderr as Any,
        ]

        super.init(domain: domain, code: code, userInfo: userInfo)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
