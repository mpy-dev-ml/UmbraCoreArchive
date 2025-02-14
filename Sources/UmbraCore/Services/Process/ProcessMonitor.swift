@preconcurrency import Foundation

// MARK: - ProcessMonitor

/// Service for monitoring process execution and performance
@objc
public class ProcessMonitor: NSObject {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with dependencies
    public init(
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        self.performanceMonitor = performanceMonitor
        self.logger = logger
        super.init()
        setupUpdateTimer()
    }

    // MARK: Public

    // MARK: - Types

    /// Process information
    public struct ProcessInfo {
        // MARK: Lifecycle

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

        // MARK: Public

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
    }

    /// Process statistics
    public struct ProcessStats {
        // MARK: Lifecycle

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

        // MARK: Public

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
    }

    // MARK: - Public Methods

    /// Start monitoring process
    @objc
    public func startMonitoring(
        pid: Int32
    ) throws {
        try queue.sync { [weak self] in
            // Check if already monitoring
            guard let self else {
                return
            }
            guard monitors[pid] == nil else {
                throw ProcessError.alreadyMonitoring(pid)
            }

            // Get initial process info
            let info = try getProcessInfo(pid)

            // Create monitor info
            let monitor = ProcessMonitorInfo(
                info: info,
                samples: [info],
                startTime: Date()
            )

            // Store monitor
            monitors[pid] = monitor

            // Log monitoring start
            let metadata: [String: String] = [
                "pid": String(pid),
                "name": info.name
            ]
            let config = LogConfig(metadata: metadata)
            logger.info("Started monitoring process", config: config)
        }
    }

    /// Stop monitoring process
    @objc
    public func stopMonitoring(
        pid: Int32
    ) throws -> ProcessStats {
        try queue.sync { [weak self] in
            // Get monitor info
            guard let self else {
                return
            }
            guard let monitor = monitors[pid] else {
                throw ProcessError.notMonitoring(pid)
            }

            // Remove monitor
            monitors.removeValue(forKey: pid)

            // Calculate stats
            let stats = calculateStats(
                from: monitor.samples,
                startTime: monitor.startTime
            )

            // Log monitoring stop
            let metadata: [String: String] = [
                "pid": String(pid),
                "name": monitor.info.name,
                "duration": String(stats.duration)
            ]
            let config = LogConfig(metadata: metadata)
            logger.info("Stopped monitoring process", config: config)

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
            guard let self else {
                return
            }

            // Get process task info
            var taskInfo = proc_taskinfo()
            let taskInfoSize = MemoryLayout<proc_taskinfo>.size

            let result = proc_pidinfo(
                pid,
                PROC_PIDTASKINFO,
                0,
                &taskInfo,
                Int32(taskInfoSize)
            )

            guard result == taskInfoSize else {
                let error = ProcessError.infoPidFailed(pid)
                logProcessError(error, pid: pid)
                throw error
            }

            // Get process name
            var name = [CChar](repeating: 0, count: MAXPATHLEN)
            guard proc_name(pid, &name, UInt32(MAXPATHLEN)) != -1 else {
                let error = ProcessError.namePidFailed(pid)
                logProcessError(error, pid: pid)
                throw error
            }

            // Convert name to string
            guard
                let processName = String(
                    cString: name,
                    encoding: .utf8
                )
            else {
                let error = ProcessError.nameEncodingFailed(pid)
                logProcessError(error, pid: pid)
                throw error
            }

            // Calculate CPU usage
            let cpuTime = Double(
                taskInfo.pti_total_user + taskInfo.pti_total_system
            )
            let cpuUsage = cpuTime / Self.cpuTimeBase

            return ProcessInfo(
                pid: pid,
                name: processName,
                startTime: Date(),
                cpuUsage: cpuUsage,
                memoryUsage: UInt64(taskInfo.pti_resident_size),
                threadCount: Int(taskInfo.pti_threadnum),
                fileDescriptorCount: Int(taskInfo.pti_fds)
            )
        }
    }

    // MARK: Private

    /// Base value for CPU time calculations
    private static let cpuTimeBase: Double = {
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        return Double(timebase.denom) / Double(timebase.numer) * 1e9
    }()

    /// Logger for tracking operations
    private let logger: LoggerProtocol

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    /// Queue for synchronizing operations
    private let queue: DispatchQueue = .init(
        label: "dev.mpy.umbra.process-monitor",
        qos: .userInitiated
    )

    /// Active process monitors
    private var monitors: [Int32: ProcessMonitorInfo] = [:]

    /// Timer for updating process info
    private var updateTimer: DispatchSourceTimer?

    /// Log a process error with metadata
    private func logProcessError(
        _ error: ProcessError,
        pid: Int32
    ) {
        let metadata: [String: String] = [
            "pid": String(pid),
            "error": String(describing: error)
        ]
        let config = LogConfig(metadata: metadata)
        logger.error(
            "Process monitoring error",
            config: config
        )
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
                // Log error
                let metadata: [String: String] = [
                    "pid": String(pid),
                    "error": String(describing: error)
                ]
                let config = LogConfig(metadata: metadata)
                logger.error("Failed to update process info", config: config)
            }
        }
    }

    /// Calculate process statistics
    private func calculateStats(
        from samples: [ProcessInfo],
        startTime: Date
    ) -> ProcessStats {
        let cpuValues = samples.map(\.cpuUsage)
        let memoryValues = samples.map(\.memoryUsage)
        let threadValues = samples.map(\.threadCount)

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

// MARK: - ProcessMonitorInfo

/// Process monitor information
private struct ProcessMonitorInfo {
    /// Current process info
    let info: ProcessMonitor.ProcessInfo
    /// Process info samples
    let samples: [ProcessMonitor.ProcessInfo]
    /// Monitor start time
    let startTime: Date
}
