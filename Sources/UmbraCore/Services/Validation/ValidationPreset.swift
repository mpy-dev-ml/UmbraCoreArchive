@preconcurrency import Foundation

/// Preset validation patterns and rules
@frozen
public enum ValidationPreset {
    /// Email validation
    @Sendable
    public static let email = try! Regex(#"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"#)
    
    /// URL validation
    @Sendable
    public static let url = try! Regex(#"^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$"#)
    
    /// IPv4 address validation
    @Sendable
    public static let ipv4 = try! Regex(#"^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"#)
    
    /// IPv6 address validation
    @Sendable
    public static let ipv6 = try! Regex(#"^(?:(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,7}:|(?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,5}(?::[0-9a-fA-F]{1,4}){1,2}|(?:[0-9a-fA-F]{1,4}:){1,4}(?::[0-9a-fA-F]{1,4}){1,3}|(?:[0-9a-fA-F]{1,4}:){1,3}(?::[0-9a-fA-F]{1,4}){1,4}|(?:[0-9a-fA-F]{1,4}:){1,2}(?::[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:(?:(?::[0-9a-fA-F]{1,4}){1,6})|:(?:(?::[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(?::[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(?:ffff(?::0{1,4}){0,1}:){0,1}(?:(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9])|(?:[0-9a-fA-F]{1,4}:){1,4}:(?:(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$"#)
    
    /// Path validation
    @Sendable
    public static let path = try! Regex(#"^(?:[a-zA-Z]:)?(?:\/[^\/\0<>:"|?*]+)+\/?$"#)
    
    /// Validates if a string matches a given regex pattern
    /// - Parameters:
    ///   - string: String to validate
    ///   - pattern: Regex pattern to match against
    /// - Returns: True if the string matches the pattern
    public static func validate(_ string: String, with pattern: Regex<Substring>) -> Bool {
        string.wholeMatch(of: pattern) != nil
    }
    
    /// Validates if a string is a valid email address
    /// - Parameter email: Email address to validate
    /// - Returns: True if the email is valid
    public static func validateEmail(_ email: String) -> Bool {
        validate(email, with: self.email)
    }
    
    /// Validates if a string is a valid URL
    /// - Parameter url: URL to validate
    /// - Returns: True if the URL is valid
    public static func validateURL(_ url: String) -> Bool {
        validate(url, with: self.url)
    }
    
    /// Validates if a string is a valid IPv4 address
    /// - Parameter ip: IP address to validate
    /// - Returns: True if the IP address is valid
    public static func validateIPv4(_ ip: String) -> Bool {
        validate(ip, with: self.ipv4)
    }
    
    /// Validates if a string is a valid IPv6 address
    /// - Parameter ip: IP address to validate
    /// - Returns: True if the IP address is valid
    public static func validateIPv6(_ ip: String) -> Bool {
        validate(ip, with: self.ipv6)
    }
    
    /// Validates if a string is a valid file system path
    /// - Parameter path: Path to validate
    /// - Returns: True if the path is valid
    public static func validatePath(_ path: String) -> Bool {
        validate(path, with: self.path)
    }
}
