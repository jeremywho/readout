import ReadoutCore
import SwiftUI

struct AdaptiveColor: ShapeStyle {
    let light: Color
    let dark: Color

    init(_ color: AdaptiveRGB) {
        light = Color(red: color.light.red, green: color.light.green, blue: color.light.blue)
        dark = Color(red: color.dark.red, green: color.dark.green, blue: color.dark.blue)
    }

    func resolve(in environment: EnvironmentValues) -> Color {
        environment.colorScheme == .dark ? dark : light
    }
}

enum PanelStyle {
    static let width: CGFloat = 340
    static let padding: CGFloat = 14
    static let cornerRadius: CGFloat = 12

    static let title = Font.title3.weight(.semibold)
    static let metric = Font.system(.title, design: .rounded).monospacedDigit()
    static let body = Font.body
    static let label = Font.callout

    static let surface = AdaptiveColor(PanelPalette.surface)
    static let secondary = AdaptiveColor(PanelPalette.secondary)
    static let download = AdaptiveColor(PanelPalette.download)
    static let upload = AdaptiveColor(PanelPalette.upload)
    static let link = AdaptiveColor(PanelPalette.link)
}
