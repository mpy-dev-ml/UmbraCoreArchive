/// Service for monitoring process execution and performance
@objc
public class ProcessMonitor: NSObject {
    // MARK: - Types

    /// Process information
    public struct ProcessInfo {
        /// Process identifier
        public let pid: Int32
        /// Process name
        public let name: String
        /// Start time
        public let startTime: Date
        /// CPU usage
        public let cpuUsage: Double
        /// Memory usage in bytes
        public let memoryUsage: UInt64
        /// Thread count
        public let threadCount: Int
        /// File descriptor count
        public let fileDescriptorCount: Int

        /// Initialize with values
        public init(
            pid: Int32,
            name: String,
            startTime: Date,
            cpuUsage: Double,
            memoryUsage: UInt64,
            threadCount: Int,
            fileDescriptorCount: Int
        ) {
            self.pid = pid
            self.name = name
            self.startTime = startTime
            self.cpuUsage = cpuUsage
            self.memoryUsage = memoryUsage
            self.threadCount = threadCount
            self.fileDescriptorCount = fileDescriptorCount
        }
    }

    /// Process statistics
    public struct ProcessStats {
        /// Average CPU usage
        public let averageCPU: Double
        /// Peak CPU usage
        public let peakCPU: Double
        /// Average memory usage
        public let averageMemory: UInt64
        /// Peak memory usage
        public let peakMemory: UInt64
        /// Average thread count
        public let averageThreads: Double
        /// Peak thread count
        public let peakThreads: Int
        /// Sample count
        public let sampleCount: Int
        /// Duration in seconds
        public let duration: TimeInterval

        /// Initialize with values
        public init(
            averageCPU: Double,
            peakCPU: Double,
            averageMemory: UInt64,
            peakMemory: UInt64,
            averageThreads: Double,
            peakThreads: Int,
            sampleCount: Int,
            duration: TimeInterval
        ) {
            self.averageCPU = averageCPU
            self.peakCPU = peakCPU
            self.averageMemory = averageMemory
            self.peakMemory = peakMemory
            self.averageThreads = averageThreads
            self.peakThreads = peakThreads
            self.sampleCount = sampleCount
            self.duration = duration
        }
    }

    // MARK: - Properties

    /// Logger for tracking operations
    private let logger: LoggerProtocol

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    /// Queue for synchronizing operations
    private let queue = DispatchQueue(
        label: "dev.mpy.umbra.process-monitor",
        qos: .userInitiated
    )

    /// Active process monitors
    private var monitors: [Int32: ProcessMonitorInfo] = [:]

    /// Timer for updating process info
    private var updateTimer: DispatchSourceTimer?

    // MARK: - Initialization

    /// Initialize with dependencies
    @objc
    public init(
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        self.performanceMonitor = performanceMonitor
        self.logger = logger
        super.init()
        setupUpdateTimer()
    }

    // MARK: - Public Methods

    /// Start monitoring process
    @objc
    public func startMonitoring(
        pid: Int32
    ) throws {
        try queue.sync { [weak self] in
            // Check if already monitoring
            guard let self = self else { return }
            guard self.monitors[pid] == nil else {
                throw ProcessError.alreadyMonitoring(pid)
            }

            // Get initial process info
            let info = try self.getProcessInfo(pid)

            // Create monitor info
            let monitor = ProcessMonitorInfo(
                info: info,
                samples: [info],
                startTime: Date()
            )

            // Store monitor
            self.monitors[pid] = monitor

            self.logger.info(
                "Started monitoring process",
                config: LogConfig(
                    metadata: [
                        "pid": String(pid),
                        "name": info.name
                    ]
                )
            )
        }
    }

    /// Stop monitoring process
    @objc
    public func stopMonitoring(
        pid: Int32
    ) throws -> ProcessStats {
        try queue.sync { [weak self] in
            // Get monitor info
            guard let self = self else { return }
            guard let monitor = self.monitors[pid] else {
                throw ProcessError.notMonitoring(pid)
            }

            // Remove monitor
            self.monitors.removeValue(forKey: pid)

            // Calculate stats
            let stats = self.calculateStats(
                from: monitor.samples,
                startTime: monitor.startTime
            )

            self.logger.info(
                "Stopped monitoring process",
                config: LogConfig(
                    metadata: [
                        "pid": String(pid),
                        "name": monitor.info.name,
                        "duration": String(stats.duration)
                    ]
                )
            )

            return stats
        }
    }

    /// Get process info
    @objc
    public func getProcessInfo(
        _ pid: Int32
    ) throws -> ProcessInfo {
        try performanceMonitor.trackDuration(
            "process.info"
        ) { [weak self] in
            guard let self = self else { return }

            var info = proc_taskinfo()
            var size = MemoryLayout<proc_taskinfo>.size

            guard proc_pidinfo(
                pid,
                PROC_PIDTASKINFO,
                0,
                &info,
                Int32(size)
            ) == size else {
                throw ProcessError.infoPidFailed(pid)
            }

            var name = [CChar](repeating: 0, count: MAXPATHLEN)
            guard proc_name(pid, &name, UInt32(MAXPATHLEN)) != -1 else {
                throw ProcessError.namePidFailed(pid)
            }

            let processName = String(cString: name)
            let startTime = Date(timeIntervalSince1970: TimeInterval(info.pti_start_time))
            let cpuUsage = Double(info.pti_total_user + info.pti_total_system) / Double(info.pti_total_time)

            return ProcessInfo(
                pid: pid,
                name: processName,
                startTime: startTime,
                cpuUsage: cpuUsage,
                memoryUsage: UInt64(info.pti_resident_size),
                threadCount: Int(info.pti_threadnum),
                fileDescriptorCount: Int(info.pti_fds)
            )
        }
    }

    // MARK: - Private Methods

    /// Set up update timer
    private func setupUpdateTimer() {
        let timer = DispatchSource.makeTimerSource(
            queue: queue
        )

        timer.schedule(
            deadline: .now(),
            repeating: .seconds(1)
        )

        timer.setEventHandler { [weak self] in
            self?.updateProcessInfo()
        }

        timer.resume()

        updateTimer = timer
    }

    /// Update process info
    private func updateProcessInfo() {
        for (pid, monitor) in monitors {
            do {
                let info = try getProcessInfo(pid)

                monitors[pid] = ProcessMonitorInfo(
                    info: info,
                    samples: monitor.samples + [info],
                    startTime: monitor.startTime
                )
            } catch {
                logger.error(
                    "Failed to update process info",
                    config: LogConfig(
                        metadata: [
                            "pid": String(pid),
                            "error": String(describing: error)
                        ]
                    )
                )
            }
        }
    }

    /// Calculate process statistics
    private func calculateStats(
        from samples: [ProcessInfo],
        startTime: Date
    ) -> ProcessStats {
        let cpuValues = samples.map { $0.cpuUsage }
        let memoryValues = samples.map { $0.memoryUsage }
        let threadValues = samples.map { $0.threadCount }

        return ProcessStats(
            averageCPU: cpuValues.reduce(0, +) / Double(cpuValues.count),
            peakCPU: cpuValues.max() ?? 0,
            averageMemory: UInt64(Double(memoryValues.reduce(0, +)) / Double(memoryValues.count)),
            peakMemory: memoryValues.max() ?? 0,
            averageThreads: Double(threadValues.reduce(0, +)) / Double(threadValues.count),
            peakThreads: threadValues.max() ?? 0,
            sampleCount: samples.count,
            duration: Date().timeIntervalSince(startTime)
        )
    }
}

/// Process monitor information
private struct ProcessMonitorInfo {
    /// Current process info
    let info: ProcessMonitor.ProcessInfo
    /// Process info samples
    let samples: [ProcessMonitor.ProcessInfo]
    /// Monitor start time
    let startTime: Date
}
