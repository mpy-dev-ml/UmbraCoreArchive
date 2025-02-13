@preconcurrency import Foundation

/// Protocol defining network service operations
public protocol NetworkServiceProtocol {
    /// Send network request
    /// - Parameter configuration: Request configuration
    /// - Returns: Network response
    /// - Throws: Error if request fails
    func sendRequest(_ configuration: RequestConfiguration) async throws -> Response

    /// Download file
    /// - Parameters:
    ///   - url: File URL
    ///   - destination: Destination URL
    /// - Returns: Download response
    /// - Throws: Error if download fails
    func downloadFile(from url: URL, to destination: URL) async throws -> Response

    /// Upload file
    /// - Parameters:
    ///   - url: File URL
    ///   - fileURL: URL of file to upload
    /// - Returns: Upload response
    /// - Throws: Error if upload fails
    func uploadFile(to url: URL, from fileURL: URL) async throws -> Response
}
