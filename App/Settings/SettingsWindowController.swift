import AppKit
import ReadoutSystem
import SwiftUI

@MainActor
final class SettingsWindowController {
    private let updater: Updater
    private var window: NSWindow?

    init(updater: Updater) {
        self.updater = updater
    }

    func show() {
        if window == nil {
            let view = SettingsView(interfaces: Self.interfaceNames(), updates: updater.settings)
            let controller = NSHostingController(rootView: view)
            let window = NSWindow(contentViewController: controller)
            window.title = "Readout Settings"
            window.styleMask = [.titled, .closable]
            window.setContentSize(controller.view.fittingSize)
            window.isReleasedWhenClosed = false
            self.window = window
        }
        window?.center()
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }

    private static func interfaceNames() -> [String] {
        let excluded = ["lo", "gif", "stf", "anpi", "ap", "awdl", "llw"]
        let names = InterfaceCountersReader.readAll()?.map(\.name) ?? []
        return Array(Set(names.filter { name in !excluded.contains { name.hasPrefix($0) } })).sorted()
    }
}
