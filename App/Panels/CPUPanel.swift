import ReadoutCore
import ReadoutSystem
import SwiftUI

struct CPUPanel: View {
    @Environment(MetricsStore.self) private var store
    @Environment(ProcessMonitor.self) private var processes

    var body: some View {
        let reading = store.snapshot.cpu
        VStack(alignment: .leading, spacing: 10) {
            PanelTitle(title: "CPU", detail: reading.map { "\($0.cores.count) cores" })
            HStack(spacing: 24) {
                BigMetric(
                    label: "Total", value: MenuBarText.percent(reading.map { $0.total.total * 100 }), tint: .primary)
                BigMetric(
                    label: "User", value: MenuBarText.percent(reading.map { $0.total.user * 100 }),
                    tint: HistoryGraph.downColor)
                BigMetric(
                    label: "System", value: MenuBarText.percent(reading.map { $0.total.system * 100 }),
                    tint: HistoryGraph.upColor)
            }
            HistoryGraph(series: .cpu(Array(store.cpuHistory.elements.suffix(120))))
            if let reading {
                coreBars(reading, kind: .performance, label: "Performance cores")
                coreBars(reading, kind: .efficiency, label: "Efficiency cores")
                InfoRows(rows: [
                    ("Load average", reading.loadAverage.map { String(format: "%.2f", $0) }.joined(separator: "  "))
                ])
            }
            ProcessRows(
                title: "Top processes",
                rows: processes.topCPU.map { ($0.name, String(format: "%.1f%%", $0.cpuPercent)) },
                unavailable: processes.processesUnavailable)
        }
        .task { await processes.run(.cpu, interface: nil) }
    }

    @ViewBuilder
    private func coreBars(_ reading: CPUReading, kind: CoreKind, label: String) -> some View {
        let loads = zip(reading.cores, reading.kinds).filter { $0.1 == kind }.map(\.0)
        if !loads.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(loads.indices, id: \.self) { index in
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            Rectangle().fill(HistoryGraph.downColor).frame(height: 28 * CGFloat(loads[index].user))
                            Rectangle().fill(HistoryGraph.upColor).frame(height: 28 * CGFloat(loads[index].system))
                        }
                        .frame(width: 8, height: 28)
                        .background(RoundedRectangle(cornerRadius: 2).fill(.quaternary.opacity(0.5)))
                    }
                }
            }
        }
    }
}
