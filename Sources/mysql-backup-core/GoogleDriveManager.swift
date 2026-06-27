import Foundation

public enum GoogleDriveError: Error {
    case authenticationFailed
    case uploadFailed(String)
    case invalidToken
}

public class GoogleDriveManager {
    public struct Config {
        public let accessToken: String
        public let folderId: String?
        
        public init(accessToken: String, folderId: String? = nil) {
            self.accessToken = accessToken
            self.folderId = folderId
        }
    }

    private let config: Config

    public init(config: Config) {
        self.config = config
    }

    public func uploadFile(filePath: String) throws {
        let fileURL = URL(fileURLWithPath: filePath)
        let fileName = fileURL.lastPathComponent
        
        // 1. Create metadata for the file
        let metadata: [String: Any] = [
            "name": fileName,
            "parents": config.folderId != nil ? [config.folderId!] : []
        ]
        
        let metadataData = try JSONSerialization.data(withJSONObject: metadata, options: [])
        
        // 2. Upload the file (Multipart upload for name + content)
        let boundary = "SwiftBoundary\(UUID().uuidString)"
        var bodyData = Data()
        
        // Metadata part
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        bodyData.append(metadataData)
        bodyData.append("\r\n".data(using: .utf8)!)
        
        // File content part
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Type: application/octet-stream\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"file\"\r\n\r\n".data(using: .utf8)!)
        
        let fileData = try Data(contentsOf: fileURL)
        bodyData.append(fileData)
        bodyData.append("\r\n".data(using: .utf8)!)
        bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        let url = URL(string: "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        
        let semaphore = DispatchSemaphore(value: 0)
        var uploadError: Error?
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                uploadError = error
            } else if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                let responseString = data != nil ? String(data: data!, encoding: .utf8) : "No response body"
                uploadError = GoogleDriveError.uploadFailed("HTTP \(httpResponse.statusCode): \(responseString)")
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        
        if let error = uploadError {
            throw error
        }
    }
}
