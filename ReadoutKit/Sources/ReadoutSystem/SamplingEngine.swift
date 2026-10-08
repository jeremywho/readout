import ReadoutCore

public struct MetricsSnapshot: Sendable, Equatable {
    public var network: NetworkReading?
    public var cpu: CPUReading?
    public var memory: MemoryReading?
    public var disk: DiskReading?
    public var temperature: TemperatureReading?

    public init(
        network: NetworkReading? = nil, cpu: CPUReading? = nil, memory: MemoryReading? = nil,
        disk: DiskReading? = nil, temperature: TemperatureReading? = nil
    ) {
        self.network = network
        self.cpu = cpu
        self.memory = memory
        self.disk = disk
        self.temperature = temperature
    }
}

public actor SamplingEngine {
    private let network = NetworkSampler()
    private let cpu = CPUSampler()
    private let memory = MemorySampler()
    private let disk = DiskSampler()
    private let temperature = SMCSampler()
    private let clock = ContinuousClock()
    private let start: ContinuousClock.Instant

    public init() {
        start = ContinuousClock.now
    }

    public func setInterfaceSelection(_ selection: InterfaceSelection) {
        network.selection = selection
    }

    public func tick() -> MetricsSnapshot {
        let elapsed = clock.now - start
        let seconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
        return MetricsSnapshot(
            network: network.sample(at: seconds),
            cpu: cpu.sample(),
            memory: memory.sample(),
            disk: disk.sample(at: seconds),
            temperature: temperature.sample()
        )
    }

    public func temperatureSensors() -> [SensorValue] {
        temperature.allTemperatureSensors()
    }
}
