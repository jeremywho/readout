import Observation
import ReadoutCore
import ReadoutSystem

@MainActor
@Observable
final class MetricsStore {
    private(set) var snapshot = MetricsSnapshot()
    private(set) var networkHistory = RingBuffer<ThroughputSample>(capacity: 600)
    private(set) var cpuHistory = RingBuffer<CoreLoad>(capacity: 600)
    private(set) var gpuHistory = RingBuffer<Double>(capacity: 600)
    private(set) var missingTemperatureTicks = 0
    private(set) var missingGPUTicks = 0

    var temperatureAvailable: Bool { missingTemperatureTicks < Self.missingTickLimit }

    func isAvailable(_ kind: MeterKind) -> Bool {
        switch kind {
        case .temperature: temperatureAvailable
        case .gpu: missingGPUTicks < Self.missingTickLimit
        case .network, .disk, .cpu, .memory: true
        }
    }

    private static let missingTickLimit = 10

    func apply(_ next: MetricsSnapshot) {
        snapshot = next
        if let throughput = next.network?.throughput { networkHistory.append(throughput) }
        if let cpu = next.cpu { cpuHistory.append(cpu.total) }
        if let gpu = next.gpu { gpuHistory.append(gpu.utilizationPercent) }
        missingTemperatureTicks = next.temperature?.summary.cpuCelsius == nil ? missingTemperatureTicks + 1 : 0
        missingGPUTicks = next.gpu == nil ? missingGPUTicks + 1 : 0
    }
}
