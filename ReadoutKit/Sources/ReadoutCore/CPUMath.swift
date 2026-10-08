public struct CoreTicks: Sendable, Equatable {
    public var user: UInt32
    public var system: UInt32
    public var idle: UInt32
    public var nice: UInt32

    public init(user: UInt32, system: UInt32, idle: UInt32, nice: UInt32) {
        self.user = user
        self.system = system
        self.idle = idle
        self.nice = nice
    }
}

public struct CoreLoad: Sendable, Equatable {
    public var user: Double
    public var system: Double
    public var total: Double { user + system }

    public static let idle = CoreLoad(user: 0, system: 0)

    public init(user: Double, system: Double) {
        self.user = user
        self.system = system
    }
}

public enum CoreKind: Sendable, Equatable {
    case performance
    case efficiency

    public init(clusterType: Character) {
        self = clusterType == "E" ? .efficiency : .performance
    }
}

public enum CPUMath {
    public static func load(previous: CoreTicks, current: CoreTicks) -> CoreLoad {
        let user =
            UInt64(CounterDelta.ticks(previous: previous.user, current: current.user))
            + UInt64(CounterDelta.ticks(previous: previous.nice, current: current.nice))
        let system = UInt64(CounterDelta.ticks(previous: previous.system, current: current.system))
        let idle = UInt64(CounterDelta.ticks(previous: previous.idle, current: current.idle))
        let total = user + system + idle
        guard total > 0 else { return .idle }
        return CoreLoad(user: Double(user) / Double(total), system: Double(system) / Double(total))
    }

    public static func loads(previous: [CoreTicks], current: [CoreTicks]) -> [CoreLoad]? {
        guard !current.isEmpty, previous.count == current.count else { return nil }
        return zip(previous, current).map { load(previous: $0, current: $1) }
    }

    public static func average(_ loads: [CoreLoad]) -> CoreLoad {
        guard !loads.isEmpty else { return .idle }
        let count = Double(loads.count)
        return CoreLoad(
            user: loads.reduce(0) { $0 + $1.user } / count,
            system: loads.reduce(0) { $0 + $1.system } / count
        )
    }
}
