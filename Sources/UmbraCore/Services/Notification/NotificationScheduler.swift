//
// NotificationScheduler.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Service for scheduling notifications with advanced patterns
public final class NotificationScheduler: BaseSandboxedService {
    // MARK: - Types

    /// Schedule pattern
    public enum Pattern {
        /// One-time schedule
        case oneTime(Date)
        /// Daily schedule
        case daily(hour: Int, minute: Int)
        /// Weekly schedule
        case weekly(weekday: Int, hour: Int, minute: Int)
        /// Monthly schedule
        case monthly(day: Int, hour: Int, minute: Int)
        /// Custom interval schedule
        case interval(TimeInterval)

        /// Get next trigger date
        func nextTriggerDate(after date: Date = Date()) -> Date? {
            let calendar = Calendar.current

            switch self {
            case .oneTime(let triggerDate):
                return triggerDate > date ? triggerDate : nil

            case .daily(let hour, let minute):
                var components = calendar.dateComponents(
                    [.year, .month, .day],
                    from: date
                )
                components.hour = hour
                components.minute = minute

                guard let triggerDate = calendar.date(from: components) else {
                    return nil
                }

                return triggerDate > date
                    ? triggerDate
                    : calendar.date(byAdding: .day, value: 1, to: triggerDate)

            case .weekly(let weekday, let hour, let minute):
                var components = calendar.dateComponents(
                    [.yearForWeekOfYear, .weekOfYear],
                    from: date
                )
                components.weekday = weekday
                components.hour = hour
                components.minute = minute

                guard let triggerDate = calendar.date(from: components) else {
                    return nil
                }

                return triggerDate > date
                    ? triggerDate
                    : calendar.date(byAdding: .weekOfYear, value: 1, to: triggerDate)

            case .monthly(let day, let hour, let minute):
                var components = calendar.dateComponents(
                    [.year, .month],
                    from: date
                )
                components.day = day
                components.hour = hour
                components.minute = minute

                guard let triggerDate = calendar.date(from: components) else {
                    return nil
                }

                return triggerDate > date
                    ? triggerDate
                    : calendar.date(byAdding: .month, value: 1, to: triggerDate)

            case .interval(let interval):
                return date.addingTimeInterval(interval)
            }
        }
    }

    /// Schedule configuration
    public struct Configuration {
        /// Schedule identifier
        public let identifier: String

        /// Notification title
        public let title: String

        /// Notification body
        public let body: String

        /// Schedule pattern
        public let pattern: Pattern

        /// Category identifier
        public let categoryIdentifier: String?

        /// User info
        public let userInfo: [AnyHashable: Any]

        /// Priority level
        public let priority: NotificationService.Priority

        /// Initialize with values
        public init(
            identifier: String,
            title: String,
            body: String,
            pattern: Pattern,
            categoryIdentifier: String? = nil,
            userInfo: [AnyHashable: Any] = [:],
            priority: NotificationService.Priority = .normal
        ) {
            self.identifier = identifier
            self.title = title
            self.body = body
            self.pattern = pattern
            self.categoryIdentifier = categoryIdentifier
            self.userInfo = userInfo
            self.priority = priority
        }
    }

    // MARK: - Properties

    /// Notification service
    private let notificationService: NotificationService

    /// Queue for synchronizing operations
    private let queue = DispatchQueue(
        label: "dev.mpy.umbracore.notification.scheduler",
        qos: .utility,
        attributes: .concurrent
    )

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    /// Active schedules
    private var schedules: [String: Configuration] = [:]

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - notificationService: Notification service
    ///   - performanceMonitor: Performance monitor
    ///   - logger: Logger for tracking operations
    public init(
        notificationService: NotificationService,
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        self.notificationService = notificationService
        self.performanceMonitor = performanceMonitor
        super.init(logger: logger)
    }

    // MARK: - Public Methods

    /// Schedule notification
    /// - Parameter configuration: Schedule configuration
    /// - Throws: Error if scheduling fails
    public func schedule(
        _ configuration: Configuration
    ) async throws {
        try validateUsable(for: "schedule")

        try await performanceMonitor.trackDuration(
            "notification.scheduler.schedule"
        ) {
            // Get next trigger date
            guard let triggerDate = configuration.pattern.nextTriggerDate() else {
                throw NotificationError.invalidSchedule(
                    "No valid trigger date for pattern"
                )
            }

            // Schedule notification
            let notificationId = try await notificationService.scheduleNotification(
                title: configuration.title,
                body: configuration.body,
                categoryIdentifier: configuration.categoryIdentifier,
                userInfo: configuration.userInfo,
                priority: configuration.priority,
                date: triggerDate
            )

            // Store schedule
            queue.async(flags: .barrier) {
                self.schedules[configuration.identifier] = configuration
            }

            logger.info(
                """
                Scheduled notification:
                ID: \(configuration.identifier)
                Title: \(configuration.title)
                Pattern: \(String(describing: configuration.pattern))
                Next: \(triggerDate)
                NotificationID: \(notificationId)
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Cancel schedule
    /// - Parameter identifier: Schedule identifier
    public func cancelSchedule(_ identifier: String) {
        queue.async(flags: .barrier) {
            self.schedules.removeValue(forKey: identifier)

            self.logger.debug(
                "Cancelled schedule: \(identifier)",
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Get active schedules
    /// - Returns: Dictionary of active schedules
    public func getActiveSchedules() -> [String: Configuration] {
        queue.sync { schedules }
    }

    /// Reschedule all active schedules
    /// - Throws: Error if rescheduling fails
    public func rescheduleAll() async throws {
        try validateUsable(for: "rescheduleAll")

        try await performanceMonitor.trackDuration(
            "notification.scheduler.reschedule"
        ) {
            let activeSchedules = getActiveSchedules()

            for (identifier, configuration) in activeSchedules {
                do {
                    try await schedule(configuration)
                } catch {
                    logger.error(
                        """
                        Failed to reschedule:
                        ID: \(identifier)
                        Error: \(error.localizedDescription)
                        """,
                        file: #file,
                        function: #function,
                        line: #line
                    )
                }
            }
        }
    }
}
