@preconcurrency import Foundation

/// Dummy logger for initialization
final class DummyLogger: LoggerProtocol {
    func log(
        level _: LogLevel,
        message _: String,
        file _: String = #file,
        line _: Int = #line,
        function _: String = #function
    ) {
        // No-op implementation
    }

    func metric(
        _: MetricContext,
        file _: String = #file,
        line _: Int = #line,
        function _: String = #function
    ) {
        // No-op implementation
    }
}
