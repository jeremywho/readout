import AppKit
import SwiftUI

@MainActor
enum ScreenshotExporter {
    static func export(to directory: URL) -> Bool {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let store = MetricsStore.fixture()
            let processes = ProcessMonitor.fixture()
            let variants: [(String, NSAppearance.Name, ColorScheme, Color)] = [
                ("dark", .darkAqua, .dark, Color(white: 0.16)),
                ("light", .aqua, .light, Color(white: 0.96)),
            ]
            for (name, appearanceName, scheme, background) in variants {
                guard let appearance = NSAppearance(named: appearanceName),
                    let bar = menuBarPNG(store: store, appearance: appearance)
                else { return false }
                try bar.write(to: directory.appending(path: "menubar-\(name).png"))
                for kind in MeterKind.allCases {
                    let view = PanelHost(kind: kind, actions: .inert)
                        .environment(store)
                        .environment(processes)
                        .environment(\.colorScheme, scheme)
                        .background(background)
                    let renderer = ImageRenderer(content: view)
                    renderer.scale = 2
                    guard let image = renderer.cgImage,
                        let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
                    else { return false }
                    try png.write(to: directory.appending(path: "panel-\(kind.rawValue)-\(name).png"))
                }
            }
            return true
        } catch {
            FileHandle.standardError.write(Data("screenshot export failed: \(error)\n".utf8))
            return false
        }
    }

    private static func menuBarPNG(store: MetricsStore, appearance: NSAppearance) -> Data? {
        let contents = MeterKind.allCases.map { MeterContentBuilder.content(for: $0, store: store, unit: .fahrenheit) }
        let widths = contents.map(MeterDrawing.width(for:))
        let spacing: CGFloat = 8
        let size = NSSize(
            width: widths.reduce(0, +) + spacing * CGFloat(contents.count + 1), height: MeterDrawing.height)
        let scale: CGFloat = 2
        guard
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale),
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
        else { return nil }
        rep.size = size
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        appearance.performAsCurrentDrawingAppearance {
            let background =
                appearance.name == .darkAqua ? NSColor(white: 0.13, alpha: 1) : NSColor(white: 0.92, alpha: 1)
            background.setFill()
            NSRect(origin: .zero, size: size).fill()
            var x = spacing
            for (content, width) in zip(contents, widths) {
                MeterDrawing.draw(content, in: NSRect(x: x, y: 0, width: width, height: size.height))
                x += width + spacing
            }
        }
        NSGraphicsContext.restoreGraphicsState()
        return rep.representation(using: .png, properties: [:])
    }
}
