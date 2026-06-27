import Foundation
import mysql_backup_core

public struct MySQLBackup {
    public static func main() {
        let args = CommandLine.arguments
        
        var user: String?
        var password: String?
        var database: String?
        var directory: String = "./backups"
        var retention: Int = 30
        
        // Google Drive config
        var gdToken: String?
        var gdFolder: String?

        var i = 1
        while i < args.count {
            let arg = args[i]
            switch arg {
            case "--user":
                if i + 1 < args.count { user = args[i+1]; i += 1 }
            case "--password":
                if i + 1 < args.count { password = args[i+1]; i += 1 }
            case "--database":
                if i + 1 < args.count { database = args[i+1]; i += 1 }
            case "--directory":
                if i + 1 < args.count { directory = args[i+1]; i += 1 }
            case "--retention":
                if i + 1 < args.count { retention = Int(args[i+1]) ?? 30; i += 1 }
            case "--gd-token":
                if i + 1 < args.count { gdToken = args[i+1]; i += 1 }
            case "--gd-folder":
                if i + 1 < args.count { gdFolder = args[i+1]; i += 1 }
            default:
                break
            }
            i += 1
        }

        let finalUser = user ?? ProcessInfo.processInfo.environment["MYSQL_USER"]
        let finalPassword = password ?? ProcessInfo.processInfo.environment["MYSQL_PASSWORD"]
        let finalDbName = database ?? ProcessInfo.processInfo.environment["MYSQL_DATABASE"]
        let finalGdToken = gdToken ?? ProcessInfo.processInfo.environment["GD_TOKEN"]
        let finalGdFolder = gdFolder ?? ProcessInfo.processInfo.environment["GD_FOLDER"]

        guard let u = finalUser, let d = finalDbName else {
            print("Error: MySQL user and database name are required via --user/--database or environment variables.")
            print("Usage: mysql-backup-swift [--user <user>] [--password <pass>] [--database <db>] [--directory <dir>] [--retention <days>] [--gd-token <token>] [--gd-folder <folder>]")
            exit(1)
        }

        let config = BackupManager.Config(
            dbUser: u,
            dbPassword: finalPassword,
            dbName: d,
            backupDir: directory,
            retentionDays: retention
        )

        let manager = BackupManager(config: config)
        
        do {
            print("Starting backup for \(d)...")
            let path = try manager.runBackup()
            print("Backup completed successfully: \(path)")
            
            // Google Drive Upload
            if let token = finalGdToken {
                print("Uploading to Google Drive...")
                let gdConfig = GoogleDriveManager.Config(accessToken: token, folderId: finalGdFolder)
                let gdManager = GoogleDriveManager(config: gdConfig)
                try gdManager.uploadFile(filePath: path)
                print("Upload to Google Drive successful.")
            } else {
                print("Google Drive token not provided; skipping upload.")
            }
            
            print("Rotating and compressing old backups...")
            try manager.rotateBackups()
            print("Rotation completed.")
        } catch {
            print("Error occurred: \(error)")
            exit(1)
        }
    }
}

MySQLBackup.main()
