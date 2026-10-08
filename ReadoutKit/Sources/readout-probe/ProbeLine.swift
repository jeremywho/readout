import Foundation
import ReadoutCore
import ReadoutSystem

enum ProbeLine {
    static func render(_ snapshot: MetricsSnapshot, at date: Date = Date()) -> String {
        let time = date.formatted(date: .omitted, time: .standard)
        let network = MenuBarText.network(snapshot.network?.throughput)
        let interface = snapshot.network?.interface ?? "none"
        let cpu = snapshot.cpu.map { "\(Int(($0.total.total * 100).rounded()))%" } ?? "—"
        let memory = snapshot.memory.map { "\($0.pressurePercent)%" } ?? "—"
        let disk = snapshot.disk.map { String(format: "%.1f%%", $0.usedPercent) } ?? "—"
        let summary = snapshot.temperature?.summary
        let cpuTemperature =
            summary?.cpuCelsius.map {
                String(format: "%.1f°C/%.0f°F", $0, TemperatureUnit.convert(celsius: $0, to: .fahrenheit))
            } ?? "—"
        let gpuTemperature = summary?.gpuCelsius.map { String(format: "%.1f°C", $0) } ?? "—"
        let fans = snapshot.temperature?.fanRPMs.map { String(Int($0.rounded())) }.joined(separator: ",") ?? "—"
        return
            "\(time) net \(interface) ↑ \(network.up) ↓ \(network.down) | cpu \(cpu) | mem \(memory) | disk \(disk) | temp cpu \(cpuTemperature) gpu \(gpuTemperature) | fans \(fans)"
    }
}
