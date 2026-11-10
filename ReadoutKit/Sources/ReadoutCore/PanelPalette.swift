import Foundation

/// An sRGB colour with components in 0...1.
public struct RGB: Sendable, Equatable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(_ red: Double, _ green: Double, _ blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public init(white: Double) {
        self.init(white, white, white)
    }

    /// WCAG 2 relative luminance.
    public var luminance: Double {
        func linear(_ channel: Double) -> Double {
            channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    /// WCAG 2 contrast ratio, from 1 (identical) to 21 (black on white).
    public func contrast(with other: RGB) -> Double {
        let lighter = max(luminance, other.luminance)
        let darker = min(luminance, other.luminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// This colour drawn at `alpha` over `backdrop`.
    public func composited(over backdrop: RGB, alpha: Double) -> RGB {
        RGB(
            red * alpha + backdrop.red * (1 - alpha), green * alpha + backdrop.green * (1 - alpha),
            blue * alpha + backdrop.blue * (1 - alpha))
    }
}

public struct AdaptiveRGB: Sendable, Equatable {
    public let light: RGB
    public let dark: RGB

    public init(light: RGB, dark: RGB) {
        self.light = light
        self.dark = dark
    }
}

/// Colours of the dropdown panels. The surface is opaque: a translucent one takes on whatever is behind the panel,
/// and then no text colour keeps its contrast.
public enum PanelPalette {
    public static let minimumTextContrast = 4.5

    public static let surface = AdaptiveRGB(light: RGB(0.925, 0.933, 0.941), dark: RGB(0.118, 0.125, 0.133))
    public static let secondary = AdaptiveRGB(light: RGB(white: 0.39), dark: RGB(white: 0.63))
    public static let download = AdaptiveRGB(light: RGB(0.10, 0.30, 0.82), dark: RGB(0.45, 0.62, 1.0))
    public static let upload = AdaptiveRGB(light: RGB(0.70, 0.06, 0.32), dark: RGB(1.0, 0.42, 0.63))
    public static let link = AdaptiveRGB(light: RGB(0.04, 0.37, 0.82), dark: RGB(0.36, 0.66, 1.0))

    public static let textColors: [(name: String, color: AdaptiveRGB)] = [
        ("secondary", secondary), ("download", download), ("upload", upload), ("link", link),
    ]

    public static let minimumGraphicContrast = 3.0

    /// Drawn behind the menu bar graph. The menu bar is translucent, so without it the bars are only as visible as
    /// the wallpaper allows. At this alpha both series keep `minimumGraphicContrast` over any wallpaper.
    public static let graphBacking = AdaptiveRGB(light: RGB(white: 1), dark: RGB(white: 0))
    public static let graphBackingAlpha = 0.7
}
