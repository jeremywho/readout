import CReadout
import Foundation
import ReadoutCore

public struct CPUReading: Sendable, Equatable {
    public var total: CoreLoad
    public var cores: [CoreLoad]
    public var groups: [CoreGroup]
    public var loadAverage: [Double]

    public init(total: CoreLoad, cores: [CoreLoad], groups: [CoreGroup], loadAverage: [Double]) {
        self.total = total
        self.cores = cores
        self.groups = groups
        self.loadAverage = loadAverage
    }
}

public final class CPUSampler {
    public typealias TicksSource = () -> [CoreTicks]?

    private let ticks: TicksSource
    private let clusterTypes: [Character]
    private let levels: [PerformanceLevel]
    private var groups: [CoreGroup] = []
    private var previous: [CoreTicks]?

    public init(
        ticks: @escaping TicksSource = CPUSampler.readTicks, clusterTypes: [Character]? = nil,
        levels: [PerformanceLevel]? = nil
    ) {
        self.ticks = ticks
        self.clusterTypes = clusterTypes ?? CPUSampler.readClusterTypes()
        self.levels = levels ?? CPUSampler.readLevels()
    }

    public func sample() -> CPUReading? {
        guard let current = ticks() else {
            previous = nil
            return nil
        }
        defer { previous = current }
        guard let previous, let loads = CPUMath.loads(previous: previous, current: current) else { return nil }
        if groups.reduce(0, { $0 + $1.cores.count }) != loads.count {
            groups = CoreTopology.groups(clusterTypes: clusterTypes, levels: levels, coreCount: loads.count)
        }
        return CPUReading(total: CPUMath.average(loads), cores: loads, groups: groups, loadAverage: Self.loadAverage())
    }

    public static func readTicks() -> [CoreTicks]? {
        var buffer = [readout_core_ticks](repeating: readout_core_ticks(), count: 512)
        let count = buffer.withUnsafeMutableBufferPointer { readout_read_core_ticks($0.baseAddress, Int32($0.count)) }
        guard count > 0 else { return nil }
        return buffer.prefix(Int(count)).map {
            CoreTicks(user: $0.user, system: $0.system, idle: $0.idle, nice: $0.nice)
        }
    }

    public static func readClusterTypes() -> [Character] {
        var buffer = [CChar](repeating: 0, count: 512)
        let count = buffer.withUnsafeMutableBufferPointer { readout_read_core_kinds($0.baseAddress, Int32($0.count)) }
        guard count > 0 else { return [] }
        return buffer.prefix(Int(count)).map { Character(Unicode.Scalar(UInt8(bitPattern: $0))) }
    }

    public static func readLevels() -> [PerformanceLevel] {
        guard let count = sysctlInt("hw.nperflevels"), count > 0 else { return [] }
        let levels = (0..<count).compactMap { level -> PerformanceLevel? in
            guard let name = sysctlString("hw.perflevel\(level).name"),
                let cores = sysctlInt("hw.perflevel\(level).logicalcpu")
            else { return nil }
            return PerformanceLevel(name: name, coreCount: cores)
        }
        return levels.count == count ? levels : []
    }

    static func loadAverage() -> [Double] {
        var values = [Double](repeating: 0, count: 3)
        return getloadavg(&values, 3) == 3 ? values : []
    }

    private static func sysctlInt(_ name: String) -> Int? {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        return sysctlbyname(name, &value, &size, nil, 0) == 0 ? Int(value) : nil
    }

    private static func sysctlString(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [UInt8](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
        let text = String(decoding: buffer.prefix { $0 != 0 }, as: UTF8.self)
        return text.isEmpty ? nil : text
    }
}
