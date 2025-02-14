import Foundation

/// Notification names used throughout the application
public enum UmbraNotification {
    /// Base notification name
    private static let base = "dev.mpy.umbracore"
    
    /// Notification names for XPC-related events
    public struct XPC {
        /// Posted when XPC connection is interrupted
        public static let connectionInterrupted = Notification.Name("\(UmbraNotification.base).xpc.connectionInterrupted")
        
        /// Posted when XPC connection is invalidated
        public static let connectionInvalidated = Notification.Name("\(UmbraNotification.base).xpc.connectionInvalidated")
        
        /// Posted when XPC connection is restored
        public static let connectionRestored = Notification.Name("\(UmbraNotification.base).xpc.connectionRestored")
        
        /// Posted when XPC connection state changes
        public static let connectionStateChanged = Notification.Name("\(UmbraNotification.base).xpc.connectionState")
        
        /// Posted when XPC service health status changes
        public static let healthStatusChanged = Notification.Name("\(UmbraNotification.base).xpc.healthStatus")
        
        /// Posted when an XPC command completes successfully
        public static let commandCompleted = Notification.Name("\(UmbraNotification.base).xpc.commandCompleted")
        
        /// Posted when an XPC command fails
        public static let commandFailed = Notification.Name("\(UmbraNotification.base).xpc.commandFailed")
        
        /// Posted when the XPC queue status changes
        public static let queueStatusChanged = Notification.Name("\(UmbraNotification.base).xpc.queueStatusChanged")
    }
    
    /// Notification names for maintenance-related events
    public struct Maintenance {
        /// Posted when maintenance schedule changes
        public static let scheduleChanged = Notification.Name("\(UmbraNotification.base).maintenance.schedule")
        
        /// Posted when maintenance task completes
        public static let taskCompleted = Notification.Name("\(UmbraNotification.base).maintenance.taskCompleted")
    }
    
    /// Notification names for performance-related events
    public struct Performance {
        /// Posted when performance metrics are updated
        public static let metricsUpdated = Notification.Name("\(UmbraNotification.base).performance.metrics")
        
        /// Posted when performance alert is triggered
        public static let alertTriggered = Notification.Name("\(UmbraNotification.base).performance.alert")
    }
    
    /// Notification names for configuration-related events
    public struct Configuration {
        /// Posted when configuration changes
        public static let changed = Notification.Name("\(UmbraNotification.base).config.changed")
        
        /// Posted when configuration is reset
        public static let reset = Notification.Name("\(UmbraNotification.base).config.reset")
    }
}
