import ReadoutCore
import SwiftUI

struct NetworkPanel: View {
    @Environment(MetricsStore.self) private var store
    @Environment(ProcessMonitor.self) private var processes

    var body: some View {
        let reading = store.snapshot.network
        let text = MenuBarText.network(reading?.throughput)
        VStack(alignment: .leading, spacing: 10) {
            PanelTitle(
                title: "Network",
                detail: reading?.interface.map { "\(processes.interfaceDisplayName ?? $0) (\($0))" } ?? "Not connected")
            HStack(spacing: 24) {
                BigMetric(label: "Upload", value: text.up, tint: HistoryGraph.upColor)
                BigMetric(label: "Download", value: text.down, tint: HistoryGraph.downColor)
            }
            HistoryGraph(series: .network(store.networkHistory.elements))
            InfoRows(rows: [
                ("Local IP", processes.localAddresses.first ?? "—"),
                ("Public IP", processes.publicIP ?? "…"),
                ("Session ↑", ByteCountText.string(reading?.sessionBytesOut ?? 0)),
                ("Session ↓", ByteCountText.string(reading?.sessionBytesIn ?? 0)),
            ])
            ProcessRows(
                title: "Top apps (last second)",
                rows: processes.topTraffic.map {
                    (
                        $0.name,
                        "↓ \(ByteRateFormatter.string(bytesPerSecond: Double($0.bytesIn)))  ↑ \(ByteRateFormatter.string(bytesPerSecond: Double($0.bytesOut)))"
                    )
                },
                unavailable: processes.trafficUnavailable)
        }
        .task(id: reading?.interface) { await processes.run(.network, interface: reading?.interface) }
    }
}
