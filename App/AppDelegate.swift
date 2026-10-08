import AppKit
import ReadoutCore
import ReadoutSystem
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let engine = SamplingEngine()
    private let store = MetricsStore()
    private let processes = ProcessMonitor()
    private let updater = Updater()
    private var controllers: [MeterKind: StatusItemController] = [:]
    private var samplingTask: Task<Void, Never>?
    private var defaultsObserver: NSObjectProtocol?
    private lazy var settingsWindow = SettingsWindowController(updater: updater)

    func applicationDidFinishLaunching(_ notification: Notification) {
        Preferences.registerDefaults()
        reconcileStatusItems()
        applyEnginePreferences()
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.preferencesChanged() }
        }
        samplingTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let snapshot = await self.engine.tick()
                self.store.apply(snapshot)
                self.refreshStatusItems()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        samplingTask?.cancel()
    }

    private func preferencesChanged() {
        reconcileStatusItems()
        applyEnginePreferences()
        refreshStatusItems()
    }

    private func applyEnginePreferences() {
        let selection = InterfaceSelection(preference: Preferences.networkInterface)
        Task { await engine.setInterfaceSelection(selection) }
    }

    private func reconcileStatusItems() {
        for kind in MeterKind.allCases.reversed() {
            let enabled = Preferences.isEnabled(kind)
            if enabled, controllers[kind] == nil {
                controllers[kind] = makeController(for: kind)
            } else if !enabled, let controller = controllers.removeValue(forKey: kind) {
                controller.remove()
            }
        }
    }

    private func refreshStatusItems() {
        let unit = Preferences.temperatureUnit
        for (kind, controller) in controllers {
            controller.update(MeterContentBuilder.content(for: kind, store: store, unit: unit))
            if kind == .temperature { controller.setVisible(store.temperatureAvailable) }
        }
    }

    private func makeController(for kind: MeterKind) -> StatusItemController {
        let actions = PanelActions(
            openSettings: { [weak self] in self?.settingsWindow.show() },
            checkForUpdates: { [weak self] in self?.updater.checkForUpdates() },
            quit: { NSApp.terminate(nil) }
        )
        let panel = PanelHost(kind: kind, actions: actions).environment(store).environment(processes)
        return StatusItemController(kind: kind, panel: AnyView(panel))
    }
}
