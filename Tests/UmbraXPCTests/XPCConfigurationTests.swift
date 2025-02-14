@testable import UmbraCore
import XCTest

final class XPCConfigurationTests: XCTestCase {
    // MARK: - Properties

    private var configuration: XPCConfiguration!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        configuration = XPCConfiguration(
            serviceName: "dev.mpy.umbra.test-service",
            interfaceProtocol: XPCServiceProtocol.self,
            securityLevel: .enhanced,
            connectionMode: .single
        )
    }

    override func tearDown() {
        configuration = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testDefaultInitialization() {
        XCTAssertEqual(configuration.serviceName, "dev.mpy.umbra.test-service")
        XCTAssertEqual(configuration.securityLevel, .enhanced)
        XCTAssertEqual(configuration.connectionMode, .single)
        XCTAssertTrue(configuration.validateAuditSession)
        XCTAssertEqual(configuration.connectionTimeout, 30.0)
        XCTAssertTrue(configuration.autoReconnect)
        XCTAssertEqual(configuration.maxRetryAttempts, 3)
        XCTAssertEqual(configuration.retryDelay, 1.0)
        XCTAssertEqual(configuration.maxConcurrentOperations, 10)
        XCTAssertEqual(configuration.operationTimeout, 60.0)
    }

    func testCustomInitialization() {
        let custom = XPCConfiguration(
            serviceName: "custom-service",
            interfaceProtocol: XPCServiceProtocol.self,
            securityLevel: .maximum,
            connectionMode: .pool,
            validateAuditSession: false,
            connectionTimeout: 15.0,
            autoReconnect: false,
            maxRetryAttempts: 5,
            retryDelay: 2.0,
            maxConcurrentOperations: 20,
            operationTimeout: 30.0
        )

        XCTAssertEqual(custom.serviceName, "custom-service")
        XCTAssertEqual(custom.securityLevel, .maximum)
        XCTAssertEqual(custom.connectionMode, .pool)
        XCTAssertFalse(custom.validateAuditSession)
        XCTAssertEqual(custom.connectionTimeout, 15.0)
        XCTAssertFalse(custom.autoReconnect)
        XCTAssertEqual(custom.maxRetryAttempts, 5)
        XCTAssertEqual(custom.retryDelay, 2.0)
        XCTAssertEqual(custom.maxConcurrentOperations, 20)
        XCTAssertEqual(custom.operationTimeout, 30.0)
    }

    // MARK: - Validation Tests

    func testValidConfiguration() {
        XCTAssertNoThrow(try configuration.validate())
    }

    func testEmptyServiceNameValidation() {
        let invalid = XPCConfiguration(
            serviceName: "",
            interfaceProtocol: XPCServiceProtocol.self
        )

        XCTAssertThrowsError(try invalid.validate()) { error in
            guard case let XPCServiceError.invalidConfiguration(reason) = error else {
                XCTFail("Expected XPCServiceError.invalidConfiguration")
                return
            }
            XCTAssertEqual(reason, "Service name cannot be empty")
        }
    }

    func testInvalidTimeoutValidation() {
        let invalid = XPCConfiguration(
            serviceName: "test",
            interfaceProtocol: XPCServiceProtocol.self,
            connectionTimeout: -1
        )

        XCTAssertThrowsError(try invalid.validate()) { error in
            guard case let XPCServiceError.invalidConfiguration(reason) = error else {
                XCTFail("Expected XPCServiceError.invalidConfiguration")
                return
            }
            XCTAssertEqual(reason, "Connection timeout must be positive")
        }
    }

    func testInvalidRetrySettingsValidation() {
        let invalid = XPCConfiguration(
            serviceName: "test",
            interfaceProtocol: XPCServiceProtocol.self,
            maxRetryAttempts: -1
        )

        XCTAssertThrowsError(try invalid.validate()) { error in
            guard case let XPCServiceError.invalidConfiguration(reason) = error else {
                XCTFail("Expected XPCServiceError.invalidConfiguration")
                return
            }
            XCTAssertEqual(reason, "Max retry attempts cannot be negative")
        }
    }

    // MARK: - Resource Limits Tests

    func testDefaultResourceLimits() {
        let limits = XPCConfiguration.ResourceLimits.default
        XCTAssertEqual(limits.maxMemoryBytes, 512 * 1024 * 1024)
        XCTAssertEqual(limits.maxCPUPercentage, 50.0)
        XCTAssertEqual(limits.maxFileDescriptors, 100)
        XCTAssertEqual(limits.maxDiskBytes, 1024 * 1024 * 1024)
    }

    func testCustomResourceLimits() {
        let limits = XPCConfiguration.ResourceLimits(
            maxMemoryBytes: 1024 * 1024 * 1024,
            maxCPUPercentage: 75.0,
            maxFileDescriptors: 200,
            maxDiskBytes: 2 * 1024 * 1024 * 1024
        )

        XCTAssertEqual(limits.maxMemoryBytes, 1024 * 1024 * 1024)
        XCTAssertEqual(limits.maxCPUPercentage, 75.0)
        XCTAssertEqual(limits.maxFileDescriptors, 200)
        XCTAssertEqual(limits.maxDiskBytes, 2 * 1024 * 1024 * 1024)
    }

    func testInvalidResourceLimitsValidation() {
        let invalid = XPCConfiguration(
            serviceName: "test",
            interfaceProtocol: XPCServiceProtocol.self,
            resourceLimits: .init(
                maxMemoryBytes: 1024,
                maxCPUPercentage: 150.0,
                maxFileDescriptors: 0,
                maxDiskBytes: 1024
            )
        )

        XCTAssertThrowsError(try invalid.validate()) { error in
            guard case let XPCServiceError.invalidConfiguration(reason) = error else {
                XCTFail("Expected XPCServiceError.invalidConfiguration")
                return
            }
            XCTAssertEqual(reason, "CPU percentage must be between 0 and 100")
        }
    }
}
