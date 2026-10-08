import Foundation

public enum ProcessRunner {
    private final class Handle: @unchecked Sendable {
        let process = Process()
        let output = Pipe()
    }

    public static func run(_ executable: String, _ arguments: [String], timeout: Double) async -> String? {
        await withCheckedContinuation { continuation in
            let handle = Handle()
            handle.process.executableURL = URL(fileURLWithPath: executable)
            handle.process.arguments = arguments
            handle.process.standardOutput = handle.output
            handle.process.standardError = FileHandle.nullDevice
            do {
                try handle.process.run()
            } catch {
                continuation.resume(returning: nil)
                return
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                if handle.process.isRunning { handle.process.terminate() }
            }
            DispatchQueue.global().async {
                let data = handle.output.fileHandleForReading.readDataToEndOfFile()
                handle.process.waitUntilExit()
                let succeeded = handle.process.terminationReason == .exit && handle.process.terminationStatus == 0
                continuation.resume(returning: succeeded ? String(decoding: data, as: UTF8.self) : nil)
            }
        }
    }
}
