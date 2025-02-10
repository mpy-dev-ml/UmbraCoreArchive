import Foundation

/// Class representing the health status of a repository
///
/// This class encapsulates various health metrics and status information
/// about a Restic repository, including:
/// - Overall repository status
/// - Last check timestamp
/// - Error counts and messages
/// - Integrity checks for different components
///
/// Example usage:
/// ```swift
/// let health = RepositoryHealth(
///     status: "healthy",
///     lastCheck: Date(),
///     errorCount: 0,
///     errors: [],
///     sizeConsistent: true,
///     indexIntegrity: true,
///     packIntegrity: true
/// )
///
/// if health.status == "healthy" &&
///    health.errorCount == 0 &&
///    health.sizeConsistent {
///     logger.info(
///         """
///         Repository health check passed at \
///         \(health.lastCheck)
///         """
///     )
/// }
/// ```
@objc public class RepositoryHealth: NSObject, NSSecureCoding {
    // MARK: Lifecycle

    /// Initialize a new repository health status
    /// - Parameters:
    ///   - status: Overall repository status ("healthy", "warning", "error")
    ///   - lastCheck: Time when the health check was performed
    ///   - errorCount: Total number of errors found
    ///   - errors: Detailed error messages
    ///   - sizeConsistent: Whether pack file sizes are consistent
    ///   - indexIntegrity: Whether the repository index is valid
    ///   - packIntegrity: Whether all pack files are valid
    @objc public init(
        status: String,
        lastCheck: Date,
        errorCount: Int,
        errors: [String],
        sizeConsistent: Bool,
        indexIntegrity: Bool,
        packIntegrity: Bool
    ) {
        self.status = status
        self.lastCheck = lastCheck
        self.errorCount = errorCount
        self.errors = errors
        self.sizeConsistent = sizeConsistent
        self.indexIntegrity = indexIntegrity
        self.packIntegrity = packIntegrity
        super.init()
    }

    /// Decodes a health status from secure storage
    /// - Parameter coder: The coder to read from
    /// - Returns: A new RepositoryHealth instance, or nil if decoding fails
    @objc public required init?(coder: NSCoder) {
        guard
            let status = coder.decodeObject(
                of: NSString.self,
                forKey: "status"
            ) as String?,
            let lastCheck = coder.decodeObject(
                of: NSDate.self,
                forKey: "lastCheck"
            ) as Date?,
            let errors = coder.decodeObject(
                of: NSArray.self,
                forKey: "errors"
            ) as? [String]
        else {
            return nil
        }

        self.status = status
        self.lastCheck = lastCheck
        errorCount = coder.decodeInteger(forKey: "errorCount")
        self.errors = errors
        sizeConsistent = coder.decodeBool(forKey: "sizeConsistent")
        indexIntegrity = coder.decodeBool(forKey: "indexIntegrity")
        packIntegrity = coder.decodeBool(forKey: "packIntegrity")
        super.init()
    }

    // MARK: Public

    // MARK: - NSSecureCoding

    /// Indicates support for secure coding
    public static var supportsSecureCoding: Bool { true }

    /// Status of the repository
    ///
    /// Common values include:
    /// - "healthy": No issues detected
    /// - "warning": Minor issues found
    /// - "error": Serious problems detected
    @objc public let status: String

    /// Last check timestamp
    ///
    /// Records when the repository health check was last performed
    @objc public let lastCheck: Date

    /// Number of errors found
    ///
    /// Total count of errors detected during health check
    @objc public let errorCount: Int

    /// Error messages if any
    ///
    /// Detailed descriptions of any errors encountered
    @objc public let errors: [String]

    /// Size consistency check result
    ///
    /// Indicates whether all pack files have consistent sizes
    @objc public let sizeConsistent: Bool

    /// Index integrity check result
    ///
    /// Indicates whether the repository index is valid
    @objc public let indexIntegrity: Bool

    /// Pack files integrity check result
    ///
    /// Indicates whether all pack files are valid
    @objc public let packIntegrity: Bool

    /// Encodes the health status for secure storage
    /// - Parameter coder: The coder to write to
    @objc public func encode(with coder: NSCoder) {
        coder.encode(status, forKey: "status")
        coder.encode(lastCheck, forKey: "lastCheck")
        coder.encode(errorCount, forKey: "errorCount")
        coder.encode(errors, forKey: "errors")
        coder.encode(sizeConsistent, forKey: "sizeConsistent")
        coder.encode(indexIntegrity, forKey: "indexIntegrity")
        coder.encode(packIntegrity, forKey: "packIntegrity")
    }
}
