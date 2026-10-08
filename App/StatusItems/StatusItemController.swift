import AppKit
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    let kind: MeterKind
    private let item: NSStatusItem
    private let meter = MeterView()
    private let popover = NSPopover()

    init(kind: MeterKind, panel: AnyView) {
        self.kind = kind
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        item.autosaveName = kind.autosaveName
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: panel)
        guard let button = item.button else { return }
        button.addSubview(meter)
        button.target = self
        button.action = #selector(togglePanel(_:))
        button.setAccessibilityLabel(kind.title)
    }

    func update(_ content: MeterContent) {
        meter.content = content
        let width = MeterDrawing.width(for: content)
        if item.length != width { item.length = width }
        meter.frame = NSRect(x: 0, y: 0, width: width, height: item.button?.bounds.height ?? MeterDrawing.height)
    }

    func setVisible(_ visible: Bool) {
        if item.isVisible != visible { item.isVisible = visible }
    }

    func remove() {
        popover.performClose(nil)
        NSStatusBar.system.removeStatusItem(item)
    }

    @objc private func togglePanel(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            NSApp.activate()
        }
    }
}
