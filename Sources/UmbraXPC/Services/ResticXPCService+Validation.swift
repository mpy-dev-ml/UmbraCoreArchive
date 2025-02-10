//
// ResticXPCService+Validation.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

//
// ResticXPCService+Validation.swift
// UmbraCore
//
// Created by Migration Script
// Copyright 2025 MPY Dev. All rights reserved.
//

import Foundation
import os.log

// MARK: - Validation

@available(macOS 13.0, *)
extension ResticXPCService {
    /// Validates the XPC connection and service state
    /// - Throws: ResticXPCError if validation fails
    func validateConnection() throws {
        guard let connection = connection else {
            throw ResticXPCError.connectionNotEstablished
        }

        // Check connection state
        if connection.invalidationHandler == nil {
            throw ResticXPCError.connectionInvalidated
        }

        // Check exported interface
        let exportedError = "Exported interface not configured"
        guard connection.exportedInterface != nil else {
            throw ResticXPCError.invalidInterface(exportedError)
        }

        // Check remote interface
        let remoteError = "Remote interface not configured"
        guard connection.remoteObjectInterface != nil else {
            throw ResticXPCError.invalidInterface(remoteError)
        }

        // Check remote object proxy
        guard connection.remoteObjectProxy != nil else {
            throw ResticXPCError.serviceUnavailable
        }

        // Check audit session
        let sessionId = au_session_self()
        guard connection.auditSessionIdentifier == sessionId else {
            throw ResticXPCError.invalidSession
        }
    }

    /// Validates command prerequisites before execution
    /// - Parameter command: The command to validate
    /// - Throws: ResticXPCError if validation fails
    func validateCommandPrerequisites(_ command: ResticCommand) async throws {
        // Validate connection
        try validateConnection()

        // Validate resources
        try validateResources()

        // Validate command
        try validateCommand(command)

        // Validate health
        guard try await performHealthCheck() else {
            throw ResticXPCError.unhealthyService
        }
    }

    /// Validates a Restic command
    /// - Parameter command: The command to validate
    /// - Throws: ResticXPCError if validation fails
    private func validateCommand(_ command: ResticCommand) throws {
        // Check command
        guard !command.command.isEmpty else {
            throw ResticXPCError.invalidCommand("Command cannot be empty")
        }

        // Check working directory
        let workDirError = "Working directory cannot be empty"
        guard !command.workingDirectory.isEmpty else {
            throw ResticXPCError.invalidCommand(workDirError)
        }

        // Check arguments
        let pathError = "Arguments cannot contain path traversal"
        for argument in command.arguments where argument.contains("..") {
            throw ResticXPCError.invalidCommand(pathError)
        }

        // Check environment
        let envError = "Environment variables cannot be empty"
        for (key, value) in command.environment where key.isEmpty || value.isEmpty {
            throw ResticXPCError.invalidCommand(envError)
        }
    }

    /// Validates service configuration
    /// - Throws: ResticXPCError if validation fails
    func validateConfiguration() throws {
        // Check timeout
        let timeoutError = "Default timeout must be positive"
        guard defaultTimeout > 0 else {
            throw ResticXPCError.invalidConfiguration(timeoutError)
        }

        // Check max retries
        let retriesError = "Max retries must be positive"
        guard maxRetries > 0 else {
            throw ResticXPCError.invalidConfiguration(retriesError)
        }

        // Check interface version
        let versionError = "Interface version must be positive"
        guard interfaceVersion > 0 else {
            throw ResticXPCError.invalidConfiguration(versionError)
        }

        // Check queue
        let queueError = "Invalid queue label"
        guard queue.label.contains("dev.mpy.rBUM") else {
            throw ResticXPCError.invalidConfiguration(queueError)
        }
    }

    /// Validates service state
    /// - Throws: ResticXPCError if validation fails
    func validateServiceState() throws {
        // Check health
        guard isHealthy else {
            throw ResticXPCError.unhealthyService
        }

        // Check configuration
        try validateConfiguration()

        // Check connection
        try validateConnection()

        // Check resources
        try validateResources()
    }
}
