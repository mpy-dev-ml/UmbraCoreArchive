//
// LoggerProtocol.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation
import os.log

/// Protocol for logging operations
@objc
public protocol LoggerProtocol {
    /// Log debug message
    @objc
    func debug(
        _ message: String,
        config: LogConfig
    )

    /// Log info message
    @objc
    func info(
        _ message: String,
        config: LogConfig
    )

    /// Log warning message
    @objc
    func warning(
        _ message: String,
        config: LogConfig
    )

    /// Log error message
    @objc
    func error(
        _ message: String,
        config: LogConfig
    )

    /// Log critical message
    @objc
    func critical(
        _ message: String,
        config: LogConfig
    )
}

/// Configuration for log messages
public struct LogConfig {
    /// Metadata key-value pairs
    public let metadata: [String: String]

    /// Initialize with values
    public init(
        metadata: [String: String] = [:]
    ) {
        self.metadata = metadata
    }
}
