import Foundation
import ReadoutCore
import ReadoutSystem

extension MetricsStore {
    static func fixture() -> MetricsStore {
        let store = MetricsStore()
        let kinds: [CoreKind] = Array("EEPPPPPPPPEEPPPPPPPP").map { CoreKind(clusterType: $0) }
        for index in 0..<600 {
            let t = Double(index)
            let up = index == 599 ? 25_000 : 25_000 + 15_000 * sin(t / 9)
            let down = index == 599 ? 61_000 : 61_000 + 45_000 * sin(t / 13) + 30_000 * sin(t / 3)
            let cores = (0..<20).map { core in
                CoreLoad(
                    user: 0.10 + 0.08 * abs(sin(t / 7 + Double(core))),
                    system: 0.04 + 0.03 * abs(sin(t / 5 + Double(core))))
            }
            store.apply(
                MetricsSnapshot(
                    network: NetworkReading(
                        interface: "en1",
                        throughput: ThroughputSample(
                            upBytesPerSecond: up, downBytesPerSecond: max(down, 0), upBytes: 0, downBytes: 0),
                        sessionBytesIn: 1_830_000_000, sessionBytesOut: 412_000_000),
                    cpu: CPUReading(
                        total: CPUMath.average(cores), cores: cores, kinds: kinds, loadAverage: [2.31, 2.05, 1.88]),
                    memory: MemoryReading(
                        pressurePercent: 5,
                        breakdown: MemoryBreakdown(
                            app: 21_400_000_000, wired: 4_100_000_000, compressed: 600_000_000, cached: 18_200_000_000),
                        swapUsedBytes: 0, physicalBytes: 68_719_476_736),
                    disk: DiskReading(
                        usedPercent: 81, totalBytes: 1_995_218_165_760, availableBytes: 379_091_451_494,
                        readBytesPerSecond: 1_200_000, writeBytesPerSecond: 340_000),
                    temperature: TemperatureReading(
                        summary: TemperatureSummary(
                            cpuCelsius: 52.2, gpuCelsius: 41.6, hottest: SensorValue(key: "Tp02", celsius: 58.6)),
                        fanRPMs: [1340, 1338])))
        }
        return store
    }
}
