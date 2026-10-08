import ReadoutCore

enum MeterContent: Equatable, Sendable {
    case captioned(caption: String, value: String)
    case network(up: String, down: String)
    case graph(loads: [CoreLoad])
    case memory(value: String, fraction: Double)
}

enum MeterContentBuilder {
    @MainActor
    static func content(for kind: MeterKind, store: MetricsStore, unit: TemperatureUnit) -> MeterContent {
        let snapshot = store.snapshot
        switch kind {
        case .temperature:
            return .captioned(
                caption: "CPU",
                value: MenuBarText.temperature(celsius: snapshot.temperature?.summary.cpuCelsius, unit: unit))
        case .network:
            let text = MenuBarText.network(snapshot.network?.throughput)
            return .network(up: text.up, down: text.down)
        case .disk:
            return .captioned(caption: "SSD", value: MenuBarText.percent(snapshot.disk?.usedPercent))
        case .cpu:
            return .graph(loads: Array(store.cpuHistory.elements.suffix(MeterDrawing.graphColumns)))
        case .memory:
            let pressure = snapshot.memory.map { Double($0.pressurePercent) }
            return .memory(value: MenuBarText.percent(pressure), fraction: (pressure ?? 0) / 100)
        }
    }
}
