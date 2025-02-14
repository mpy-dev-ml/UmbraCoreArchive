@preconcurrency import Foundation
import UserNotifications

/// Service for managing notifications
public final class NotificationService: BaseSandboxedService {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - performanceMonitor: Performance monitor
    ///   - logger: Logger for tracking operations
    public init(
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        self.performanceMonitor = performanceMonitor
        super.init(logger: logger)
        requestAuthorization()
    }

    // MARK: Public

    // MARK: - Types

    /// Notification priority
    public enum Priority: Int, Comparable {
        case low = 0
        case normal = 1
        case high = 2
        case critical = 3

        // MARK: Public

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        @available(macOS 12.0, *)
        var interruptionLevel: UNNotificationInterruptionLevel {
            switch self {
            case .low:
                .passive

            case .normal:
                .active

            case .high:
                .timeSensitive

            case .critical:
                .critical
            }
        }
    }

    /// Notification category
    public struct Category {
        // MARK: Lifecycle

        /// Initialize with values
        public init(identifier: String, actions: [Action]) {
            self.identifier = identifier
            self.actions = actions
        }

        // MARK: Public

        /// Category identifier
        public let identifier: String

        /// Category actions
        public let actions: [Action]
    }

    /// Notification action
    public struct Action {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            identifier: String,
            title: String,
            options: UNNotificationActionOptions = []
        ) {
            self.identifier = identifier
            self.title = title
            self.options = options
        }

        // MARK: Public

        /// Action identifier
        public let identifier: String

        /// Action title
        public let title: String

        /// Action options
        public let options: UNNotificationActionOptions
    }

    /// Configuration for a notification request
    public struct NotificationConfiguration {
        // MARK: Lifecycle

        /// Initialize with values
        public init(
            identifier: String,
            title: String,
            body: String,
            categoryIdentifier: String? = nil,
            userInfo: [AnyHashable: Any] = [:],
            priority: Priority = .normal,
            date: Date = Date()
        ) {
            self.identifier = identifier
            self.title = title
            self.body = body
            self.categoryIdentifier = categoryIdentifier
            self.userInfo = userInfo
            self.priority = priority
            self.date = date
        }

        // MARK: Public

        /// Unique identifier for the notification
        public let identifier: String

        /// Notification title
        public let title: String

        /// Notification body text
        public let body: String

        /// Category identifier for custom actions
        public let categoryIdentifier: String?

        /// Additional user information
        public let userInfo: [AnyHashable: Any]

        /// Priority level
        public let priority: Priority

        /// Trigger date
        public let date: Date
    }

    // MARK: - Public Methods

    /// Schedule notification
    /// - Parameters:
    ///   - configuration: Notification configuration
    /// - Returns: Notification identifier
    /// - Throws: Error if scheduling fails
    @discardableResult
    public func scheduleNotification(
        configuration: NotificationConfiguration
    ) async throws -> String {
        try validateUsable(for: "scheduleNotification")

        return try await performanceMonitor.trackDuration(
            "notification.schedule"
        ) {
            // Create notification request
            let request = createNotificationRequest(configuration: configuration)

            // Schedule request
            try await center.add(request)

            // Log operation
            logger.info(
                """
                Scheduled notification:
                ID: \(configuration.identifier)
                Title: \(configuration.title)
                Category: \(configuration.categoryIdentifier ?? "none")
                Priority: \(configuration.priority)
                Date: \(configuration.date)
                """,
                file: #file,
                function: #function,
                line: #line
            )

            return configuration.identifier
        }
    }

    /// Cancel notification
    /// - Parameter identifier: Notification identifier
    public func cancelNotification(withIdentifier identifier: String) {
        center.removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )

        logger.debug(
            "Cancelled notification: \(identifier)",
            file: #file,
            function: #function,
            line: #line
        )
    }

    /// Cancel all notifications
    public func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()

        logger.debug(
            "Cancelled all notifications",
            file: #file,
            function: #function,
            line: #line
        )
    }

    /// Register notification category
    /// - Parameter category: Category to register
    public func registerCategory(_ category: Category) {
        let actions = category.actions.map { action in
            UNNotificationAction(
                identifier: action.identifier,
                title: action.title,
                options: action.options
            )
        }

        let category = UNNotificationCategory(
            identifier: category.identifier,
            actions: actions,
            intentIdentifiers: [],
            options: []
        )

        queue.async(flags: .barrier) {
            self.categories.insert(category)
            self.center.setNotificationCategories(self.categories)

            self.logger.debug(
                """
                Registered notification category:
                ID: \(category.identifier)
                Actions: \(category.actions.count)
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Unregister notification category
    /// - Parameter identifier: Category identifier
    public func unregisterCategory(withIdentifier identifier: String) {
        queue.async(flags: .barrier) {
            self.categories.removeAll { $0.identifier == identifier }
            self.center.setNotificationCategories(self.categories)

            self.logger.debug(
                "Unregistered notification category: \(identifier)",
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Get pending notifications
    /// - Returns: Array of pending notification requests
    public func getPendingNotifications() async -> [UNNotificationRequest] {
        try? await performanceMonitor.trackDuration(
            "notification.pending"
        ) {
            await center.pendingNotificationRequests()
        } ?? []
    }

    // MARK: Private

    /// Notification center
    private let center: UNUserNotificationCenter = .current()

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.notification",
        qos: .userInitiated,
        attributes: .concurrent
    )

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    /// Registered categories
    private var categories: Set<UNNotificationCategory> = []

    // MARK: - Private Methods

    /// Request notification authorization
    private func requestAuthorization() {
        Task {
            do {
                let granted = try await center.requestAuthorization(
                    options: [.alert, .sound, .badge]
                )

                logger.info(
                    "Notification authorization \(granted ? "granted" : "denied")",
                    file: #file,
                    function: #function,
                    line: #line
                )
            } catch {
                logger.error(
                    "Failed to request notification authorization: \(error)",
                    file: #file,
                    function: #function,
                    line: #line
                )
            }
        }
    }

    /// Create a notification request with the specified parameters
    /// - Parameters:
    ///   - configuration: Notification configuration
    /// - Returns: Configured notification request
    private func createNotificationRequest(
        configuration: NotificationConfiguration
    ) -> UNNotificationRequest {
        // Create content
        let content = createNotificationContent(
            title: configuration.title,
            body: configuration.body,
            categoryIdentifier: configuration.categoryIdentifier,
            userInfo: configuration.userInfo,
            priority: configuration.priority
        )

        // Create trigger
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(0, configuration.date.timeIntervalSinceNow),
            repeats: false
        )

        // Create request
        return UNNotificationRequest(
            identifier: configuration.identifier,
            content: content,
            trigger: trigger
        )
    }

    /// Create notification content with the specified parameters
    /// - Parameters:
    ///   - title: Notification title
    ///   - body: Notification body
    ///   - categoryIdentifier: Optional category identifier
    ///   - userInfo: Optional user info
    ///   - priority: Priority level
    /// - Returns: Configured notification content
    private func createNotificationContent(
        title: String,
        body: String,
        categoryIdentifier: String?,
        userInfo: [AnyHashable: Any],
        priority: Priority
    ) async throws -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.userInfo = userInfo
        content.sound = .default

        if let categoryIdentifier {
            content.categoryIdentifier = categoryIdentifier
        }

        if #available(macOS 12.0, *) {
            content.interruptionLevel = priority.interruptionLevel
        }

        return content
    }
}
