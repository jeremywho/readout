import Darwin
import Foundation

public enum ProcessRunner {
    private final class Handle: @unchecked Sendable {
        let process = Process()
        let output = Pipe()
        private let lock = NSLock()
        private var continuation: CheckedContinuation<String?, Never>?

        init(continuation: CheckedContinuation<String?, Never>) {
            self.continuation = continuation
        }

        func finish(_ value: String?) {
            let pending = lock.withLock {
                defer { continuation = nil }
                return continuation
            }
            pending?.resume(returning: value)
        }
    }

    public static func run(_ executable: String, _ arguments: [String], timeout: Double) async -> String? {
        await withCheckedContinuation { continuation in
            let handle = Handle(continuation: continuation)
            handle.process.executableURL = URL(fileURLWithPath: executable)
            handle.process.arguments = arguments
            handle.process.standardOutput = handle.output
            handle.process.standardError = FileHandle.nullDevice
            do {
                try handle.process.run()
            } catch {
                handle.finish(nil)
                return
            }
            let pid = handle.process.processIdentifier
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                guard handle.process.isRunning else { return }
                kill(pid, SIGKILL)
                handle.finish(nil)
            }
            DispatchQueue.global().async {
                let data = handle.output.fileHandleForReading.readDataToEndOfFile()
                handle.process.waitUntilExit()
                let succeeded = handle.process.terminationReason == .exit && handle.process.terminationStatus == 0
                handle.finish(succeeded ? String(decoding: data, as: UTF8.self) : nil)
            }
        }
    }
}
