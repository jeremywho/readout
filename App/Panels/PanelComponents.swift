import SwiftUI

struct PanelTitle: View {
    let title: String
    let detail: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.headline)
            Spacer()
            if let detail { Text(detail).font(.callout).foregroundStyle(.secondary).lineLimit(1) }
        }
    }
}

struct BigMetric: View {
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.system(.title2, design: .rounded).monospacedDigit()).foregroundStyle(tint)
        }
    }
}

struct InfoRows: View {
    let rows: [(String, String)]

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
            ForEach(rows.indices, id: \.self) { index in
                GridRow {
                    Text(rows[index].0).foregroundStyle(.secondary)
                    Text(rows[index].1).monospacedDigit().textSelection(.enabled).lineLimit(1)
                }
            }
        }
        .font(.callout)
    }
}

struct ProcessRows: View {
    let title: String
    let rows: [(String, String)]
    let unavailable: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            if unavailable {
                Text("unavailable").font(.callout).foregroundStyle(.secondary)
            } else if rows.isEmpty {
                Text("—").font(.callout).foregroundStyle(.secondary)
            } else {
                ForEach(rows.indices, id: \.self) { index in
                    HStack {
                        Text(rows[index].0).lineLimit(1)
                        Spacer()
                        Text(rows[index].1).monospacedDigit().foregroundStyle(.secondary)
                    }
                    .font(.callout)
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
