import Observation
import ReadoutCore
import ReadoutSystem

@MainActor
@Observable
final class MetricsStore {
    private(set) var snapshot = MetricsSnapshot()
    private(set) var networkHistory = RingBuffer<ThroughputSample>(capacity: 600)
    private(set) var cpuHistory = RingBuffer<CoreLoad>(capacity: 600)
    private(set) var missingTemperatureTicks = 0

    var temperatureAvailable: Bool { missingTemperatureTicks < 10 }

    func apply(_ next: MetricsSnapshot) {
        snapshot = next
        if let throughput = next.network?.throughput { networkHistory.append(throughput) }
        if let cpu = next.cpu { cpuHistory.append(cpu.total) }
        missingTemperatureTicks = next.temperature?.summary.cpuCelsius == nil ? missingTemperatureTicks + 1 : 0
    }
}
