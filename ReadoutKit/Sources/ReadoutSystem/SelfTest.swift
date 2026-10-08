import Foundation

public struct SelfTestResult: Sendable {
    public var passed: Bool
    public var report: String
}

public enum SelfTest {
    public static func run(ticks: Int = 3) async -> SelfTestResult {
        let engine = SamplingEngine()
        var snapshot = MetricsSnapshot()
        for index in 0..<max(ticks, 2) {
            snapshot = await engine.tick()
            if index < max(ticks, 2) - 1 { try? await Task.sleep(for: .seconds(1)) }
        }
        let checks: [(String, Bool)] = [
            ("network", snapshot.network?.throughput != nil),
            ("cpu", snapshot.cpu != nil),
            ("memory", snapshot.memory != nil),
            ("disk", snapshot.disk != nil),
        ]
        var lines = checks.map { "\($0.0): \($0.1 ? "ok" : "FAILED")" }
        lines.append("temperature: \(snapshot.temperature == nil ? "unavailable (allowed)" : "ok")")
        return SelfTestResult(passed: checks.allSatisfy(\.1), report: lines.joined(separator: "\n"))
    }

    public static func runBlocking(ticks: Int = 3) -> SelfTestResult {
        final class Box: @unchecked Sendable {
            let lock = NSLock()
            var value: SelfTestResult?
        }
        let box = Box()
        let semaphore = DispatchSemaphore(value: 0)
        Task.detached {
            let result = await run(ticks: ticks)
            box.lock.withLock { box.value = result }
            semaphore.signal()
        }
        semaphore.wait()
        return box.lock.withLock { box.value } ?? SelfTestResult(passed: false, report: "self-test produced no result")
    }
}
