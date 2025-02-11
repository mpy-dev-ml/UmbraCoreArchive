import Compression
import Foundation

/// Manager for compression operations
public final class CompressionManager: Sendable {
    // MARK: - Properties

    /// Shared instance
    public static let shared = CompressionManager()

    /// Whether LZMA compression is available
    public let isLZMAAvailable: Bool

    // MARK: - Initialization

    private init() {
        // Check LZMA availability by attempting to create an encoder
        isLZMAAvailable = (compression_stream_init(
            nil,
            COMPRESSION_STREAM_ENCODE,
            COMPRESSION_LZMA
        ) == COMPRESSION_STATUS_OK)
    }
}
