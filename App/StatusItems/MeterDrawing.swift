import AppKit
import ReadoutCore

@MainActor
enum MeterDrawing {
    static let graphColumns = 20
    static let height: CGFloat = NSStatusBar.system.thickness
    static let captionFont = NSFont.systemFont(ofSize: 8.5, weight: .medium)
    static let valueFont = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
    static let networkFont = NSFont.monospacedDigitSystemFont(ofSize: 9.5, weight: .regular)
    static let userColor = NSColor(srgbRed: 0.27, green: 0.47, blue: 1.0, alpha: 1)
    static let systemColor = NSColor(srgbRed: 1.0, green: 0.30, blue: 0.55, alpha: 1)
    private static let horizontalPadding: CGFloat = 4

    static func width(for content: MeterContent) -> CGFloat {
        switch content {
        case .captioned(let caption, let value):
            let widest = max(textWidth(caption, captionFont), textWidth(value, valueFont), textWidth("100%", valueFont))
            return ceil(widest) + horizontalPadding * 2
        case .network(let up, let down):
            let widest = max(
                textWidth("↓ 999 KB/s", networkFont), textWidth("↑ " + up, networkFont),
                textWidth("↓ " + down, networkFont))
            return ceil(widest) + horizontalPadding * 2
        case .graph:
            return CGFloat(graphColumns * 3) + 3 + horizontalPadding * 2
        case .memory(let value, _):
            let widest = max(textWidth("MEM", captionFont), textWidth(value, valueFont), textWidth("100%", valueFont))
            return ceil(widest) + 4 + 6 + horizontalPadding * 2
        }
    }

    static func draw(_ content: MeterContent, in rect: NSRect) {
        let inner = rect.insetBy(dx: horizontalPadding, dy: 0)
        switch content {
        case .captioned(let caption, let value):
            drawCaptioned(caption: caption, value: value, in: inner)
        case .network(let up, let down):
            drawNetwork(up: up, down: down, in: inner)
        case .graph(let loads):
            drawGraph(loads, in: inner)
        case .memory(let value, let fraction):
            let textRect = NSRect(x: inner.minX, y: inner.minY, width: inner.width - 10, height: inner.height)
            drawCaptioned(caption: "MEM", value: value, in: textRect)
            drawPressureBar(
                fraction: fraction, in: NSRect(x: inner.maxX - 6, y: inner.minY + 4, width: 6, height: inner.height - 8)
            )
        }
    }

    private static func textWidth(_ text: String, _ font: NSFont) -> CGFloat {
        (text as NSString).size(withAttributes: [.font: font]).width
    }

    private static func drawText(_ text: String, font: NSFont, at point: NSPoint, color: NSColor = .labelColor) {
        (text as NSString).draw(at: point, withAttributes: [.font: font, .foregroundColor: color])
    }

    private static func drawCaptioned(caption: String, value: String, in rect: NSRect) {
        let captionHeight = (caption as NSString).size(withAttributes: [.font: captionFont]).height
        drawText(caption, font: captionFont, at: NSPoint(x: rect.minX, y: rect.maxY - captionHeight + 1))
        drawText(value, font: valueFont, at: NSPoint(x: rect.minX, y: rect.minY - 3))
    }

    private static func drawNetwork(up: String, down: String, in rect: NSRect) {
        let lineHeight = rect.height / 2
        for (row, (arrow, value)) in [("↑", up), ("↓", down)].enumerated() {
            let y = rect.maxY - lineHeight * CGFloat(row + 1) + 0.5
            drawText(arrow, font: networkFont, at: NSPoint(x: rect.minX, y: y))
            let width = textWidth(value, networkFont)
            drawText(value, font: networkFont, at: NSPoint(x: rect.maxX - width, y: y))
        }
    }

    private static func drawGraph(_ loads: [CoreLoad], in rect: NSRect) {
        let frame = NSRect(x: rect.minX, y: rect.minY + 3, width: rect.width, height: rect.height - 6)
        NSColor.labelColor.withAlphaComponent(0.55).setStroke()
        let outline = NSBezierPath(roundedRect: frame.insetBy(dx: 0.5, dy: 0.5), xRadius: 3, yRadius: 3)
        outline.lineWidth = 1
        outline.stroke()
        let plot = frame.insetBy(dx: 2, dy: 2)
        for (index, load) in loads.suffix(graphColumns).reversed().enumerated() {
            let x = plot.maxX - CGFloat(index + 1) * 3 + 1
            let systemHeight = plot.height * CGFloat(min(max(load.system, 0), 1))
            let userHeight = plot.height * CGFloat(min(max(load.user, 0), 1 - load.system))
            systemColor.setFill()
            NSRect(x: x, y: plot.minY, width: 2, height: systemHeight).fill()
            userColor.setFill()
            NSRect(x: x, y: plot.minY + systemHeight, width: 2, height: userHeight).fill()
        }
    }

    private static func drawPressureBar(fraction: Double, in rect: NSRect) {
        let clamped = CGFloat(min(max(fraction, 0), 1))
        NSColor.labelColor.withAlphaComponent(0.55).setStroke()
        let outline = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: 2, yRadius: 2)
        outline.stroke()
        let color: NSColor = clamped >= 0.8 ? .systemRed : clamped >= 0.5 ? .systemYellow : .labelColor
        color.setFill()
        let fill = rect.insetBy(dx: 1.5, dy: 1.5)
        NSBezierPath(
            roundedRect: NSRect(x: fill.minX, y: fill.minY, width: fill.width, height: max(fill.height * clamped, 1)),
            xRadius: 1, yRadius: 1
        ).fill()
    }
}
