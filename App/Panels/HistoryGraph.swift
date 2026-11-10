import ReadoutCore
import SwiftUI

struct HistoryGraph: View {
    enum Series {
        case network([ThroughputSample])
        case cpu([CoreLoad])
        case usage([Double])
    }

    let series: Series

    var body: some View {
        Canvas { context, size in
            switch series {
            case .network(let samples):
                let peak = max(samples.map { max($0.upBytesPerSecond, $0.downBytesPerSecond) }.max() ?? 0, 1)
                context.stroke(
                    path(samples.map(\.downBytesPerSecond), peak: peak, in: size), with: .style(PanelStyle.download),
                    lineWidth: 1.5)
                context.stroke(
                    path(samples.map(\.upBytesPerSecond), peak: peak, in: size), with: .style(PanelStyle.upload),
                    lineWidth: 1.5)
            case .cpu(let loads):
                let step = size.width / CGFloat(max(loads.count, 1))
                for (index, load) in loads.enumerated() {
                    let x = CGFloat(index) * step
                    let systemHeight = size.height * CGFloat(load.system)
                    let userHeight = size.height * CGFloat(load.user)
                    context.fill(
                        Path(CGRect(x: x, y: size.height - systemHeight, width: max(step, 1), height: systemHeight)),
                        with: .style(PanelStyle.upload))
                    context.fill(
                        Path(
                            CGRect(
                                x: x, y: size.height - systemHeight - userHeight, width: max(step, 1),
                                height: userHeight)),
                        with: .style(PanelStyle.download))
                }
            case .usage(let percents):
                let step = size.width / CGFloat(max(percents.count, 1))
                for (index, percent) in percents.enumerated() {
                    let height = size.height * CGFloat(min(max(percent, 0), 100) / 100)
                    context.fill(
                        Path(
                            CGRect(
                                x: CGFloat(index) * step, y: size.height - height, width: max(step, 1), height: height)),
                        with: .style(PanelStyle.download))
                }
            }
        }
        .frame(height: 64)
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary.opacity(0.5)))
        .overlay(alignment: .topTrailing) {
            if let peakLabel {
                Text(peakLabel).font(PanelStyle.label).foregroundStyle(PanelStyle.secondary).padding(.horizontal, 6)
                    .background(Capsule().fill(PanelStyle.surface.opacity(0.8))).padding(6)
            }
        }
    }

    private var peakLabel: String? {
        guard case .network(let samples) = series else { return nil }
        let peak = samples.map { max($0.upBytesPerSecond, $0.downBytesPerSecond) }.max() ?? 0
        return "peak \(ByteRateFormatter.string(bytesPerSecond: peak))"
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
