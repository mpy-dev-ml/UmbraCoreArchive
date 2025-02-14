@testable import UmbraCore
import XCTest

final class XPCServiceResultTests: XCTestCase {
    // MARK: - Properties

    private var result: XPCServiceResult!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        result = XPCServiceResult(
            identifier: "test-result",
            data: "test data".data(using: .utf8)!,
            status: .success
        )
    }

    override func tearDown() {
        result = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testDefaultInitialization() {
        XCTAssertEqual(result.identifier, "test-result")
        XCTAssertEqual(String(data: result.data, encoding: .utf8), "test data")
        XCTAssertNil(result.error)
        XCTAssertEqual(result.status, XPCServiceResult.Status.success.rawValue)
        XCTAssertNotNil(result.timestamp)
    }

    func testInitializationWithError() {
        let error = XPCServiceError.operationFailed(reason: "Test error")
        let result = XPCServiceResult(
            identifier: "error-result",
            data: Data(),
            error: error,
            status: .failure
        )

        XCTAssertEqual(result.identifier, "error-result")
        XCTAssertNotNil(result.error)
        XCTAssertEqual(result.status, XPCServiceResult.Status.failure.rawValue)
    }

    // MARK: - Status Tests

    func testSuccessStatus() {
        let success = XPCServiceResult(
            identifier: "success",
            data: Data(),
            status: .success
        )
        XCTAssertEqual(success.status, XPCServiceResult.Status.success.rawValue)
    }

    func testFailureStatus() {
        let failure = XPCServiceResult(
            identifier: "failure",
            data: Data(),
            error: XPCServiceError.operationFailed(reason: "Failed"),
            status: .failure
        )
        XCTAssertEqual(failure.status, XPCServiceResult.Status.failure.rawValue)
    }

    func testCancelledStatus() {
        let cancelled = XPCServiceResult(
            identifier: "cancelled",
            data: Data(),
            error: XPCServiceError.operationCancelled,
            status: .cancelled
        )
        XCTAssertEqual(cancelled.status, XPCServiceResult.Status.cancelled.rawValue)
    }

    // MARK: - Coding Tests

    func testEncoding() {
        let data = try? NSKeyedArchiver.archivedData(
            withRootObject: result,
            requiringSecureCoding: true
        )
        XCTAssertNotNil(data)
    }

    func testDecoding() {
        guard let data = try? NSKeyedArchiver.archivedData(
            withRootObject: result,
            requiringSecureCoding: true
        ) else {
            XCTFail("Failed to archive result")
            return
        }

        let decoded = try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: XPCServiceResult.self,
            from: data
        )
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.identifier, result.identifier)
        XCTAssertEqual(decoded?.data, result.data)
        XCTAssertEqual(decoded?.status, result.status)
    }

    func testDecodingWithError() {
        let errorResult = XPCServiceResult(
            identifier: "error",
            data: Data(),
            error: XPCServiceError.operationFailed(reason: "Test error"),
            status: .failure
        )

        guard let data = try? NSKeyedArchiver.archivedData(
            withRootObject: errorResult,
            requiringSecureCoding: true
        ) else {
            XCTFail("Failed to archive result")
            return
        }

        let decoded = try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: XPCServiceResult.self,
            from: data
        )
        XCTAssertNotNil(decoded)
        XCTAssertNotNil(decoded?.error)
        XCTAssertEqual(decoded?.status, XPCServiceResult.Status.failure.rawValue)
    }

    // MARK: - Sendable Tests

    func testSendableBehaviour() {
        let result = result!

        DispatchQueue.global().async {
            let copy = result
            XCTAssertEqual(copy.identifier, result.identifier)
            XCTAssertEqual(copy.data, result.data)
            XCTAssertEqual(copy.status, result.status)
        }
    }
}
