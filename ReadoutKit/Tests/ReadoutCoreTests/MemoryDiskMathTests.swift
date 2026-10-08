import Testing

@testable import ReadoutCore

@Suite struct MemoryDiskMathTests {
    @Test func pressureIsInverseOfMemorystatusLevel() {
        #expect(MemoryMath.pressurePercent(memorystatusLevel: 96) == 4)
        #expect(MemoryMath.pressurePercent(memorystatusLevel: 0) == 100)
        #expect(MemoryMath.pressurePercent(memorystatusLevel: 120) == 0)
        #expect(MemoryMath.pressurePercent(memorystatusLevel: -5) == 100)
    }

    @Test func breakdownFollowsActivityMonitorDefinitions() {
        let pages = VMPages(
            internalPages: 1_000, purgeablePages: 100, externalPages: 300,
            wiredPages: 200, compressorPages: 50, pageSize: 16_384
        )
        let breakdown = MemoryMath.breakdown(pages)
        #expect(breakdown.app == 900 * 16_384)
        #expect(breakdown.wired == 200 * 16_384)
        #expect(breakdown.compressed == 50 * 16_384)
        #expect(breakdown.cached == 400 * 16_384)
        #expect(breakdown.used == 1_150 * 16_384)
    }

    @Test func breakdownNeverUnderflowsWhenPurgeableExceedsInternal() {
        let pages = VMPages(
            internalPages: 10, purgeablePages: 20, externalPages: 0,
            wiredPages: 0, compressorPages: 0, pageSize: 4_096
        )
        #expect(MemoryMath.breakdown(pages).app == 0)
    }

    @Test func diskUsedPercentCountsPurgeableAsFree() {
        #expect(DiskMath.usedPercent(totalBytes: 2_000, availableBytes: 380) == 81)
    }

    @Test func diskUsedPercentRejectsNonsense() {
        #expect(DiskMath.usedPercent(totalBytes: 0, availableBytes: 0) == nil)
        #expect(DiskMath.usedPercent(totalBytes: 100, availableBytes: -1) == nil)
        #expect(DiskMath.usedPercent(totalBytes: 100, availableBytes: 150) == 0)
    }
}
