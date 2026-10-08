import Testing

@testable import ReadoutCore

@Suite struct ProcessParsersTests {
    let nettopOutput = """
        ,bytes_in,bytes_out,
        launchd.1,0,0,
        remoted.360,3978,2626,
        apsd.383,350205,280969,
        ,bytes_in,bytes_out,
        launchd.1,0,0,
        remoted.360,0,0,
        apsd.383,1200,800,
        com.apple.WebKit.Networking.812,64000,2000,
        Foo, Inc.123,10,5,
        garbage line
        nopid,1,1,
        """

    @Test func nettopUsesOnlyTheLastSampleBlock() {
        let rows = NettopParser.parseLastSample(nettopOutput)
        #expect(rows.first(where: { $0.pid == 383 })?.bytesIn == 1200)
        #expect(rows.count == 5)
    }

    @Test func nettopSplitsNameAndPidAtTheLastDot() {
        let rows = NettopParser.parseLastSample(nettopOutput)
        #expect(
            rows.contains(ProcessTraffic(name: "com.apple.WebKit.Networking", pid: 812, bytesIn: 64000, bytesOut: 2000))
        )
        #expect(rows.contains(ProcessTraffic(name: "Foo, Inc", pid: 123, bytesIn: 10, bytesOut: 5)))
    }

    @Test func nettopTopDropsIdleAndSortsByTotal() {
        let top = NettopParser.top(NettopParser.parseLastSample(nettopOutput), limit: 2)
        #expect(top.map(\.pid) == [812, 383])
    }

    @Test func nettopWithoutHeaderIsEmpty() {
        #expect(NettopParser.parseLastSample("nothing here").isEmpty)
    }

    let psOutput = """
          550  55.4 136208 logioptionsplus_updater
          794  34.1 251616 logioptionsplus_agent
          415  17.1 140896 WindowServer
         1201   3.0 512000 Google Chrome Helper (Renderer)
        bad row
            9   0.0      1
        """

    @Test func psParsesNamesWithSpaces() {
        let rows = PSParser.parse(psOutput)
        #expect(rows.count == 4)
        #expect(
            rows.contains(
                ProcessUsage(
                    pid: 1201, cpuPercent: 3.0, residentBytes: 512_000 * 1024, name: "Google Chrome Helper (Renderer)")
            ))
    }

    @Test func psTopByCPUAndMemory() {
        let rows = PSParser.parse(psOutput)
        #expect(PSParser.topByCPU(rows, limit: 2).map(\.pid) == [550, 794])
        #expect(PSParser.topByMemory(rows, limit: 2).map(\.pid) == [1201, 794])
    }
}
