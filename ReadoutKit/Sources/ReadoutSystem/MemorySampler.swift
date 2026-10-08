import CReadout
import Foundation
import ReadoutCore

public struct MemoryReading: Sendable, Equatable {
    public var pressurePercent: Int
    public var breakdown: MemoryBreakdown?
    public var swapUsedBytes: UInt64?
    public var physicalBytes: UInt64

    public init(pressurePercent: Int, breakdown: MemoryBreakdown?, swapUsedBytes: UInt64?, physicalBytes: UInt64) {
        self.pressurePercent = pressurePercent
        self.breakdown = breakdown
        self.swapUsedBytes = swapUsedBytes
        self.physicalBytes = physicalBytes
    }
}

public struct MemorySampler: Sendable {
    public init() {}

    public func sample() -> MemoryReading? {
        let level = readout_read_memorystatus_level()
        guard level >= 0 else { return nil }
        var pages = readout_vm_pages()
        let breakdown =
            readout_read_vm_pages(&pages) == 0
            ? MemoryMath.breakdown(
                VMPages(
                    internalPages: pages.internal_pages, purgeablePages: pages.purgeable_pages,
                    externalPages: pages.external_pages, wiredPages: pages.wired_pages,
                    compressorPages: pages.compressor_pages, pageSize: pages.page_size))
            : nil
        var used: UInt64 = 0
        var total: UInt64 = 0
        let swap = readout_read_swap(&used, &total) == 0 ? used : nil
        return MemoryReading(
            pressurePercent: MemoryMath.pressurePercent(memorystatusLevel: Int(level)),
            breakdown: breakdown,
            swapUsedBytes: swap,
            physicalBytes: ProcessInfo.processInfo.physicalMemory
        )
    }
}
