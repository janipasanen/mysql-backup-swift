import Foundation

public protocol ShellExecutor {
    func execute(_ command: String) throws -> Int32
}

public class RealShellExecutor: ShellExecutor {
    public init() {}
    public func execute(_ command: String) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }
}
