//
// ResticXPCService.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation
import Security
import os.log

// MARK: - Restic XPC Service

/// Service for managing Restic operations through XPC
@objc
public final class ResticXPCService: NSObject {
    // MARK: - Properties
    
    /// XPC connection manager
    private let connectionManager: XPCConnectionManager
    
    /// Queue for synchronizing operations
    private let queue: DispatchQueue
    
    /// Current health state of the service
    @objc private(set) dynamic var isHealthy: Bool
    
    /// Active security-scoped bookmarks
    private var activeBookmarks: [String: NSData]
    
    /// Logger for service operations
    private let logger: LoggerProtocol
    
    /// Security service for permissions
    private let securityService: SecurityServiceProtocol
    
    /// Message queue for XPC commands
    private let messageQueue: XPCMessageQueue
    
    /// Task for queue processing
    private var queueProcessor: Task<Void, Never>?
    
    /// Health monitor for service
    private let healthMonitor: XPCHealthMonitor
    
    /// Operation metrics recorder
    private let metricsRecorder: SecurityMetrics
    
    // MARK: - Initialization
    
    /// Creates a new Restic XPC service
    /// - Parameters:
    ///   - logger: Logger for operations
    ///   - securityService: Security service
    ///   - metrics: Metrics recorder
    public init(
        logger: LoggerProtocol,
        securityService: SecurityServiceProtocol,
        metrics: SecurityMetrics
    ) {
        self.logger = logger
        self.securityService = securityService
        self.metricsRecorder = metrics
        
        // Initialize core components
        self.queue = DispatchQueue(
            label: "com.umbra.core.resticXPC",
            qos: .userInitiated,
            attributes: .concurrent
        )
        self.isHealthy = false
        self.activeBookmarks = [:]
        self.messageQueue = XPCMessageQueue(logger: logger)
        
        // Initialize connection manager
        self.connectionManager = XPCConnectionManager(
            logger: logger,
            securityService: securityService
        )
        
        // Initialize health monitor
        self.healthMonitor = XPCHealthMonitor(
            connectionManager: connectionManager,
            logger: logger,
            checkInterval: 30
        )
        
        super.init()
        
        // Configure components
        self.connectionManager.delegate = self
        self.healthMonitor.delegate = self
        
        // Start services
        self.startServices()
    }
    
    deinit {
        stopServices()
    }
    
    // MARK: - Service Lifecycle
    
    /// Starts all service components
    private func startServices() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Start connection manager
            self.connectionManager.start()
            
            // Start health monitoring
            self.healthMonitor.start()
            
            // Start queue processor
            self.startQueueProcessor()
            
            self.logger.info("ResticXPCService started successfully")
        }
    }
    
    /// Stops all service components
    private func stopServices() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Stop health monitoring
            self.healthMonitor.stop()
            
            // Stop queue processor
            self.queueProcessor?.cancel()
            self.queueProcessor = nil
            
            // Stop connection manager
            self.connectionManager.stop()
            
            // Clean up resources
            self.cleanupResources()
            
            self.logger.info("ResticXPCService stopped successfully")
        }
    }
    
    /// Starts the queue processor
    private func startQueueProcessor() {
        queueProcessor = Task { [weak self] in
            guard let self = self else { return }
            
            do {
                try await self.messageQueue.process { message in
                    try await self.handleMessage(message)
                }
            } catch {
                self.logger.error("Queue processor failed: \(error.localizedDescription)")
                self.metricsRecorder.recordXPC(
                    success: false,
                    error: error.localizedDescription
                )
            }
        }
    }
    
    /// Cleans up service resources
    private func cleanupResources() {
        // Release active bookmarks
        for bookmark in activeBookmarks.values {
            autoreleasepool {
                bookmark.stopAccessingSecurityScopedResource()
            }
        }
        activeBookmarks.removeAll()
        
        // Clear message queue
        messageQueue.clear()
    }
}

// MARK: - XPC Connection State Delegate

extension ResticXPCService: XPCConnectionStateDelegate {
    public func connectionStateDidChange(_ state: XPCConnectionState) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            switch state {
            case .connected:
                self.isHealthy = true
                self.logger.info("XPC connection established")
                self.metricsRecorder.recordXPC(
                    success: true,
                    metadata: ["state": "connected"]
                )
                
            case .disconnected:
                self.isHealthy = false
                self.logger.warning("XPC connection lost")
                self.metricsRecorder.recordXPC(
                    success: false,
                    error: "Connection lost",
                    metadata: ["state": "disconnected"]
                )
                
            case .invalid:
                self.isHealthy = false
                self.logger.error("XPC connection invalid")
                self.metricsRecorder.recordXPC(
                    success: false,
                    error: "Invalid connection",
                    metadata: ["state": "invalid"]
                )
                
            case .interrupted:
                self.isHealthy = false
                self.logger.warning("XPC connection interrupted")
                self.metricsRecorder.recordXPC(
                    success: false,
                    error: "Connection interrupted",
                    metadata: ["state": "interrupted"]
                )
            }
        }
    }
}

// MARK: - Health Monitor Delegate

extension ResticXPCService: XPCHealthMonitorDelegate {
    public func healthCheckFailed(_ error: Error) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.isHealthy = false
            self.logger.error("Health check failed: \(error.localizedDescription)")
            self.metricsRecorder.recordXPC(
                success: false,
                error: error.localizedDescription,
                metadata: ["type": "health_check"]
            )
            
            // Attempt recovery
            self.connectionManager.reconnect()
        }
    }
    
    public func healthCheckPassed() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.isHealthy = true
            self.logger.debug("Health check passed")
            self.metricsRecorder.recordXPC(
                success: true,
                metadata: ["type": "health_check"]
            )
        }
    }
}
