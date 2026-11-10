import SwiftUI

struct PanelTitle: View {
    let title: String
    let detail: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(PanelStyle.title)
            Spacer()
            if let detail { Text(detail).font(PanelStyle.body).foregroundStyle(PanelStyle.secondary).lineLimit(1) }
        }
    }
}

struct BigMetric: View {
    let label: String
    let value: String
    var series: AdaptiveColor?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(PanelStyle.label).foregroundStyle(PanelStyle.secondary)
            Text(value).font(PanelStyle.metric)
                .foregroundStyle(series.map(AnyShapeStyle.init) ?? AnyShapeStyle(.primary))
        }
    }
}

struct InfoRows: View {
    let rows: [(String, String)]

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
            ForEach(rows.indices, id: \.self) { index in
                GridRow {
                    Text(rows[index].0).foregroundStyle(PanelStyle.secondary)
                    Text(rows[index].1).monospacedDigit().textSelection(.enabled).lineLimit(1)
                }
            }
        }
        .font(PanelStyle.body)
    }
}

struct ProcessRows: View {
    let title: String
    let rows: [(String, String)]
    let unavailable: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(PanelStyle.label).foregroundStyle(PanelStyle.secondary)
            if unavailable {
                Text("unavailable").font(PanelStyle.body).foregroundStyle(PanelStyle.secondary)
            } else if rows.isEmpty {
                Text("—").font(PanelStyle.body).foregroundStyle(PanelStyle.secondary)
            } else {
                ForEach(rows.indices, id: \.self) { index in
                    HStack {
                        Text(rows[index].0).lineLimit(1)
                        Spacer()
                        Text(rows[index].1).monospacedDigit().foregroundStyle(PanelStyle.secondary)
                    }
                    .font(PanelStyle.body)
                }
            }
        }
    }
}

enum ByteCountText {
    static func string(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(clamping: bytes), countStyle: .decimal)
    }

    static func memory(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(clamping: bytes), countStyle: .memory)
    }
}
