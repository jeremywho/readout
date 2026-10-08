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
            Text(kind.title).font(.headline)
            Divider()
            PanelFooter(actions: actions)
        }
        .padding(14)
        .frame(width: 300)
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
        .buttonStyle(.borderless)
        .font(.callout)
    }
}
