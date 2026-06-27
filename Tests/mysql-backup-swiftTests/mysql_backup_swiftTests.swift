import XCTest
@testable import mysql_backup_core

// Mocks
class MockShellExecutor: ShellExecutor {
    var executedCommands: [String] = []
    var resultStatus: Int32 = 0
    
    func execute(_ command: String) throws -> Int32 {
        executedCommands.append(command)
        return resultStatus
    }
}

class MockNetworkClient: NetworkClient {
    var uploadCalled = false
    var responseData: Data?
    var response: URLResponse?
    var error: Error?
    
    func upload(request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        uploadCalled = true
        completion(responseData, response, error)
    }
}

final class MySQLBackupTests: XCTestCase {
    
    func testRunBackup() throws {
        let backupDir = "test_backups_run"
        try? FileManager.default.removeItem(atPath: backupDir)
        try FileManager.default.createDirectory(atPath: backupDir, withIntermediateDirectories: true)
        
        let mockExecutor = MockShellExecutor()
        let config = BackupManager.Config(
            dbUser: "testuser",
            dbPassword: "testpassword",
            dbName: "testdb",
            backupDir: backupDir,
            retentionDays: 7
        )
        let manager = BackupManager(config: config, executor: mockExecutor)
        
        let path = try manager.runBackup()
        
        XCTAssertTrue(path.contains("testdb_"))
        XCTAssertTrue(path.contains(backupDir))
        XCTAssertEqual(mockExecutor.executedCommands.count, 1)
        XCTAssertTrue(mockExecutor.executedCommands[0].contains("mysqldump -u testuser -ptestpassword testdb"))
        
        try? FileManager.default.removeItem(atPath: backupDir)
    }
    
    func testRunBackupFailure() throws {
        let mockExecutor = MockShellExecutor()
        mockExecutor.resultStatus = 1
        
        let config = BackupManager.Config(
            dbUser: "testuser",
            dbPassword: "testpassword",
            dbName: "testdb",
            backupDir: "fail_dir",
            retentionDays: 7
        )
        let manager = BackupManager(config: config, executor: mockExecutor)
        
        XCTAssertThrowsError(try manager.runBackup()) { error in
            XCTAssertTrue(error is BackupError)
        }
    }
    
    func testGoogleDriveUpload() throws {
        let backupDir = "test_backups_gd"
        try? FileManager.default.removeItem(atPath: backupDir)
        try FileManager.default.createDirectory(atPath: backupDir, withIntermediateDirectories: true)
        let filePath = "\(backupDir)/test.sql"
        FileManager.default.createFile(atPath: filePath, contents: "data".data(using: .utf8), attributes: nil)
        
        let mockClient = MockNetworkClient()
        mockClient.response = HTTPURLResponse(url: URL(string: "http://api.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        let config = GoogleDriveManager.Config(accessToken: "mock_token", folderId: "mock_folder")
        let manager = GoogleDriveManager(config: config, client: mockClient)
        
        try manager.uploadFile(filePath: filePath)
        XCTAssertTrue(mockClient.uploadCalled)
        
        try? FileManager.default.removeItem(atPath: backupDir)
    }
    
    func testGoogleDriveUploadFailure() throws {
        let backupDir = "test_backups_gd_fail"
        try? FileManager.default.removeItem(atPath: backupDir)
        try FileManager.default.createDirectory(atPath: backupDir, withIntermediateDirectories: true)
        let filePath = "\(backupDir)/test.sql"
        FileManager.default.createFile(atPath: filePath, contents: "data".data(using: .utf8), attributes: nil)
        
        let mockClient = MockNetworkClient()
        mockClient.response = HTTPURLResponse(url: URL(string: "http://api.com")!, statusCode: 401, httpVersion: nil, headerFields: nil)
        
        let config = GoogleDriveManager.Config(accessToken: "bad_token")
        let manager = GoogleDriveManager(config: config, client: mockClient)
        
        XCTAssertThrowsError(try manager.uploadFile(filePath: filePath))
        
        try? FileManager.default.removeItem(atPath: backupDir)
    }
    
    func testBackupRotationAndCompression() throws {
        let backupDir = "test_backups_rot"
        try? FileManager.default.removeItem(atPath: backupDir)
        try FileManager.default.createDirectory(atPath: backupDir, withIntermediateDirectories: true)
        
        let mockExecutor = MockShellExecutor()
        let config = BackupManager.Config(
            dbUser: "test",
            dbPassword: "password",
            dbName: "testdb",
            backupDir: backupDir,
            retentionDays: 7
        )
        let manager = BackupManager(config: config, executor: mockExecutor)
        
        let oldFile = "\(backupDir)/testdb_old.sql"
        FileManager.default.createFile(atPath: oldFile, contents: "dummy data".data(using: .utf8), attributes: nil)
        
        let attributes = [FileAttributeKey.creationDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!]
        try FileManager.default.setAttributes(attributes, ofItemAtPath: oldFile)
        
        try manager.rotateBackups()
        
        XCTAssertTrue(mockExecutor.executedCommands.contains { $0.contains("tar -czf") })
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
        
        try? FileManager.default.removeItem(atPath: backupDir)
    }
}
