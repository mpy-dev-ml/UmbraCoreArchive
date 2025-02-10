extension ResticXPCService {
    func performBackupOperation(
        source: String,
        destination: String,
        options: [String: Any]
    ) throws -> Bool {
        let validOptions = [
            "compression",
            "excludes",
            "includes",
            "tags"
        ]
        
        guard validateOptions(options, against: validOptions) else {
            throw ResticXPCError.invalidOptions
        }
        
        return try executeBackup(from: source, to: destination, with: options)
    }
    
    func performRestoreOperation(
        source: String,
        destination: String,
        snapshot: String,
        options: [String: Any]
    ) throws -> Bool {
        let validOptions = [
            "includeDeleted",
            "overwrite",
            "preservePermissions",
            "verify"
        ]
        
        guard validateOptions(options, against: validOptions) else {
            throw ResticXPCError.invalidOptions
        }
        
        return try executeRestore(from: source, to: destination, snapshot: snapshot, with: options)
    }
    
    private func validateOptions(
        _ options: [String: Any],
        against validOptions: [String]
    ) -> Bool {
        let optionKeys = Set(options.keys)
        let validOptionSet = Set(validOptions)
        return optionKeys.isSubset(of: validOptionSet)
    }
    
    private func executeBackup(
        from source: String,
        to destination: String,
        with options: [String: Any]
    ) throws -> Bool {
        guard fileManager.fileExists(atPath: source) else {
            throw ResticXPCError.sourceNotFound
        }
        
        let operation = BackupOperation(
            source: source,
            destination: destination,
            options: options
        )
        
        return try operationQueue.sync {
            try operation.execute()
        }
    }
    
    private func executeRestore(
        from source: String,
        to destination: String,
        snapshot: String,
        with options: [String: Any]
    ) throws -> Bool {
        guard fileManager.fileExists(atPath: source) else {
            throw ResticXPCError.sourceNotFound
        }
        
        let operation = RestoreOperation(
            source: source,
            destination: destination,
            snapshot: snapshot,
            options: options
        )
        
        return try operationQueue.sync {
            try operation.execute()
        }
    }
}
