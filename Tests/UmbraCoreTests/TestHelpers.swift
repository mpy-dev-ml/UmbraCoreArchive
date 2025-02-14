import Testing

@testable import UmbraCore

/// Test helper functions and utilities for UmbraCore tests
enum TestHelpers {
    /// Creates a temporary directory for testing
    /// - Returns: URL to the temporary directory
    static func createTemporaryDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(
            at: tempDir,
            withIntermediateDirectories: true
        )
        return tempDir
    }

    /// Removes a temporary directory
    /// - Parameter url: URL to the temporary directory
    static func removeTemporaryDirectory(_ url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
}

/// Convenience functions for test assertions
extension TestHelpers {
    /// Asserts that a throwing closure throws an error of the expected type
    /// - Parameters:
    ///   - expectedError: The type of error expected to be thrown
    ///   - closure: The closure that should throw the error
    static func assertThrows<T: Error>(
        _ expectedError: T.Type,
        closure: () throws -> Void
    ) throws {
        do {
            try closure()
            #expect(false, "Expected \(expectedError) to be thrown")
        } catch {
            #expect(error is T, "Expected error to be \(expectedError) but got \(type(of: error))")
        }
    }
}
