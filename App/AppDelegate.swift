import AppKit
import ReadoutCore
import ReadoutSystem
import ServiceManagement
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let engine = SamplingEngine()
    private let store = MetricsStore()
    private let processes = ProcessMonitor()
    private let updater = Updater()
    private let presenter = PanelPresenter()
    private var controllers: [MeterKind: StatusItemController] = [:]
    private var itemLayout = ItemLayout()
    private var itemOrder = MeterKind.allCases
    private var shownKinds: Set<MeterKind>?
    private var samplingTask: Task<Void, Never>?
    private var defaultsObserver: NSObjectProtocol?
    private lazy var settingsWindow = SettingsWindowController(updater: updater)

    func applicationDidFinishLaunching(_ notification: Notification) {
        Preferences.registerDefaults()
        Preferences.launchAtLoginDefault.perform { try SMAppService.mainApp.register() }
        preferenceFingerprint = preferencesFingerprint()
        applyItemOrder()
        reconcileStatusItems()
        applyEnginePreferences()
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.applyPreferencesIfChanged() }
        }
        samplingTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let snapshot = await self.engine.tick()
                self.store.apply(snapshot)
                self.applyPreferencesIfChanged()
                self.refreshStatusItems()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        samplingTask?.cancel()
    }

    private var preferenceFingerprint = ""

    private func preferencesFingerprint() -> String {
        MeterKind.allCases.map { Preferences.isEnabled($0) ? "1" : "0" }.joined()
            + Preferences.temperatureUnit.rawValue + "|" + Preferences.networkInterface + "|"
            + ItemOrder.stored(Preferences.itemOrder.map(\.rawValue))
    }

    private func applyPreferencesIfChanged() {
        let fingerprint = preferencesFingerprint()
        guard fingerprint != preferenceFingerprint else { return }
        preferenceFingerprint = fingerprint
        applyEnginePreferences()
        if applyItemOrder() { rebuildStatusItems() }
        refreshStatusItems()
    }

    /// Returns whether the items must be re-created: Settings now asks for another order than they were created in.
    @discardableResult
    private func applyItemOrder() -> Bool {
        let order = Preferences.itemOrder
        let stored = Preferences.itemLayout
        let layout = stored.placing(order.map(\.rawValue))
        let changed = order != itemOrder || layout != itemLayout
        itemOrder = order
        itemLayout = layout
        if layout != stored { Preferences.itemLayout = layout }
        return changed
    }

    private func rebuildStatusItems() {
        for controller in controllers.values { controller.remove() }
        controllers = [:]
        reconcileStatusItems()
    }

    private func applyEnginePreferences() {
        let selection = InterfaceSelection(preference: Preferences.networkInterface)
        Task { await engine.setInterfaceSelection(selection) }
    }

    private func reconcileStatusItems() {
        for kind in itemOrder.reversed() where controllers[kind] == nil {
            controllers[kind] = makeController(for: kind)
        }
    }

    private func refreshStatusItems() {
        let unit = Preferences.temperatureUnit
        let shown = Set(MeterKind.allCases.filter { Preferences.isEnabled($0) && store.isAvailable($0) })
        let rebuild = ItemLayout.needsRebuild(
            shownBefore: shownKinds.map { Set($0.map(\.rawValue)) }, shownNow: Set(shown.map(\.rawValue)))
        shownKinds = shown
        if rebuild { rebuildStatusItems() }
        for (kind, controller) in controllers {
            let visible = shown.contains(kind)
            controller.setVisible(visible)
            if visible { controller.update(MeterContentBuilder.content(for: kind, store: store, unit: unit)) }
        }
    }

    /// macOS honors `activate()` only while the panel is still on screen; after it closes, the next window opens
    /// behind the frontmost app.
    private func leavePanel(for action: (AppDelegate) -> Void) {
        NSApp.activate()
        presenter.close()
        action(self)
    }

    private func makeController(for kind: MeterKind) -> StatusItemController {
        let actions = PanelActions(
            openSettings: { [weak self] in self?.leavePanel { $0.settingsWindow.show() } },
            checkForUpdates: { [weak self] in self?.leavePanel { $0.updater.checkForUpdates() } },
            quit: { NSApp.terminate(nil) }
        )
        let panel = PanelHost(kind: kind, actions: actions).environment(store).environment(processes)
        return StatusItemController(
            kind: kind, autosaveName: itemLayout.autosaveName(prefix: MeterKind.autosavePrefix, item: kind.rawValue),
            panel: AnyView(panel), presenter: presenter)
    }
}
