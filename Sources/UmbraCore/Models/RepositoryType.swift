@preconcurrency import Foundation

/// Type of repository
@frozen // Mark as frozen for better Swift 6 compatibility
@objc
public enum RepositoryType: Int, Sendable, CustomStringConvertible {
    /// Local repository on disk
    case local
    /// Remote repository over SFTP
    case sftp
    /// Remote repository over REST
    case rest
    /// Remote repository over S3
    case s3
    /// Remote repository over B2
    case b2
    /// Remote repository over Azure
    case azure
    /// Remote repository over Google Cloud Storage
    case gcs
    /// Remote repository over WebDAV
    case webdav
    /// Remote repository over rclone
    case rclone

    /// String representation of the repository type
    public var description: String {
        switch self {
        case .local: "Local"
        case .sftp: "SFTP"
        case .rest: "REST"
        case .s3: "S3"
        case .b2: "B2"
        case .azure: "Azure"
        case .gcs: "Google Cloud"
        case .webdav: "WebDAV"
        case .rclone: "Rclone"
        }
    }

    /// Protocol scheme for the repository type
    public var scheme: String {
        switch self {
        case .local: "file"
        case .sftp: "sftp"
        case .rest: "rest"
        case .s3: "s3"
        case .b2: "b2"
        case .azure: "azure"
        case .gcs: "gs"
        case .webdav: "webdav"
        case .rclone: "rclone"
        }
    }
}
