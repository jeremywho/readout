import Foundation
import Testing

@testable import ReadoutSystem

@Suite struct ProcessRunnerTests {
    @Test func capturesStandardOutput() async {
        let output = await ProcessRunner.run("/bin/echo", ["hello"], timeout: 5)
        #expect(output == "hello\n")
    }

    @Test func nonZeroExitIsNil() async {
        #expect(await ProcessRunner.run("/usr/bin/false", [], timeout: 5) == nil)
    }

    @Test func missingExecutableIsNil() async {
        #expect(await ProcessRunner.run("/nonexistent/tool", [], timeout: 5) == nil)
    }

    @Test func hungProcessIsTerminatedAtTimeout() async {
        let start = ContinuousClock.now
        let output = await ProcessRunner.run("/bin/sleep", ["30"], timeout: 0.5)
        let elapsed = ContinuousClock.now - start
        #expect(output == nil)
        #expect(elapsed < .seconds(5))
    }

    @Test func realPsOutputParses() async throws {
        let output = try #require(await ProcessRunner.run("/bin/ps", ["-Aceo", "pid=,pcpu=,rss=,comm="], timeout: 5))
        #expect(PSParser.parse(output).contains { $0.pid == ProcessInfo.processInfo.processIdentifier })
    }
}
