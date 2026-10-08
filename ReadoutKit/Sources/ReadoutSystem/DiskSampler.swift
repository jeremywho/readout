import CReadout
import Foundation
import ReadoutCore

public struct DiskReading: Sendable, Equatable {
    public var usedPercent: Double
    public var totalBytes: Int64
    public var availableBytes: Int64
    public var readBytesPerSecond: Double?
    public var writeBytesPerSecond: Double?

    public init(
        usedPercent: Double, totalBytes: Int64, availableBytes: Int64,
        readBytesPerSecond: Double?, writeBytesPerSecond: Double?
    ) {
        self.usedPercent = usedPercent
        self.totalBytes = totalBytes
        self.availableBytes = availableBytes
        self.readBytesPerSecond = readBytesPerSecond
        self.writeBytesPerSecond = writeBytesPerSecond
    }
}

public final class DiskSampler {
    private struct Capacity {
        var total: Int64
        var available: Int64
        var percent: Double
        var measuredAt: Double
    }

    private var volume: URL
    private let dataVolumePath: String
    private let capacityInterval: Double
    private var capacity: Capacity?
    private var meter = RateMeter()

    public init(
        volume: URL = URL(fileURLWithPath: "/"), dataVolumePath: String = "/System/Volumes/Data",
        capacityInterval: Double = 30
    ) {
        self.volume = volume
        self.dataVolumePath = dataVolumePath
        self.capacityInterval = capacityInterval
    }

    public func sample(at seconds: Double) -> DiskReading? {
        if capacity == nil || seconds - (capacity?.measuredAt ?? 0) >= capacityInterval {
            capacity = measureCapacity(at: seconds) ?? capacity
        }
        guard let capacity else { return nil }
        var read: UInt64 = 0
        var written: UInt64 = 0
        let io = readout_read_disk_io(&read, &written) == 0 ? meter.update(up: written, down: read, at: seconds) : nil
        return DiskReading(
            usedPercent: capacity.percent, totalBytes: capacity.total, availableBytes: capacity.available,
            readBytesPerSecond: io?.downBytesPerSecond, writeBytesPerSecond: io?.upBytesPerSecond)
    }

    private func measureCapacity(at seconds: Double) -> Capacity? {
        volume.removeAllCachedResourceValues()
        guard
            let values = try? volume.resourceValues(forKeys: [
                .volumeTotalCapacityKey, .volumeAvailableCapacityKey, .volumeAvailableCapacityForImportantUsageKey,
            ]),
            let totalCapacity = values.volumeTotalCapacity,
            let containerFree = values.volumeAvailableCapacity,
            let important = values.volumeAvailableCapacityForImportantUsage
        else { return nil }
        let total = Int64(totalCapacity)
        var volumeUsed: Int64 = 0
        if readout_read_volume_used(dataVolumePath, &volumeUsed) != 0 {
            volumeUsed = total - Int64(containerFree)
        }
        guard
            let percent = DiskMath.usedPercent(
                volumeUsedBytes: volumeUsed, totalBytes: total, availableForImportantUsage: important,
                containerFreeBytes: Int64(containerFree))
        else { return nil }
        let available = total - Int64((Double(total) * percent / 100).rounded())
        return Capacity(total: total, available: available, percent: percent, measuredAt: seconds)
    }
}
