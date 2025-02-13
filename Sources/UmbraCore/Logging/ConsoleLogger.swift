@preconcurrency import Foundation

/// Simple console logger for bootstrapping
public class ConsoleLogger: LoggerProtocol {
    public init() {}

    public func debug(_ message: String, file: String, function: String, line: Int) {
        log("DEBUG", message: message, file: file, function: function, line: line)
    }

    public func info(_ message: String, file: String, function: String, line: Int) {
        log("INFO", message: message, file: file, function: function, line: line)
    }

    public func warning(_ message: String, file: String, function: String, line: Int) {
        log("WARNING", message: message, file: file, function: function, line: line)
    }

    public func error(_ message: String, file: String, function: String, line: Int) {
        log("ERROR", message: message, file: file, function: function, line: line)
    }

    private func log(_ level: String, message: String, file: String, function _: String, line: Int) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let filename = (file as NSString).lastPathComponent
        print("[\(timestamp)] [\(level)] \(filename):\(line) - \(message)")
    }
}
