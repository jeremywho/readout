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
                BigMetric(label: "Total", value: MenuBarText.percent(reading.map { $0.total.total * 100 }))
                BigMetric(
                    label: "User", value: MenuBarText.percent(reading.map { $0.total.user * 100 }),
                    series: PanelStyle.download)
                BigMetric(
                    label: "System", value: MenuBarText.percent(reading.map { $0.total.system * 100 }),
                    series: PanelStyle.upload)
            }
            HistoryGraph(series: .cpu(Array(store.cpuHistory.elements.suffix(120))))
            if let reading {
                ForEach(reading.groups.indices, id: \.self) { coreBars(reading.groups[$0], loads: reading.cores) }
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

    /// 64 bars at their 2 pt minimum need 254 pt, which fits the panel's content width.
    private static let maxBarsPerRow = 64

    private func coreBars(_ group: CoreGroup, loads: [CoreLoad]) -> some View {
        let rows = CoreTopology.rows(group.cores.filter(loads.indices.contains), maxPerRow: Self.maxBarsPerRow)
        return VStack(alignment: .leading, spacing: 3) {
            Text(group.name.map { "\($0) cores" } ?? "Cores").font(PanelStyle.label).foregroundStyle(
                PanelStyle.secondary)
            ForEach(rows.indices, id: \.self) { row in
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(rows[row], id: \.self) { core in
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            Rectangle().fill(PanelStyle.download).frame(height: 28 * CGFloat(loads[core].user))
                            Rectangle().fill(PanelStyle.upload).frame(height: 28 * CGFloat(loads[core].system))
                        }
                        .frame(minWidth: 2, maxWidth: 8)
                        .frame(height: 28)
                        .background(RoundedRectangle(cornerRadius: 2).fill(.quaternary.opacity(0.5)))
                    }
                }
            }
        }
    }
}
