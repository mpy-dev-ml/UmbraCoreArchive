import Foundation

// MARK: - XPCConfiguration

/// Configuration for XPC service setup and behaviour
@frozen
@Observable
public struct XPCConfiguration: Sendable, Codable, Equatable {
    // MARK: - Types

    /// Security level for XPC connection
    @frozen
    public enum SecurityLevel: String, Codable, Sendable, CaseIterable {
        /// Basic security with default settings
        case basic
        /// Enhanced security with additional validations
        case enhanced
        /// Maximum security with all validations enabled
        case maximum

        /// Whether audit session validation is required
        public var requiresAuditSession: Bool {
            switch self {
            case .basic:
                false

            case .enhanced, .maximum:
                true
            }
        }

        /// Default timeout for this security level
        public var defaultTimeout: TimeInterval {
            switch self {
            case .basic:
                30.0

            case .enhanced:
                60.0

            case .maximum:
                120.0
            }
        }
    }

    /// Connection mode for XPC service
    @frozen
    public enum ConnectionMode: String, Codable, Sendable, CaseIterable {
        /// Single connection mode
        case single
        /// Multiple connections allowed
        case multiple
        /// Pool of connections
        case pool

        /// Maximum concurrent operations for this mode
        public var maxConcurrentOperations: Int {
            switch self {
            case .single:
                1

            case .multiple:
                5

            case .pool:
                10
            }
        }

        /// Whether reconnection is supported
        public var supportsReconnection: Bool {
            switch self {
            case .single:
                true

            case .multiple, .pool:
                false
            }
        }
    }

    // MARK: - Properties

    /// Service name for XPC connection
    public let serviceName: String

    /// Interface protocol
    @CodingKey(stringValue: "interfaceProtocolName")
    private let _interfaceProtocolName: String

    /// Interface protocol
    public var interfaceProtocol: Protocol {
        get {
            NSProtocolFromString(_interfaceProtocolName) ?? XPCServiceProtocol.self
        }
        set {
            _interfaceProtocolName = NSStringFromProtocol(newValue)
        }
    }

    /// Security level for connection
    public let securityLevel: SecurityLevel

    /// Connection mode
    public let connectionMode: ConnectionMode

    /// Whether to validate audit session
    public let validateAuditSession: Bool

    /// Connection timeout in seconds
    public let connectionTimeout: TimeInterval

    /// Whether to automatically reconnect
    public let autoReconnect: Bool

    /// Maximum retry attempts
    public let maxRetryAttempts: Int

    /// Delay between retry attempts in seconds
    public let retryDelay: TimeInterval

    /// Maximum concurrent operations
    public let maxConcurrentOperations: Int

    /// Operation timeout in seconds
    public let operationTimeout: TimeInterval

    /// Resource limits
    public let resourceLimits: ResourceLimits

    // MARK: - Computed Properties

    /// Whether the configuration is valid
    public var isValid: Bool {
        do {
            try validate()
            return true
        } catch {
            return false
        }
    }

    /// Whether reconnection is allowed
    public var allowsReconnection: Bool {
        autoReconnect && connectionMode.supportsReconnection
    }

    /// Effective timeout for operations
    public var effectiveTimeout: TimeInterval {
        min(operationTimeout, securityLevel.defaultTimeout)
    }

    // MARK: - Initialization

    /// Initialize with custom configuration
    /// - Parameters:
    ///   - serviceName: Name of the XPC service
    ///   - interfaceProtocol: Protocol for XPC interface
    ///   - securityLevel: Security level for connection
    ///   - connectionMode: Connection mode
    ///   - validateAuditSession: Whether to validate audit session
    ///   - connectionTimeout: Connection timeout in seconds
    ///   - autoReconnect: Whether to automatically reconnect
    ///   - maxRetryAttempts: Maximum retry attempts
    ///   - retryDelay: Delay between retry attempts in seconds
    ///   - maxConcurrentOperations: Maximum concurrent operations
    ///   - operationTimeout: Operation timeout in seconds
    ///   - resourceLimits: Resource limits
    public init(
        serviceName: String,
        interfaceProtocol: Protocol,
        securityLevel: SecurityLevel = .enhanced,
        connectionMode: ConnectionMode = .single,
        validateAuditSession: Bool? = nil,
        connectionTimeout: TimeInterval? = nil,
        autoReconnect: Bool = true,
        maxRetryAttempts: Int = 3,
        retryDelay: TimeInterval = 1.0,
        maxConcurrentOperations: Int? = nil,
        operationTimeout: TimeInterval? = nil,
        resourceLimits: ResourceLimits = .default
    ) {
        self.serviceName = serviceName
        self._interfaceProtocolName = NSStringFromProtocol(interfaceProtocol)
        self.securityLevel = securityLevel
        self.connectionMode = connectionMode
        self.validateAuditSession = validateAuditSession ?? securityLevel.requiresAuditSession
        self.connectionTimeout = connectionTimeout ?? securityLevel.defaultTimeout
        self.autoReconnect = autoReconnect
        self.maxRetryAttempts = maxRetryAttempts
        self.retryDelay = retryDelay
        self.maxConcurrentOperations = maxConcurrentOperations ?? connectionMode.maxConcurrentOperations
        self.operationTimeout = operationTimeout ?? securityLevel.defaultTimeout
        self.resourceLimits = resourceLimits
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case serviceName
        case _interfaceProtocolName = "interfaceProtocolName"
        case securityLevel
        case connectionMode
        case validateAuditSession
        case connectionTimeout
        case autoReconnect
        case maxRetryAttempts
        case retryDelay
        case maxConcurrentOperations
        case operationTimeout
        case resourceLimits
    }

    // MARK: - Computed Properties

    /// Whether the configuration is valid
    public var isValid: Bool {
        do {
            try validate()
            return true
        } catch {
            return false
        }
    }

    /// Whether reconnection is allowed
    public var allowsReconnection: Bool {
        autoReconnect && connectionMode.supportsReconnection
    }

    /// Effective timeout for operations
    public var effectiveTimeout: TimeInterval {
        min(operationTimeout, securityLevel.defaultTimeout)
    }

    // MARK: - ResourceLimits

    public struct ResourceLimits: Sendable, Codable, Equatable {
        // MARK: - Properties

        /// Maximum memory usage in bytes
        public let maxMemoryBytes: UInt64

        /// Maximum CPU usage percentage (0-100)
        public let maxCPUPercentage: Double

        /// Maximum file descriptors
        public let maxFileDescriptors: Int

        /// Maximum disk usage in bytes
        public let maxDiskBytes: UInt64

        /// Default resource limits
        public static let `default` = Self(
            maxMemoryBytes: 512 * 1_024 * 1_024, // 512MB
            maxCPUPercentage: 50.0,
            maxFileDescriptors: 100,
            maxDiskBytes: 1_024 * 1_024 * 1_024 // 1GB
        )

        /// Minimal resource limits
        public static let minimal = Self(
            maxMemoryBytes: 64 * 1_024 * 1_024, // 64MB
            maxCPUPercentage: 25.0,
            maxFileDescriptors: 50,
            maxDiskBytes: 256 * 1_024 * 1_024 // 256MB
        )

        /// Maximum resource limits
        public static let maximum = Self(
            maxMemoryBytes: 2_048 * 1_024 * 1_024, // 2GB
            maxCPUPercentage: 100.0,
            maxFileDescriptors: 1_000,
            maxDiskBytes: 4_096 * 1_024 * 1_024 // 4GB
        )

        // MARK: - Computed Properties

        /// Whether the limits are within acceptable ranges
        public var isValid: Bool {
            maxMemoryBytes > 0 &&
                maxCPUPercentage >= 0 && maxCPUPercentage <= 100 &&
                maxFileDescriptors > 0 &&
                maxDiskBytes > 0
        }

        /// Memory usage in megabytes
        public var maxMemoryMB: Double {
            Double(maxMemoryBytes) / (1_024 * 1_024)
        }

        /// Disk usage in gigabytes
        public var maxDiskGB: Double {
            Double(maxDiskBytes) / (1_024 * 1_024 * 1_024)
        }

        // MARK: - Initialization

        /// Initialize with custom limits
        /// - Parameters:
        ///   - maxMemoryBytes: Maximum memory usage in bytes
        ///   - maxCPUPercentage: Maximum CPU usage percentage
        ///   - maxFileDescriptors: Maximum file descriptors
        ///   - maxDiskBytes: Maximum disk usage in bytes
        public init(
            maxMemoryBytes: UInt64,
            maxCPUPercentage: Double,
            maxFileDescriptors: Int,
            maxDiskBytes: UInt64
        ) {
            self.maxMemoryBytes = maxMemoryBytes
            self.maxCPUPercentage = maxCPUPercentage
            self.maxFileDescriptors = maxFileDescriptors
            self.maxDiskBytes = maxDiskBytes
        }
    }

    // MARK: - Validation

    public enum ValidationError: LocalizedError {
        @ErrorCase("Invalid service name: {reason}")
        case invalidServiceName(reason: String)

        @ErrorCase("Invalid timeout: {reason}")
        case invalidTimeout(reason: String)

        @ErrorCase("Invalid retry settings: {reason}")
        case invalidRetrySettings(reason: String)

        @ErrorCase("Invalid operation settings: {reason}")
        case invalidOperationSettings(reason: String)

        @ErrorCase("Invalid resource limits: {reason}")
        case invalidResourceLimits(reason: String)

        public var errorDescription: String? {
            switch self {
            case let .invalidServiceName(reason),
                 let .invalidTimeout(reason),
                 let .invalidRetrySettings(reason),
                 let .invalidOperationSettings(reason),
                 let .invalidResourceLimits(reason):
                reason
            }
        }
    }

    /// Validate configuration
    /// - Throws: ValidationError if validation fails
    func validate() throws {
        // Validate service name
        guard !serviceName.isEmpty else {
            throw ValidationError.invalidServiceName(reason: "Service name cannot be empty")
        }

        // Validate timeouts
        guard connectionTimeout > 0 else {
            throw ValidationError.invalidTimeout(reason: "Connection timeout must be positive")
        }

        guard operationTimeout > 0 else {
            throw ValidationError.invalidTimeout(reason: "Operation timeout must be positive")
        }

        // Validate retry settings
        guard maxRetryAttempts >= 0 else {
            throw ValidationError.invalidRetrySettings(reason: "Max retry attempts cannot be negative")
        }

        guard retryDelay >= 0 else {
            throw ValidationError.invalidRetrySettings(reason: "Retry delay cannot be negative")
        }

        // Validate operation limits
        guard maxConcurrentOperations > 0 else {
            throw ValidationError.invalidOperationSettings(reason: "Max concurrent operations must be positive")
        }

        // Validate resource limits
        guard resourceLimits.maxCPUPercentage >= 0, resourceLimits.maxCPUPercentage <= 100 else {
            throw ValidationError.invalidResourceLimits(reason: "CPU percentage must be between 0 and 100")
        }

        guard resourceLimits.maxFileDescriptors > 0 else {
            throw ValidationError.invalidResourceLimits(reason: "Max file descriptors must be positive")
        }
    }
}

// MARK: - CustomStringConvertible

extension XPCConfiguration: CustomStringConvertible {
    public var description: String {
        """
        XPCConfiguration(
            serviceName: \(serviceName)
            securityLevel: \(securityLevel.rawValue)
            connectionMode: \(connectionMode.rawValue)
            validateAuditSession: \(validateAuditSession)
            connectionTimeout: \(connectionTimeout)s
            autoReconnect: \(autoReconnect)
            maxRetryAttempts: \(maxRetryAttempts)
            retryDelay: \(retryDelay)s
            maxConcurrentOperations: \(maxConcurrentOperations)
            operationTimeout: \(operationTimeout)s
            resourceLimits: {
                maxMemoryBytes: \(resourceLimits.maxMemoryBytes)
                maxCPUPercentage: \(resourceLimits.maxCPUPercentage)%
                maxFileDescriptors: \(resourceLimits.maxFileDescriptors)
                maxDiskBytes: \(resourceLimits.maxDiskBytes)
            }
            isValid: \(isValid)
            allowsReconnection: \(allowsReconnection)
            effectiveTimeout: \(effectiveTimeout)s
        )
        """
    }
}
