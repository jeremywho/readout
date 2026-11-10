import AppKit
import SwiftUI

final class PanelWindow: NSPanel {
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
        contentView = container
    }

    private let container = NSView()

    override var canBecomeKey: Bool { true }

    /// Hiding the window does not end the panel's `.task` work; removing the SwiftUI tree (nil) does.
    func setContent(_ content: AnyView?) {
        for subview in container.subviews { subview.removeFromSuperview() }
        guard let content else { return }
        let surface = RoundedRectangle(cornerRadius: PanelStyle.cornerRadius, style: .continuous)
        let hosting = NSHostingView(rootView: content.fixedSize().background(surface.fill(PanelStyle.surface)))
        hosting.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: container.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        setContentSize(hosting.fittingSize)
    }
}
