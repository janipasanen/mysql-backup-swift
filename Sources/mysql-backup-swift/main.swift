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
        var gdToken: String?
        var gdFolder: String?

        var i = 1
        while i < args.count {
            let arg = args[i]
            switch arg {
            case "--user", "-u":
                if i + 1 < args.count { user = args[i+1]; i += 1 } else { print("Error: --user requires a value"); exit(1) }
            case "--password", "-p":
                if i + 1 < args.count { password = args[i+1]; i += 1 } else { print("Error: --password requires a value"); exit(1) }
            case "--database", "-d":
                if i + 1 < args.count { database = args[i+1]; i += 1 } else { print("Error: --database requires a value"); exit(1) }
            case "--directory", "-o":
                if i + 1 < args.count { directory = args[i+1]; i += 1 } else { print("Error: --directory requires a value"); exit(1) }
            case "--retention", "-r":
                if i + 1 < args.count { 
                    if let val = Int(args[i+1]) { retention = val } else { print("Error: --retention must be an integer"); exit(1) }
                    i += 1 
                } else { print("Error: --retention requires a value"); exit(1) }
            case "--gd-token", "-t":
                if i + 1 < args.count { gdToken = args[i+1]; i += 1 } else { print("Error: --gd-token requires a value"); exit(1) }
            case "--gd-folder", "-f":
                if i + 1 < args.count { gdFolder = args[i+1]; i += 1 } else { print("Error: --gd-folder requires a value"); exit(1) }
            case "--help", "-h":
                printUsage()
                exit(0)
            default:
                print("Error: Unknown argument \(arg)")
                printUsage()
                exit(1)
            }
            i += 1
        }

        let finalUser = user ?? ProcessInfo.processInfo.environment["MYSQL_USER"]
        let finalPassword = password ?? ProcessInfo.processInfo.environment["MYSQL_PASSWORD"]
        let finalDbName = database ?? ProcessInfo.processInfo.environment["MYSQL_DATABASE"]
        let finalGdToken = gdToken ?? ProcessInfo.processInfo.environment["GD_TOKEN"]
        let finalGdFolder = gdFolder ?? ProcessInfo.processInfo.environment["GD_FOLDER"]

        guard let u = finalUser, let d = finalDbName else {
            print("Error: MySQL user and database name are required via arguments or environment variables.")
            printUsage()
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

    private static func printUsage() {
        let usage = """
        Usage: mysql-backup-swift [options]

        Options:
          -u, --user <user>         MySQL User (Env: MYSQL_USER)
          -p, --password <pass>     MySQL Password (Env: MYSQL_PASSWORD)
          -d, --database <db>       MySQL Database Name (Env: MYSQL_DATABASE)
          -o, --directory <dir>     Backup Directory (Env: MYSQL_BACKUP_DIR, default: ./backups)
          -r, --retention <days>    Retention period in days (default: 30)
          -t, --gd-token <token>    Google Drive Access Token (Env: GD_TOKEN)
          -f, --gd-folder <folder>  Google Drive Folder ID (Env: GD_FOLDER)
          -h, --help                Show this help message
        """
        print(usage)
    }
}

MySQLBackup.main()
