import SwiftUI

struct PanelActions {
    let openSettings: @MainActor () -> Void
    let checkForUpdates: @MainActor () -> Void
    let quit: @MainActor () -> Void

    static let inert = PanelActions(openSettings: {}, checkForUpdates: {}, quit: {})
}

struct PanelHost: View {
    let kind: MeterKind
    let actions: PanelActions

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch kind {
            case .network: NetworkPanel()
            case .cpu: CPUPanel()
            case .gpu: GPUPanel()
            case .memory: MemoryPanel()
            case .disk: DiskPanel()
            case .temperature: TemperaturePanel()
            }
            Divider()
            PanelFooter(actions: actions)
        }
        .padding(PanelStyle.padding)
        .frame(width: PanelStyle.width)
    }
}

struct PanelFooter: View {
    let actions: PanelActions

    var body: some View {
        HStack {
            Button("Settings…") { actions.openSettings() }
            Button("Check for Updates…") { actions.checkForUpdates() }
            Spacer()
            Button("Quit Readout") { actions.quit() }
        }
        .buttonStyle(.plain)
        .foregroundStyle(PanelStyle.link)
        .font(PanelStyle.body)
    }
}
