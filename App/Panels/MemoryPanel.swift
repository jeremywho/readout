import ReadoutCore
import SwiftUI

struct MemoryPanel: View {
    @Environment(MetricsStore.self) private var store
    @Environment(ProcessMonitor.self) private var processes

    var body: some View {
        let reading = store.snapshot.memory
        VStack(alignment: .leading, spacing: 10) {
            PanelTitle(title: "Memory", detail: reading.map { ByteCountText.memory($0.physicalBytes) })
            BigMetric(
                label: "Pressure", value: MenuBarText.percent(reading.map { Double($0.pressurePercent) }),
                tint: .primary)
            if let breakdown = reading?.breakdown {
                InfoRows(rows: [
                    ("Used", ByteCountText.memory(breakdown.used)),
                    ("App", ByteCountText.memory(breakdown.app)),
                    ("Wired", ByteCountText.memory(breakdown.wired)),
                    ("Compressed", ByteCountText.memory(breakdown.compressed)),
                    ("Cached files", ByteCountText.memory(breakdown.cached)),
                    ("Swap used", reading?.swapUsedBytes.map(ByteCountText.memory) ?? "—"),
                ])
            }
            ProcessRows(
                title: "Top processes",
                rows: processes.topMemory.map { ($0.name, ByteCountText.memory($0.residentBytes)) },
                unavailable: processes.processesUnavailable)
        }
        .task { await processes.run(.memory, interface: nil) }
    }
}
