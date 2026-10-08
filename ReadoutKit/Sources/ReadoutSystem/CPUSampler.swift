import CReadout
import Foundation
import ReadoutCore

public struct CPUReading: Sendable, Equatable {
    public var total: CoreLoad
    public var cores: [CoreLoad]
    public var kinds: [CoreKind]
    public var loadAverage: [Double]

    public init(total: CoreLoad, cores: [CoreLoad], kinds: [CoreKind], loadAverage: [Double]) {
        self.total = total
        self.cores = cores
        self.kinds = kinds
        self.loadAverage = loadAverage
    }
}

public final class CPUSampler {
    public typealias TicksSource = () -> [CoreTicks]?

    private let ticks: TicksSource
    private let kinds: [CoreKind]
    private var previous: [CoreTicks]?

    public init(ticks: @escaping TicksSource = CPUSampler.readTicks, kinds: [CoreKind]? = nil) {
        self.ticks = ticks
        self.kinds = kinds ?? CPUSampler.readKinds()
    }

    public func sample() -> CPUReading? {
        guard let current = ticks() else {
            previous = nil
            return nil
        }
        defer { previous = current }
        guard let previous, let loads = CPUMath.loads(previous: previous, current: current) else { return nil }
        let coreKinds = kinds.count == loads.count ? kinds : Array(repeating: .performance, count: loads.count)
        return CPUReading(
            total: CPUMath.average(loads), cores: loads, kinds: coreKinds, loadAverage: Self.loadAverage())
    }

    public static func readTicks() -> [CoreTicks]? {
        var buffer = [readout_core_ticks](repeating: readout_core_ticks(), count: 512)
        let count = buffer.withUnsafeMutableBufferPointer { readout_read_core_ticks($0.baseAddress, Int32($0.count)) }
        guard count > 0 else { return nil }
        return buffer.prefix(Int(count)).map {
            CoreTicks(user: $0.user, system: $0.system, idle: $0.idle, nice: $0.nice)
        }
    }

    public static func readKinds() -> [CoreKind] {
        var buffer = [CChar](repeating: 0, count: 512)
        let count = buffer.withUnsafeMutableBufferPointer { readout_read_core_kinds($0.baseAddress, Int32($0.count)) }
        guard count > 0 else { return [] }
        return buffer.prefix(Int(count)).map { CoreKind(clusterType: Character(Unicode.Scalar(UInt8(bitPattern: $0)))) }
    }

    static func loadAverage() -> [Double] {
        var values = [Double](repeating: 0, count: 3)
        return getloadavg(&values, 3) == 3 ? values : []
    }
}
