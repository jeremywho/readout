import AppKit
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    let kind: MeterKind
    private let item: NSStatusItem
    private let meter = MeterView()
    private let panel: AnyView
    private let presenter: PanelPresenter

    init(kind: MeterKind, panel: AnyView, presenter: PanelPresenter) {
        self.kind = kind
        self.panel = panel
        self.presenter = presenter
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        item.autosaveName = kind.autosaveName
        guard let button = item.button else { return }
        button.addSubview(meter)
        button.target = self
        button.action = #selector(togglePanel(_:))
        button.setAccessibilityLabel(kind.title)
    }

    var buttonWindow: NSWindow? { item.button?.window }

    func update(_ content: MeterContent) {
        guard content != meter.content else { return }
        meter.content = content
        let width = MeterDrawing.width(for: content)
        if item.length != width { item.length = width }
        meter.frame = NSRect(x: 0, y: 0, width: width, height: item.button?.bounds.height ?? MeterDrawing.height)
    }

    func setVisible(_ visible: Bool) {
        guard item.isVisible != visible else { return }
        if !visible { presenter.close(kind) }
        item.isVisible = visible
    }

    func remove() {
        presenter.close(kind)
        NSStatusBar.system.removeStatusItem(item)
    }

    @objc private func togglePanel(_ sender: NSStatusBarButton) {
        guard let window = sender.window, let screen = window.screen ?? NSScreen.main else { return }
        let anchor = window.convertToScreen(sender.convert(sender.bounds, to: nil))
        presenter.toggle(kind, content: panel, anchor: anchor, visibleFrame: screen.visibleFrame)
    }
}
