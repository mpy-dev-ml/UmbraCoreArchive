//
// CacheMetrics.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation

/// Service for tracking cache metrics
public final class CacheMetrics: BaseSandboxedService {
    // MARK: - Types

    /// Cache metrics
    public struct Metrics {
        /// Total cache size in bytes
        public let totalSize: Int64

        /// Number of entries
        public let entryCount: Int

        /// Hit rate
        public let hitRate: Double

        /// Miss rate
        public let missRate: Double

        /// Average entry size
        public let averageEntrySize: Double

        /// Average entry age
        public let averageEntryAge: TimeInterval

        /// Initialize with values
        public init(
            totalSize: Int64,
            entryCount: Int,
            hitRate: Double,
            missRate: Double,
            averageEntrySize: Double,
            averageEntryAge: TimeInterval
        ) {
            self.totalSize = totalSize
            self.entryCount = entryCount
            self.hitRate = hitRate
            self.missRate = missRate
            self.averageEntrySize = averageEntrySize
            self.averageEntryAge = averageEntryAge
        }
    }

    // MARK: - Properties

    /// Cache directory URL
    private let directoryURL: URL

    /// Queue for synchronizing operations
    private let queue = DispatchQueue(
        label: "dev.mpy.umbracore.cache.metrics",
        qos: .utility,
        attributes: .concurrent
    )

    /// Performance monitor
    private let performanceMonitor: PerformanceMonitor

    /// Hit count
    private var hitCount: Int = 0

    /// Miss count
    private var missCount: Int = 0

    // MARK: - Initialization

    /// Initialize with dependencies
    /// - Parameters:
    ///   - directoryURL: Cache directory URL
    ///   - performanceMonitor: Performance monitor
    ///   - logger: Logger for tracking operations
    public init(
        directoryURL: URL,
        performanceMonitor: PerformanceMonitor,
        logger: LoggerProtocol
    ) {
        self.directoryURL = directoryURL
        self.performanceMonitor = performanceMonitor
        super.init(logger: logger)
    }

    // MARK: - Public Methods

    /// Track cache hit
    public func trackHit() {
        queue.async(flags: .barrier) {
            self.hitCount += 1
        }
    }

    /// Track cache miss
    public func trackMiss() {
        queue.async(flags: .barrier) {
            self.missCount += 1
        }
    }

    /// Get current metrics
    /// - Returns: Cache metrics
    /// - Throws: Error if operation fails
    public func getMetrics() async throws -> Metrics {
        try validateUsable(for: "getMetrics")

        return try await performanceMonitor.trackDuration("cache.metrics") {
            // Get cache contents
            let contents = try FileManager.default.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [.fileSizeKey, .creationDateKey]
            )

            var totalSize: Int64 = 0
            var totalAge: TimeInterval = 0

            // Calculate metrics
            for url in contents {
                let attributes = try FileManager.default.attributesOfItem(
                    atPath: url.path
                )

                let size = attributes[.size] as? Int64 ?? 0
                totalSize += size

                if let creationDate = attributes[.creationDate] as? Date {
                    totalAge += Date().timeIntervalSince(creationDate)
                }
            }

            let entryCount = contents.count
            let totalRequests = hitCount + missCount

            let hitRate = totalRequests > 0
                ? Double(hitCount) / Double(totalRequests)
                : 0.0

            let missRate = totalRequests > 0
                ? Double(missCount) / Double(totalRequests)
                : 0.0

            let averageEntrySize = entryCount > 0
                ? Double(totalSize) / Double(entryCount)
                : 0.0

            let averageEntryAge = entryCount > 0
                ? totalAge / Double(entryCount)
                : 0.0

            // Create metrics
            let metrics = Metrics(
                totalSize: totalSize,
                entryCount: entryCount,
                hitRate: hitRate,
                missRate: missRate,
                averageEntrySize: averageEntrySize,
                averageEntryAge: averageEntryAge
            )

            // Log metrics
            logger.debug(
                """
                Cache metrics:
                Size: \(totalSize) bytes
                Entries: \(entryCount)
                Hit Rate: \(hitRate * 100)%
                Miss Rate: \(missRate * 100)%
                Avg Size: \(averageEntrySize) bytes
                Avg Age: \(averageEntryAge)s
                """,
                file: #file,
                function: #function,
                line: #line
            )

            // Track performance metrics
            Task {
                try? await performanceMonitor.trackMetric(
                    "cache.size",
                    value: Double(totalSize)
                )
                try? await performanceMonitor.trackMetric(
                    "cache.entries",
                    value: Double(entryCount)
                )
                try? await performanceMonitor.trackMetric(
                    "cache.hit_rate",
                    value: hitRate
                )
                try? await performanceMonitor.trackMetric(
                    "cache.miss_rate",
                    value: missRate
                )
            }

            return metrics
        }
    }

    /// Reset metrics
    public func resetMetrics() {
        queue.async(flags: .barrier) {
            self.hitCount = 0
            self.missCount = 0
        }

        logger.debug(
            "Reset cache metrics",
            file: #file,
            function: #function,
            line: #line
        )
    }
}
