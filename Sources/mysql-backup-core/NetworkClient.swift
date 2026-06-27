import Foundation

public protocol NetworkClient {
    func upload(request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void)
}

public class RealNetworkClient: NetworkClient {
    public init() {}
    public func upload(request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        URLSession.shared.dataTask(with: request) { data, response, error in
            completion(data, response, error)
        }.resume()
    }
}
