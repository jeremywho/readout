import ReadoutCore
import SwiftUI

struct TemperaturePanel: View {
    @Environment(MetricsStore.self) private var store

    var body: some View {
        let unit = Preferences.temperatureUnit
        let reading = store.snapshot.temperature
        VStack(alignment: .leading, spacing: 10) {
            PanelTitle(title: "Temperature", detail: nil)
            if store.temperatureAvailable, let reading {
                HStack(spacing: 24) {
                    BigMetric(
                        label: "CPU", value: MenuBarText.temperature(celsius: reading.summary.cpuCelsius, unit: unit))
                    BigMetric(
                        label: "GPU", value: MenuBarText.temperature(celsius: reading.summary.gpuCelsius, unit: unit))
                }
                InfoRows(
                    rows: [
                        (
                            "Hottest",
                            reading.summary.hottest.map {
                                "\($0.key)  \(MenuBarText.temperature(celsius: $0.celsius, unit: unit))"
                            } ?? "—"
                        )
                    ]
                        + reading.fanRPMs.enumerated().map {
                            ("Fan \($0.offset + 1)", "\(Int($0.element.rounded())) rpm")
                        })
            } else {
                Text("Temperature sensors are not available on this Mac.").font(PanelStyle.body).foregroundStyle(
                    PanelStyle.secondary)
            }
        }
    }
}
