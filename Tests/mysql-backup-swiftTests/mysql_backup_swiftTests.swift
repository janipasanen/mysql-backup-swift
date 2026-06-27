import XCTest
@testable import mysql_backup_core

final class MySQLBackupTests: XCTestCase {
    func testBackupRotationAndCompression() throws {
        let backupDir = "test_backups_rot"
        try? FileManager.default.removeItem(atPath: backupDir)
        try FileManager.default.createDirectory(atPath: backupDir, withIntermediateDirectories: true)
        
        let config = BackupManager.Config(
            dbUser: "test",
            dbPassword: "password",
            dbName: "testdb",
            backupDir: backupDir,
            retentionDays: 7
        )
        let manager = BackupManager(config: config)
        
        let oldFile = "\(backupDir)/testdb_old.sql"
        FileManager.default.createFile(atPath: oldFile, contents: "dummy data".data(using: .utf8), attributes: nil)
        
        let attributes = [FileAttributeKey.creationDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!]
        try FileManager.default.setAttributes(attributes, ofItemAtPath: oldFile)
        
        try manager.rotateBackups()
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: oldFile + ".tar.gz"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: oldFile))
        
        try? FileManager.default.removeItem(atPath: backupDir)
    }
    
    func testRetentionPolicy() throws {
        let backupDir = "test_backups_ret"
        try? FileManager.default.removeItem(atPath: backupDir)
        try FileManager.default.createDirectory(atPath: backupDir, withIntermediateDirectories: true)
        
        let config = BackupManager.Config(
            dbUser: "test",
            dbPassword: "password",
            dbName: "testdb",
            backupDir: backupDir,
            retentionDays: 1
        )
        let manager = BackupManager(config: config)
        
        let veryOldFile = "\(backupDir)/testdb_very_old.sql"
        FileManager.default.createFile(atPath: veryOldFile, contents: "dummy data".data(using: .utf8), attributes: nil)
        
        let attributes = [FileAttributeKey.creationDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!]
        try FileManager.default.setAttributes(attributes, ofItemAtPath: veryOldFile)
        
        try manager.rotateBackups()
        
        XCTAssertFalse(FileManager.default.fileExists(atPath: veryOldFile))
        XCTAssertFalse(FileManager.default.fileExists(atPath: veryOldFile + ".tar.gz"))
        
        try? FileManager.default.removeItem(atPath: backupDir)
    }
}
