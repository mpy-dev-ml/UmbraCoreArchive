import CryptoKit
import Foundation

/// Manager for encryption operations
public final class EncryptionManager: Sendable {
    // MARK: - Properties

    /// Shared instance
    public static let shared = EncryptionManager()

    /// Whether AES-256 encryption is available
    public let isAESAvailable: Bool

    /// Whether ChaCha20 encryption is available
    public let isChaCha20Available: Bool

    // MARK: - Initialization

    private init() {
        // Check encryption availability
        if #available(macOS 11.0, *) {
            isAESAvailable = true
            isChaCha20Available = true
        } else {
            isAESAvailable = true
            isChaCha20Available = false
        }
    }
}
