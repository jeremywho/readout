import ReadoutCore
import SwiftUI

struct HistoryGraph: View {
    enum Series {
        case network([ThroughputSample])
        case cpu([CoreLoad])
    }

    static let downColor = Color(red: 0.27, green: 0.47, blue: 1.0)
    static let upColor = Color(red: 1.0, green: 0.30, blue: 0.55)

    let series: Series

    var body: some View {
        Canvas { context, size in
            switch series {
            case .network(let samples):
                let peak = max(samples.map { max($0.upBytesPerSecond, $0.downBytesPerSecond) }.max() ?? 0, 1)
                context.stroke(
                    path(samples.map(\.downBytesPerSecond), peak: peak, in: size), with: .color(Self.downColor),
                    lineWidth: 1.5)
                context.stroke(
                    path(samples.map(\.upBytesPerSecond), peak: peak, in: size), with: .color(Self.upColor),
                    lineWidth: 1.5)
            case .cpu(let loads):
                let step = size.width / CGFloat(max(loads.count, 1))
                for (index, load) in loads.enumerated() {
                    let x = CGFloat(index) * step
                    let systemHeight = size.height * CGFloat(load.system)
                    let userHeight = size.height * CGFloat(load.user)
                    context.fill(
                        Path(CGRect(x: x, y: size.height - systemHeight, width: max(step, 1), height: systemHeight)),
                        with: .color(Self.upColor))
                    context.fill(
                        Path(
                            CGRect(
                                x: x, y: size.height - systemHeight - userHeight, width: max(step, 1),
                                height: userHeight)),
                        with: .color(Self.downColor))
                }
            }
        }
        .frame(height: 64)
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary.opacity(0.5)))
        .overlay(alignment: .topLeading) {
            if case .network(let samples) = series {
                let peak = samples.map { max($0.upBytesPerSecond, $0.downBytesPerSecond) }.max() ?? 0
                Text("peak \(ByteRateFormatter.string(bytesPerSecond: peak))").font(.caption2).foregroundStyle(
                    .secondary
                ).padding(8)
            }
        }
    }

    private func path(_ values: [Double], peak: Double, in size: CGSize) -> Path {
        var path = Path()
        guard values.count > 1 else { return path }
        for (index, value) in values.enumerated() {
            let point = CGPoint(
                x: size.width * CGFloat(index) / CGFloat(values.count - 1),
                y: size.height * (1 - CGFloat(min(value / peak, 1))))
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }
}
