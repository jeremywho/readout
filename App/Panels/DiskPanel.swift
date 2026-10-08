import ReadoutCore
import SwiftUI

struct DiskPanel: View {
    @Environment(MetricsStore.self) private var store

    var body: some View {
        let reading = store.snapshot.disk
        VStack(alignment: .leading, spacing: 10) {
            PanelTitle(title: "Disk", detail: "Startup volume")
            BigMetric(label: "Used", value: MenuBarText.percent(reading?.usedPercent), tint: .primary)
            InfoRows(rows: [
                ("Free", reading.map { ByteCountText.string(UInt64(max($0.availableBytes, 0))) } ?? "—"),
                ("Total", reading.map { ByteCountText.string(UInt64(max($0.totalBytes, 0))) } ?? "—"),
                ("Read", reading?.readBytesPerSecond.map { ByteRateFormatter.string(bytesPerSecond: $0) } ?? "—"),
                ("Write", reading?.writeBytesPerSecond.map { ByteRateFormatter.string(bytesPerSecond: $0) } ?? "—"),
            ])
            Text("Read and write rates include every attached drive.").font(.caption).foregroundStyle(.secondary)
        }
    }
}
