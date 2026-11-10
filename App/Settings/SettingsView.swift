import ReadoutCore
import ServiceManagement
import SwiftUI

struct ItemRow: View {
    let kind: MeterKind
    let canMoveUp: Bool
    let canMoveDown: Bool
    let move: (Int) -> Void
    @AppStorage private var enabled: Bool

    init(kind: MeterKind, canMoveUp: Bool, canMoveDown: Bool, move: @escaping (Int) -> Void) {
        self.kind = kind
        self.canMoveUp = canMoveUp
        self.canMoveDown = canMoveDown
        self.move = move
        _enabled = AppStorage(wrappedValue: true, Preferences.Key.enabled(kind))
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(kind.title)
            Spacer()
            moveButton("chevron.up", "Move \(kind.title) up", shown: canMoveUp) { move(-1) }
            moveButton("chevron.down", "Move \(kind.title) down", shown: canMoveDown) { move(1) }
            Toggle(kind.title, isOn: $enabled).labelsHidden()
        }
    }

    private func moveButton(_ symbol: String, _ label: String, shown: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: symbol) }
            .buttonStyle(.borderless)
            .help(label)
            .accessibilityLabel(label)
            .opacity(shown ? 1 : 0)
            .disabled(!shown)
            .accessibilityHidden(!shown)
    }
}

struct SettingsView: View {
    let interfaces: [String]
    let updates: UpdaterSettings?
    @AppStorage(Preferences.Key.temperatureUnit) private var unit = TemperatureUnit.fahrenheit.rawValue
    @AppStorage(Preferences.Key.networkInterface) private var interface = ""
    @AppStorage(Preferences.Key.itemOrder) private var storedOrder = ""
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        Form {
            Section {
                let order = Preferences.order(from: storedOrder)
                ForEach(order) { kind in
                    ItemRow(kind: kind, canMoveUp: kind != order.first, canMoveDown: kind != order.last) { offset in
                        storedOrder = ItemOrder.stored(
                            ItemOrder.moving(kind.rawValue, by: offset, in: order.map(\.rawValue)))
                    }
                }
            } header: {
                Text("Menu bar items")
            } footer: {
                Text("Top to bottom here is left to right in the menu bar.")
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
        .fixedSize(horizontal: false, vertical: true)
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

struct UpdatesSection: View {
    @Bindable var settings: UpdaterSettings

    var body: some View {
        Section("Updates") {
            Toggle("Check for updates automatically", isOn: $settings.automaticallyChecks)
            Toggle("Download and install updates automatically", isOn: $settings.automaticallyDownloads)
                .disabled(!settings.automaticallyChecks)
        }
    }
}
