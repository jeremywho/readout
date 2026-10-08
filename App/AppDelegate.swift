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
    private var controllers: [MeterKind: StatusItemController] = [:]
    private var samplingTask: Task<Void, Never>?
    private var defaultsObserver: NSObjectProtocol?
    private lazy var settingsWindow = SettingsWindowController(updater: updater)

    func applicationDidFinishLaunching(_ notification: Notification) {
        Preferences.registerDefaults()
        Preferences.launchAtLoginDefault.perform { try SMAppService.mainApp.register() }
        preferenceFingerprint = preferencesFingerprint()
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
            + Preferences.temperatureUnit.rawValue + "|" + Preferences.networkInterface
    }

    private func applyPreferencesIfChanged() {
        let fingerprint = preferencesFingerprint()
        guard fingerprint != preferenceFingerprint else { return }
        preferenceFingerprint = fingerprint
        applyEnginePreferences()
        refreshStatusItems()
    }

    private func applyEnginePreferences() {
        let selection = InterfaceSelection(preference: Preferences.networkInterface)
        Task { await engine.setInterfaceSelection(selection) }
    }

    private func reconcileStatusItems() {
        for kind in MeterKind.allCases.reversed() where controllers[kind] == nil {
            controllers[kind] = makeController(for: kind)
        }
    }

    private func refreshStatusItems() {
        let unit = Preferences.temperatureUnit
        for (kind, controller) in controllers {
            let visible = Preferences.isEnabled(kind) && (kind != .temperature || store.temperatureAvailable)
            controller.setVisible(visible)
            if visible { controller.update(MeterContentBuilder.content(for: kind, store: store, unit: unit)) }
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
