@testable import UmbraCore
import XCTest

final class XPCServiceOperationTests: XCTestCase {
    // MARK: - Properties

    private var operation: XPCServiceOperation!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        operation = XPCServiceOperation(
            type: .command,
            path: "/usr/bin/test",
            arguments: ["--version"],
            environment: ["PATH": "/usr/bin"]
        )
    }

    override func tearDown() {
        operation = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testDefaultInitialization() {
        XCTAssertFalse(operation.identifier.isEmpty)
        XCTAssertEqual(operation.type, XPCServiceOperation.OperationType.command.rawValue)
        XCTAssertEqual(operation.path, "/usr/bin/test")
        XCTAssertEqual(operation.arguments, ["--version"])
        XCTAssertEqual(operation.environment, ["PATH": "/usr/bin"])
        XCTAssertNotNil(operation.timestamp)
    }

    func testCustomInitialization() {
        let custom = XPCServiceOperation(
            identifier: "custom-id",
            type: .fileRead,
            path: "/path/to/file",
            arguments: [],
            environment: [:]
        )

        XCTAssertEqual(custom.identifier, "custom-id")
        XCTAssertEqual(custom.type, XPCServiceOperation.OperationType.fileRead.rawValue)
        XCTAssertEqual(custom.path, "/path/to/file")
        XCTAssertTrue(custom.arguments.isEmpty)
        XCTAssertTrue(custom.environment.isEmpty)
        XCTAssertNotNil(custom.timestamp)
    }

    // MARK: - Coding Tests

    func testEncoding() {
        let data = try? NSKeyedArchiver.archivedData(
            withRootObject: operation,
            requiringSecureCoding: true
        )
        XCTAssertNotNil(data)
    }

    func testDecoding() {
        guard let data = try? NSKeyedArchiver.archivedData(
            withRootObject: operation,
            requiringSecureCoding: true
        ) else {
            XCTFail("Failed to archive operation")
            return
        }

        let decoded = try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: XPCServiceOperation.self,
            from: data
        )
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.identifier, operation.identifier)
        XCTAssertEqual(decoded?.type, operation.type)
        XCTAssertEqual(decoded?.path, operation.path)
        XCTAssertEqual(decoded?.arguments, operation.arguments)
        XCTAssertEqual(decoded?.environment, operation.environment)
    }

    // MARK: - Operation Type Tests

    func testCommandOperation() {
        let command = XPCServiceOperation(
            type: .command,
            path: "/usr/bin/ls",
            arguments: ["-la"]
        )
        XCTAssertEqual(command.type, XPCServiceOperation.OperationType.command.rawValue)
    }

    func testFileReadOperation() {
        let read = XPCServiceOperation(
            type: .fileRead,
            path: "/path/to/file"
        )
        XCTAssertEqual(read.type, XPCServiceOperation.OperationType.fileRead.rawValue)
    }

    func testFileWriteOperation() {
        let write = XPCServiceOperation(
            type: .fileWrite,
            path: "/path/to/file"
        )
        XCTAssertEqual(write.type, XPCServiceOperation.OperationType.fileWrite.rawValue)
    }

    func testSecurityOperation() {
        let security = XPCServiceOperation(
            type: .security,
            path: "/path/to/validate"
        )
        XCTAssertEqual(security.type, XPCServiceOperation.OperationType.security.rawValue)
    }

    func testResourceOperation() {
        let resource = XPCServiceOperation(
            type: .resource
        )
        XCTAssertEqual(resource.type, XPCServiceOperation.OperationType.resource.rawValue)
    }

    // MARK: - Sendable Tests

    func testSendableBehaviour() {
        let operation = operation!

        DispatchQueue.global().async {
            let copy = operation
            XCTAssertEqual(copy.identifier, operation.identifier)
            XCTAssertEqual(copy.type, operation.type)
            XCTAssertEqual(copy.path, operation.path)
            XCTAssertEqual(copy.arguments, operation.arguments)
            XCTAssertEqual(copy.environment, operation.environment)
        }
    }
}
