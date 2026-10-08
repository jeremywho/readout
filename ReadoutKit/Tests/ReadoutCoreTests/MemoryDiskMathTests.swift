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

    @Test func diskUsedPercentMatchesIStatOnRecordedMacstudioValues() throws {
        let percent = try #require(
            DiskMath.usedPercent(
                volumeUsedBytes: 1_729_511_211_008, totalBytes: 1_995_218_165_760,
                availableForImportantUsage: 367_672_773_679, containerFreeBytes: 242_417_848_320))
        #expect(abs(percent - 80.4050561) < 0.0001)
        #expect(MenuBarText.percent(percent) == "80%")
    }

    @Test func diskPurgeableIsNeverNegative() {
        let percent = DiskMath.usedPercent(
            volumeUsedBytes: 500, totalBytes: 1_000, availableForImportantUsage: 100, containerFreeBytes: 300)
        #expect(percent == 50)
    }

    @Test func diskUsedIsClampedToTheContainer() {
        #expect(
            DiskMath.usedPercent(
                volumeUsedBytes: 5_000, totalBytes: 1_000, availableForImportantUsage: 0, containerFreeBytes: 0)
                == 100)
        #expect(
            DiskMath.usedPercent(
                volumeUsedBytes: 100, totalBytes: 1_000, availableForImportantUsage: 900, containerFreeBytes: 0)
                == 0)
    }

    @Test func diskUsedPercentRejectsNonsense() {
        #expect(
            DiskMath.usedPercent(
                volumeUsedBytes: 1, totalBytes: 0, availableForImportantUsage: 0, containerFreeBytes: 0) == nil)
        #expect(
            DiskMath.usedPercent(
                volumeUsedBytes: -1, totalBytes: 100, availableForImportantUsage: 0, containerFreeBytes: 0) == nil)
        #expect(
            DiskMath.usedPercent(
                volumeUsedBytes: 1, totalBytes: 100, availableForImportantUsage: -1, containerFreeBytes: 0) == nil)
    }
}
