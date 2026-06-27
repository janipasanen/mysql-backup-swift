import Foundation

public enum BackupError: Error {
    case shellCommandFailed(String)
    case invalidConfiguration
    case fileOperationFailed(String)
}

public class BackupManager {
    public struct Config {
        public let dbUser: String
        public let dbPassword: String?
        public let dbName: String
        public let backupDir: String
        public let retentionDays: Int

        public init(dbUser: String, dbPassword: String?, dbName: String, backupDir: String, retentionDays: Int) {
            self.dbUser = dbUser
            self.dbPassword = dbPassword
            self.dbName = dbName
            self.backupDir = backupDir
            self.retentionDays = retentionDays
        }
    }

    public let config: Config

    public init(config: Config) {
        self.config = config
    }

    public func runBackup() throws -> String {
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let fileName = "\(config.dbName)_\(timestamp).sql"
        let filePath = "\(config.backupDir)/\(fileName)"
        
        try createDirectory(path: config.backupDir)

        let passwordArg = config.dbPassword != nil ? "-p\(config.dbPassword!)" : "-p"
        let command = "mysqldump -u \(config.dbUser) \(passwordArg) \(config.dbName) > \(filePath)"
        
        print("Executing: \(command)")
        try executeShell(command)
        
        return filePath
    }

    public func rotateBackups() throws {
        let fileManager = FileManager.default
        let items = try fileManager.contentsOfDirectory(atPath: config.backupDir)
        
        let now = Date()
        let calendar = Calendar.current

        for item in items {
            let fullPath = "\(config.backupDir)/\(item)"
            let attributes = try fileManager.attributesOfItem(atPath: fullPath)
            guard let creationDate = attributes[.creationDate] as? Date else { continue }
            
            let diff = calendar.dateComponents([.day], from: creationDate, to: now).day ?? 0
            
            if diff >= config.retentionDays {
                print("Deleting expired backup: \(item)")
                try fileManager.removeItem(atPath: fullPath)
            } else if diff >= 1 {
                try compressBackup(filePath: fullPath)
            }
        }
    }

    private func compressBackup(filePath: String) throws {
        let fileManager = FileManager.default
        if filePath.hasSuffix(".tar.gz") { return }
        
        let compressedPath = filePath + ".tar.gz"
        let command = "tar -czf \(compressedPath) -C \(config.backupDir) \(URL(fileURLWithPath: filePath).lastPathComponent)"
        
        print("Compressing: \(filePath)")
        try executeShell(command)
        try fileManager.removeItem(atPath: filePath)
    }

    private func createDirectory(path: String) throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path) {
            try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
        }
    }

    private func executeShell(_ command: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw BackupError.shellCommandFailed("Command failed with status \(process.terminationStatus): \(command)")
        }
    }
}
