import Foundation

@MainActor
enum ScreenshotExporter {
    static func export(to directory: URL) -> Bool {
        FileHandle.standardError.write(Data("screenshot export is not implemented yet\n".utf8))
        return false
    }
}
