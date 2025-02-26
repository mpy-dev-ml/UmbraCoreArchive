import Foundation

/// A class representing a Restic backup repository
@objc
public class Repository: NSObject, NSSecureCoding {
    // MARK: Lifecycle

    /// Initialize a new repository
    @objc
    public init(
        id: String,
        url: URL,
        name: String,
        type: String,
        createdAt: Date,
        lastAccessed: Date,
        size: Int64,
        isActive: Bool
    ) {
        self.id = id
        self.url = url
        self.name = name
        self.type = type
        self.createdAt = createdAt
        self.lastAccessed = lastAccessed
        self.size = size
        self.isActive = isActive
        super.init()
    }

    @objc
    public required init?(coder: NSCoder) {
        guard let id = coder.decodeObject(of: NSString.self, forKey: "id") as String?,
              let url = coder.decodeObject(of: NSURL.self, forKey: "url") as URL?,
              let name = coder.decodeObject(of: NSString.self, forKey: "name") as String?,
              let type = coder.decodeObject(of: NSString.self, forKey: "type") as String?,
              let createdAt = coder.decodeObject(of: NSDate.self, forKey: "createdAt") as Date?,
              let lastAccessed = coder.decodeObject(
                  of: NSDate.self,
                  forKey: "lastAccessed"
              ) as Date?
        else {
            return nil
        }

        self.id = id
        self.url = url
        self.name = name
        self.type = type
        self.createdAt = createdAt
        self.lastAccessed = lastAccessed
        size = coder.decodeInt64(forKey: "size")
        isActive = coder.decodeBool(forKey: "isActive")
        super.init()
    }

    // MARK: Public

    public static var supportsSecureCoding: Bool { true }

    override public var description: String {
        String(
            format: "Repository(id: %@, name: %@, url: %@)",
            id as NSString,
            name as NSString,
            url as NSURL
        )
    }

    /// Unique identifier for the repository
    @objc public let id: String

    /// URL of the repository
    @objc public let url: URL

    /// Name of the repository
    @objc public let name: String

    /// Type of repository (local, SFTP, etc.)
    @objc public let type: String

    /// Date the repository was created
    @objc public let createdAt: Date

    /// Date the repository was last accessed
    @objc public let lastAccessed: Date

    /// Size of the repository in bytes
    @objc public let size: Int64

    /// Whether the repository is currently active
    @objc public let isActive: Bool

    // MARK: - NSSecureCoding

    @objc
    public func encode(with coder: NSCoder) {
        coder.encode(id, forKey: "id")
        coder.encode(url, forKey: "url")
        coder.encode(name, forKey: "name")
        coder.encode(type, forKey: "type")
        coder.encode(createdAt, forKey: "createdAt")
        coder.encode(lastAccessed, forKey: "lastAccessed")
        coder.encode(size, forKey: "size")
        coder.encode(isActive, forKey: "isActive")
    }
}
