import AppKit
import ReadoutCore
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    let kind: MeterKind
    private let item: NSStatusItem
    private let meter = MeterView()
    private let panel: AnyView
    private let presenter: PanelPresenter

    init(kind: MeterKind, autosaveName: String, panel: AnyView, presenter: PanelPresenter) {
        self.kind = kind
        self.panel = panel
        self.presenter = presenter
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        item.autosaveName = autosaveName
        guard let button = item.button else { return }
        button.addSubview(meter)
        button.target = self
        button.action = #selector(togglePanel(_:))
        button.setAccessibilityLabel(kind.title)
    }

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
        let pointer = NSEvent.mouseLocation
        let clicked = NSScreen.screens.first { NSMouseInRect(pointer, $0.frame, false) }
        guard let screen = clicked ?? sender.window?.screen ?? NSScreen.main else { return }
        let clickedCopy = NSApp.currentEvent?.window.flatMap { $0.level == .statusBar ? $0 : nil }
        let anchor = PanelPlacement.anchor(
            itemFrames: [clickedCopy, sender.window].compactMap { $0?.frame }, pointer: pointer,
            screenFrame: screen.frame)
        presenter.toggle(kind, content: panel, anchor: anchor, visibleFrame: screen.visibleFrame)
    }
}
