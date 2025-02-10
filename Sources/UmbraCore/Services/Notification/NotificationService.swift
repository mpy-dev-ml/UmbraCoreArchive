//
// NotificationService.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation
import UserNotifications

/// Service for managing notifications
public final class NotificationService: BaseSandboxedService {
    // MARK: - Types

    /// Notification priority
    public enum Priority: Int, Comparable {
        case low = 0
        case normal = 1
        case high = 2
        case critical = 3

        public static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// Notification category
    public struct Category {
        /// Category identifier
        public let identifier: String

        /// Category actions
        public let actions: [Action]

        /// Initialize with values
        public init(identifier: String, actions: [Action]) {
            self.identifier = identifier
            self.actions = actions
        }
    }

    /// Notification action
    public struct Action {
        /// Action identifier
        public let identifier: String

        /// Action title
        public let title: String

        /// Action options
        public let options: UNNotificationActionOptions

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
    }

    // MARK: - Properties

    /// Notification center
    private let center = UNUserNotificationCenter.current()

    /// Queue for synchronizing operations
    private let queue = DispatchQueue(
        label: "dev.mpy.umbracore.notification",
        qos: .userInitiated,
        attributes: .concurrent
    )

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    /// Registered categories
    private var categories: Set<UNNotificationCategory> = []

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

    // MARK: - Public Methods

    /// Schedule notification
    /// - Parameters:
    ///   - title: Notification title
    ///   - body: Notification body
    ///   - categoryIdentifier: Optional category identifier
    ///   - userInfo: Optional user info
    ///   - priority: Priority level
    ///   - date: Trigger date
    /// - Returns: Notification identifier
    /// - Throws: Error if scheduling fails
    @discardableResult
    public func scheduleNotification(
        title: String,
        body: String,
        categoryIdentifier: String? = nil,
        userInfo: [AnyHashable: Any] = [:],
        priority: Priority = .normal,
        date: Date
    ) async throws -> String {
        try validateUsable(for: "scheduleNotification")

        return try await performanceMonitor.trackDuration(
            "notification.schedule"
        ) {
            // Create content
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.userInfo = userInfo
            content.sound = .default

            if let categoryIdentifier = categoryIdentifier {
                content.categoryIdentifier = categoryIdentifier
            }

            // Set interruption level
            if #available(macOS 12.0, *) {
                switch priority {
                case .low:
                    content.interruptionLevel = .passive
                case .normal:
                    content.interruptionLevel = .active
                case .high:
                    content.interruptionLevel = .timeSensitive
                case .critical:
                    content.interruptionLevel = .critical
                }
            }

            // Create trigger
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: date
            )
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: false
            )

            // Create request
            let identifier = UUID().uuidString
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            // Schedule request
            try await center.add(request)

            logger.info(
                """
                Scheduled notification:
                ID: \(identifier)
                Title: \(title)
                Category: \(categoryIdentifier ?? "none")
                Priority: \(priority)
                Date: \(date)
                """,
                file: #file,
                function: #function,
                line: #line
            )

            return identifier
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
}
