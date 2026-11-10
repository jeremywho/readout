import ReadoutCore
import SwiftUI

struct GPUPanel: View {
    @Environment(MetricsStore.self) private var store

    var body: some View {
        let reading = store.snapshot.gpu
        VStack(alignment: .leading, spacing: 10) {
            PanelTitle(title: "GPU", detail: reading?.model)
            BigMetric(label: "Usage", value: MenuBarText.percent(reading?.utilizationPercent))
            HistoryGraph(series: .usage(Array(store.gpuHistory.elements.suffix(120))))
            InfoRows(rows: [
                ("Memory in use", reading?.memoryInUseBytes.map(ByteCountText.memory) ?? "—"),
                (
                    "Temperature",
                    MenuBarText.temperature(
                        celsius: store.snapshot.temperature?.summary.gpuCelsius, unit: Preferences.temperatureUnit)
                ),
            ])
        }
    }
}
