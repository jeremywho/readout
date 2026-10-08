import AppKit

final class MeterView: NSView {
    var content: MeterContent = .captioned(caption: "", value: "—") {
        didSet { if content != oldValue { needsDisplay = true } }
    }

    override func draw(_ dirtyRect: NSRect) {
        MeterDrawing.draw(content, in: bounds)
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
