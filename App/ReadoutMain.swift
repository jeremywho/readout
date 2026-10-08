import AppKit
import ReadoutSystem

@main
enum ReadoutMain {
    @MainActor
    static func main() {
        let arguments = CommandLine.arguments
        if arguments.contains("--self-test") {
            let result = SelfTest.runBlocking()
            print(result.report)
            exit(result.passed ? 0 : 1)
        }
        if let index = arguments.firstIndex(of: "--export-screenshots") {
            guard arguments.indices.contains(index + 1) else {
                FileHandle.standardError.write(Data("usage: Readout --export-screenshots <directory>\n".utf8))
                exit(2)
            }
            exit(ScreenshotExporter.export(to: URL(fileURLWithPath: arguments[index + 1], isDirectory: true)) ? 0 : 1)
        }
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { application.run() }
    }
}
