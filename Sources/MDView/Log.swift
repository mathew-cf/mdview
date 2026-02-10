import Foundation

enum Log {
    private static let enabled = ProcessInfo.processInfo.environment["MDVIEW_DEBUG"] != nil
    private static let path = "/tmp/mdview-debug.log"
    private static let formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        return f
    }()

    static func debug(_ message: @autoclosure () -> String) {
        guard enabled else { return }
        let line = "\(formatter.string(from: Date())) \(message())\n"
        if let data = line.data(using: .utf8),
           let fh = FileHandle(forWritingAtPath: path) {
            fh.seekToEndOfFile()
            fh.write(data)
            fh.closeFile()
        } else {
            try? line.write(toFile: path, atomically: true, encoding: .utf8)
        }
    }
}
