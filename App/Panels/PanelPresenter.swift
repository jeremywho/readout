import AppKit
import ReadoutCore
import SwiftUI

@MainActor
final class PanelPresenter {
    /// Windows hosting Readout's own menu bar items. A click in one belongs to that item's action, not to dismissal.
    var statusItemWindows: () -> [NSWindow] = { [] }

    private static let escapeKeyCode: UInt16 = 53
    private let window = PanelWindow()
    private var openKind: MeterKind?
    private var anchor = NSRect.zero
    private var visibleFrame = NSRect.zero
    private var eventMonitors: [Any] = []
    private var observations: [(center: NotificationCenter, token: NSObjectProtocol)] = []

    func toggle(_ kind: MeterKind, content: AnyView, anchor: NSRect, visibleFrame: NSRect) {
        let wasShowing = openKind == kind
        close()
        guard !wasShowing else { return }
        self.anchor = anchor
        self.visibleFrame = visibleFrame
        window.setContent(content)
        place()
        openKind = kind
        startWatching()
        window.orderFrontRegardless()
        window.makeKey()
    }

    func close() {
        guard openKind != nil else { return }
        openKind = nil
        stopWatching()
        window.orderOut(nil)
        window.setContent(nil)
    }

    func close(_ kind: MeterKind) {
        if openKind == kind { close() }
    }

    private func place() {
        let frame = PanelPlacement.frame(anchor: anchor, size: window.frame.size, visibleFrame: visibleFrame)
        if frame != window.frame { window.setFrame(frame, display: true) }
        window.invalidateShadow()
    }

    private func startWatching() {
        let mouseDowns: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        let local = NSEvent.addLocalMonitorForEvents(matching: mouseDowns.union(.keyDown)) { [weak self] event in
            if event.type == .keyDown {
                guard event.keyCode == Self.escapeKeyCode else { return event }
                MainActor.assumeIsolated { self?.close() }
                return nil
            }
            let target = event.window.map(ObjectIdentifier.init)
            MainActor.assumeIsolated { self?.closeUnlessOwnWindow(target) }
            return event
        }
        let global = NSEvent.addGlobalMonitorForEvents(matching: mouseDowns) { [weak self] _ in
            MainActor.assumeIsolated { self?.close() }
        }
        eventMonitors = [local, global].compactMap { $0 }

        let workspace = NSWorkspace.shared.notificationCenter
        observe(workspace, NSWorkspace.activeSpaceDidChangeNotification) { $0.close() }
        observe(workspace, NSWorkspace.didActivateApplicationNotification) { $0.close() }
        observe(.default, NSApplication.didChangeScreenParametersNotification) { $0.close() }
        observe(.default, NSWindow.didResizeNotification, object: window) { $0.place() }
    }

    private func stopWatching() {
        for monitor in eventMonitors { NSEvent.removeMonitor(monitor) }
        eventMonitors = []
        for observation in observations { observation.center.removeObserver(observation.token) }
        observations = []
    }

    private func observe(
        _ center: NotificationCenter, _ name: Notification.Name, object: AnyObject? = nil,
        _ action: @escaping @MainActor (PanelPresenter) -> Void
    ) {
        let token = center.addObserver(forName: name, object: object, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { if let self { action(self) } }
        }
        observations.append((center, token))
    }

    private func closeUnlessOwnWindow(_ target: ObjectIdentifier?) {
        let own = ([window] + statusItemWindows()).map(ObjectIdentifier.init)
        if let target, own.contains(target) { return }
        close()
    }
}
