import Testing

@testable import ReadoutSystem

@Suite struct EngineTests {
    @Test func secondTickHasNetworkCpuMemoryAndDisk() async throws {
        let engine = SamplingEngine()
        _ = await engine.tick()
        try await Task.sleep(for: .milliseconds(500))
        let snapshot = await engine.tick()
        #expect(snapshot.network?.interface != nil)
        #expect(snapshot.network?.throughput != nil)
        #expect(snapshot.cpu != nil)
        #expect(snapshot.memory != nil)
        #expect(snapshot.disk != nil)
    }

    @Test func selfTestPassesOnThisMachine() async {
        let result = await SelfTest.run(ticks: 2)
        #expect(result.passed, "\(result.report)")
        #expect(result.report.contains("network"))
    }

    @Test func localAddressesForLoopbackIncludeIPv4() {
        #expect(LocalAddresses.addresses(interface: "lo0").contains("127.0.0.1"))
    }
}
