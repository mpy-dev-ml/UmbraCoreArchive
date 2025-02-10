import Foundation

// MARK: - ConfigurationObserving

/// Protocol for observing configuration changes
public protocol ConfigurationObserving: AnyObject {
    /// Called when configuration value changes
    /// - Parameters:
    ///   - service: Configuration service
    ///   - key: Configuration key
    ///   - value: New value
    func configurationService(
        _ service: ConfigurationService,
        didChangeValueForKey key: String,
        to value: Any
    )

    /// Called when configuration value is removed
    /// - Parameters:
    ///   - service: Configuration service
    ///   - key: Configuration key
    func configurationService(
        _ service: ConfigurationService,
        didRemoveValueForKey key: String
    )

    /// Called when all configuration values are cleared
    /// - Parameter service: Configuration service
    func configurationServiceDidClearValues(
        _ service: ConfigurationService
    )
}

/// Default implementations for ConfigurationObserving
public extension ConfigurationObserving {
    func configurationService(
        _: ConfigurationService,
        didChangeValueForKey _: String,
        to _: Any
    ) {}

    func configurationService(
        _: ConfigurationService,
        didRemoveValueForKey _: String
    ) {}

    func configurationServiceDidClearValues(
        _: ConfigurationService
    ) {}
}

// MARK: - ConfigurationObserver

/// Service for managing configuration observers
public final class ConfigurationObserver: BaseSandboxedService {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - configurationService: Configuration service
    ///   - logger: Logger for tracking operations
    public init(
        configurationService: ConfigurationService,
        logger: LoggerProtocol
    ) {
        self.configurationService = configurationService
        super.init(logger: logger)
    }

    // MARK: Public

    // MARK: - Public Methods

    /// Add observer for configuration changes
    /// - Parameters:
    ///   - observer: Observer to add
    ///   - keys: Keys to observe
    public func addObserver(
        _ observer: ConfigurationObserving,
        forKeys keys: Set<String>
    ) {
        queue.async(flags: .barrier) {
            let registration = ObserverRegistration(
                observer: observer,
                keys: keys
            )
            self.registrations.append(registration)

            self.logger.debug(
                """
                Added configuration observer:
                Keys: \(keys)
                """,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Remove observer
    /// - Parameter observer: Observer to remove
    public func removeObserver(_ observer: ConfigurationObserving) {
        queue.async(flags: .barrier) {
            self.registrations.removeAll { registration in
                registration.observer === observer
            }

            self.logger.debug(
                "Removed configuration observer",
                file: #file,
                function: #function,
                line: #line
            )
        }
    }

    /// Notify observers of value change
    /// - Parameters:
    ///   - key: Configuration key
    ///   - value: New value
    public func notifyValueChanged(forKey key: String, to value: Any) {
        guard let service = configurationService else {
            return
        }

        queue.async {
            // Clean up stale observers
            self.cleanupStaleObservers()

            // Notify observers
            for registration in self.registrations {
                guard let observer = registration.observer else {
                    continue
                }

                if registration.keys.isEmpty || registration.keys.contains(key) {
                    observer.configurationService(
                        service,
                        didChangeValueForKey: key,
                        to: value
                    )
                }
            }
        }
    }

    /// Notify observers of value removal
    /// - Parameter key: Configuration key
    public func notifyValueRemoved(forKey key: String) {
        guard let service = configurationService else {
            return
        }

        queue.async {
            // Clean up stale observers
            self.cleanupStaleObservers()

            // Notify observers
            for registration in self.registrations {
                guard let observer = registration.observer else {
                    continue
                }

                if registration.keys.isEmpty || registration.keys.contains(key) {
                    observer.configurationService(
                        service,
                        didRemoveValueForKey: key
                    )
                }
            }
        }
    }

    /// Notify observers of values cleared
    public func notifyValuesCleared() {
        guard let service = configurationService else {
            return
        }

        queue.async {
            // Clean up stale observers
            self.cleanupStaleObservers()

            // Notify observers
            for registration in self.registrations {
                guard let observer = registration.observer else {
                    continue
                }
                observer.configurationServiceDidClearValues(service)
            }
        }
    }

    // MARK: Private

    // MARK: - Types

    /// Observer registration
    private struct ObserverRegistration {
        // MARK: Lifecycle

        /// Initialize with values
        init(observer: ConfigurationObserving, keys: Set<String>) {
            self.observer = observer
            self.keys = keys
        }

        // MARK: Internal

        /// Observer reference
        weak var observer: ConfigurationObserving?

        /// Observed keys
        let keys: Set<String>
    }

    /// Observer registrations
    private var registrations: [ObserverRegistration] = []

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbracore.config.observer",
        qos: .userInitiated,
        attributes: .concurrent
    )

    /// Configuration service
    private weak var configurationService: ConfigurationService?

    // MARK: - Private Methods

    /// Clean up stale observers
    private func cleanupStaleObservers() {
        queue.async(flags: .barrier) {
            self.registrations.removeAll { registration in
                registration.observer == nil
            }
        }
    }
}
