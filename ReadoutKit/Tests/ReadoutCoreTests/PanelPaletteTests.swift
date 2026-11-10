import Testing

@testable import ReadoutCore

@Suite struct PanelPaletteTests {
    private func isClose(_ value: Double, _ expected: Double, tolerance: Double = 0.01) -> Bool {
        abs(value - expected) <= tolerance
    }

    @Test func contrastMatchesTheWCAGReferenceValues() {
        let white = RGB(white: 1)
        let black = RGB(white: 0)
        #expect(isClose(white.contrast(with: black), 21))
        #expect(isClose(black.contrast(with: white), 21))
        #expect(isClose(white.contrast(with: white), 1))
        #expect(isClose(RGB(white: 119.0 / 255).contrast(with: white), 4.48))
        #expect(isClose(RGB(1, 0, 0).contrast(with: white), 4.0))
    }

    @Test func everyTextColorMeetsTheMinimumOnTheSurfaceInBothAppearances() {
        for (name, color) in PanelPalette.textColors {
            let light = color.light.contrast(with: PanelPalette.surface.light)
            let dark = color.dark.contrast(with: PanelPalette.surface.dark)
            #expect(light >= PanelPalette.minimumTextContrast, "\(name) on the light surface is \(light):1")
            #expect(dark >= PanelPalette.minimumTextContrast, "\(name) on the dark surface is \(dark):1")
        }
    }

    @Test func theSeriesBlueThisPaletteReplacedFailsTheSameCheck() {
        let replaced = RGB(0.27, 0.47, 1.0)
        #expect(replaced.contrast(with: PanelPalette.surface.dark) < PanelPalette.minimumTextContrast)
        #expect(replaced.contrast(with: PanelPalette.surface.light) < PanelPalette.minimumTextContrast)
    }

    private func worstGraphContrast(alpha: Double) -> Double {
        var worst = Double.infinity
        for backdrop in [RGB(white: 0), RGB(white: 1)] {
            for series in [PanelPalette.download, PanelPalette.upload] {
                let light = PanelPalette.graphBacking.light.composited(over: backdrop, alpha: alpha)
                let dark = PanelPalette.graphBacking.dark.composited(over: backdrop, alpha: alpha)
                worst = min(worst, series.light.contrast(with: light), series.dark.contrast(with: dark))
            }
        }
        return worst
    }

    @Test func theGraphSeriesStayVisibleOnTheirBackingOverAnyWallpaper() {
        #expect(worstGraphContrast(alpha: PanelPalette.graphBackingAlpha) >= PanelPalette.minimumGraphicContrast)
    }

    @Test func aThinnerBackingOrNoneFailsTheSameCheck() {
        #expect(worstGraphContrast(alpha: 0.6) < PanelPalette.minimumGraphicContrast)
        #expect(worstGraphContrast(alpha: 0) < PanelPalette.minimumGraphicContrast)
    }

    @Test func compositingBlendsTowardsTheBackdrop() {
        let black = RGB(white: 0)
        let white = RGB(white: 1)
        #expect(black.composited(over: white, alpha: 1) == black)
        #expect(black.composited(over: white, alpha: 0) == white)
        #expect(isClose(black.composited(over: white, alpha: 0.7).red, 0.3))
    }

    @Test func eachSeriesKeepsItsHueAcrossAppearances() {
        for color in [PanelPalette.download, PanelPalette.upload] {
            #expect(abs(hue(color.light) - hue(color.dark)) < 6)
        }
        #expect(abs(hue(PanelPalette.download.dark) - hue(RGB(0.27, 0.47, 1.0))) < 6)
        #expect(abs(hue(PanelPalette.upload.dark) - hue(RGB(1.0, 0.30, 0.55))) < 6)
    }

    private func hue(_ color: RGB) -> Double {
        let high = max(color.red, color.green, color.blue)
        let low = min(color.red, color.green, color.blue)
        let span = high - low
        guard span > 0 else { return 0 }
        let sector: Double
        if high == color.red {
            sector = ((color.green - color.blue) / span).truncatingRemainder(dividingBy: 6)
        } else if high == color.green {
            sector = (color.blue - color.red) / span + 2
        } else {
            sector = (color.red - color.green) / span + 4
        }
        return (sector * 60 + 360).truncatingRemainder(dividingBy: 360)
    }
}
