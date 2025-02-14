@preconcurrency import Foundation

public extension Notification.Name {
    // MARK: - XPC Connection Notifications

    /// Posted when XPC connection is interrupted
    static let xpcConnectionInterrupted = Notification.Name(
        "dev.mpy.umbracore.xpcConnectionInterrupted")

    /// Posted when XPC connection is invalidated
    static let xpcConnectionInvalidated = Notification.Name(
        "dev.mpy.umbracore.xpcConnectionInvalidated")

    /// Posted when XPC connection is restored
    static let xpcConnectionRestored = Notification.Name(
        "dev.mpy.umbracore.xpcConnectionRestored")

    // MARK: - Service Notifications

    /// Posted when service state changes
    static let serviceStateChanged = Notification.Name("dev.mpy.umbracore.serviceStateChanged")

    /// Posted when service health status changes
    static let serviceHealthStatusChanged = Notification.Name(
        "dev.mpy.umbracore.serviceHealthStatusChanged")

    /// Posted when service configuration changes
    static let serviceConfigurationChanged = Notification.Name(
        "dev.mpy.umbracore.serviceConfigurationChanged")
}
