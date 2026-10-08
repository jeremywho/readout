import ReadoutCore
import ServiceManagement
import SwiftUI

struct ItemToggle: View {
    let kind: MeterKind
    @AppStorage private var enabled: Bool

    init(kind: MeterKind) {
        self.kind = kind
        _enabled = AppStorage(wrappedValue: true, Preferences.Key.enabled(kind))
    }

    var body: some View {
        Toggle(kind.title, isOn: $enabled)
    }
}

struct SettingsView: View {
    let interfaces: [String]
    let updates: UpdaterSettings?
    @AppStorage(Preferences.Key.temperatureUnit) private var unit = TemperatureUnit.fahrenheit.rawValue
    @AppStorage(Preferences.Key.networkInterface) private var interface = ""
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        Form {
            Section("Menu bar items") {
                ForEach(MeterKind.allCases) { ItemToggle(kind: $0) }
            }
            Section("Display") {
                Picker("Temperature", selection: $unit) {
                    Text("Fahrenheit (°F)").tag(TemperatureUnit.fahrenheit.rawValue)
                    Text("Celsius (°C)").tag(TemperatureUnit.celsius.rawValue)
                }
            }
            Section("Network") {
                Picker("Interface", selection: $interface) {
                    Text("Automatic (primary)").tag("")
                    ForEach(interfaces, id: \.self) { Text($0).tag($0) }
                }
            }
            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
                if let loginError { Text(loginError).font(.caption).foregroundStyle(.red) }
            }
            if let updates { UpdatesSection(settings: updates) }
        }
        .formStyle(.grouped)
        .frame(width: 420)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            loginError = nil
        } catch {
            loginError = error.localizedDescription
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

@MainActor
@Observable
final class UpdaterSettings {}

struct UpdatesSection: View {
    let settings: UpdaterSettings
    var body: some View { EmptyView() }
}
