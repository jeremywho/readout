import AppKit
import SwiftUI

final class PanelWindow: NSPanel {
    private static let cornerRadius: CGFloat = 12
    private let background = NSVisualEffectView()

    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        level = .popUpMenu
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        animationBehavior = .none
        collectionBehavior = [.transient, .ignoresCycle, .fullScreenAuxiliary]
        background.material = .popover
        background.blendingMode = .behindWindow
        background.state = .active
        background.maskImage = Self.roundedMask
        contentView = background
    }

    override var canBecomeKey: Bool { true }

    /// Hiding the window does not end the panel's `.task` work; removing the SwiftUI tree (nil) does.
    func setContent(_ content: AnyView?) {
        for subview in background.subviews { subview.removeFromSuperview() }
        guard let content else { return }
        let hosting = NSHostingView(rootView: content.fixedSize())
        hosting.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: background.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: background.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: background.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: background.bottomAnchor),
        ])
        setContentSize(hosting.fittingSize)
    }

    private static let roundedMask: NSImage = {
        let edge = cornerRadius * 2 + 1
        let image = NSImage(size: NSSize(width: edge, height: edge), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(
            top: cornerRadius, left: cornerRadius, bottom: cornerRadius, right: cornerRadius)
        image.resizingMode = .stretch
        return image
    }()
}
