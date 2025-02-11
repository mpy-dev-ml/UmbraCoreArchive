import Foundation
import UserNotifications

// MARK: - NotificationResponding

/// Protocol for handling notification responses
public protocol NotificationResponding: AnyObject {
    /// Called when notification action is selected
    /// - Parameters:
    ///   - service: Notification service
    ///   - response: Notification response
    func notificationService(
        _ service: NotificationService,
        didReceiveResponse response: UNNotificationResponse
    )

    /// Called when notification is presented
    /// - Parameters:
    ///   - service: Notification service
    ///   - notification: Notification
    func notificationService(
        _ service: NotificationService,
        willPresentNotification notification: UNNotification
    ) async -> UNNotificationPresentationOptions
}

/// Default implementations for NotificationResponding
public extension NotificationResponding {
    func notificationService(
        _: NotificationService,
        didReceiveResponse _: UNNotificationResponse
    ) {}

    func notificationService(
        _: NotificationService,
        willPresentNotification _: UNNotification
    ) async -> UNNotificationPresentationOptions {
        if #available(macOS 12.0, *) {
            [.banner, .sound, .badge]
        } else {
            [.alert, .sound, .badge]
        }
    }
}

// MARK: - NotificationDelegate

/// Delegate for handling notification events
public final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - service: Notification service
    ///   - responder: Notification responder
    ///   - logger: Logger for tracking operations
    public init(
        service: NotificationService,
        responder: NotificationResponding,
        logger: LoggerProtocol
    ) {
        self.service = service
        self.responder = responder
        self.logger = logger
        super.init()

        // Set delegate
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: Public

    // MARK: - UNUserNotificationCenterDelegate Implementation

    public func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        guard let service,
              let responder
        else {
            return []
        }

        logger.debug(
            """
            Will present notification:
            ID: \(notification.request.identifier)
            Category: \(notification.request.content.categoryIdentifier)
            """,
            file: #file,
            function: #function,
            line: #line
        )

        return await responder.notificationService(
            service,
            willPresentNotification: notification
        )
    }

    public func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let service,
              let responder
        else {
            return
        }

        logger.debug(
            """
            Did receive notification response:
            ID: \(response.notification.request.identifier)
            Action: \(response.actionIdentifier)
            """,
            file: #file,
            function: #function,
            line: #line
        )

        responder.notificationService(service, didReceiveResponse: response)
    }

    // MARK: Private

    /// Notification service
    private weak var service: NotificationService?

    /// Notification responder
    private weak var responder: NotificationResponding?

    /// Logger for tracking operations
    private let logger: LoggerProtocol
}

// MARK: - NotificationDelegateService

/// Service for managing notification delegates
public final class NotificationDelegateService: BaseSandboxedService {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameter logger: Logger for tracking operations
    override public init(logger: LoggerProtocol) {
        super.init(logger: logger)
    }

    // MARK: Public

    // MARK: - Public Methods

    /// Create notification delegate
    /// - Parameters:
    ///   - service: Notification service
    ///   - responder: Notification responder
    /// - Returns: Notification delegate
    public func createDelegate(
        for service: NotificationService,
        responder: NotificationResponding
    ) -> NotificationDelegate {
        let delegate = NotificationDelegate(
            service: service,
            responder: responder,
            logger: logger
        )

        queue.async(flags: .barrier) {
            self.delegates.append(delegate)

            self.logger.debug(
                "Created notification delegate",
                file: #file,
                function: #function,
                line: #line
            )
        }

        return delegate
    }

    /// Remove notification delegate
    /// - Parameter delegate: Delegate to remove
    public func removeDelegate(_ delegate: NotificationDelegate) {
        queue.async(flags: .barrier) {
            self.delegates.removeAll { $0 === delegate }

            self.logger.debug(
                "Removed notification delegate",
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Clear all delegates
    public func clearDelegates() {
        queue.async(flags: .barrier) {
            self.delegates.removeAll()

            self.logger.debug(
                "Cleared all notification delegates",
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    // MARK: Private

    /// Active delegates
    private var delegates: [NotificationDelegate] = []

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.notification.delegate",
        qos: .userInitiated,
        attributes: .concurrent
    )
}
