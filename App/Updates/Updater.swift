import Observation
import Sparkle

@MainActor
final class Updater {
    private let controller = SPUStandardUpdaterController(
        startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    private(set) lazy var settings: UpdaterSettings? = UpdaterSettings(updater: controller.updater)

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}

@MainActor
@Observable
final class UpdaterSettings {
    private let updater: SPUUpdater
    private var checks: Bool
    private var downloads: Bool

    var automaticallyChecks: Bool {
        get { checks }
        set {
            checks = newValue
            updater.automaticallyChecksForUpdates = newValue
        }
    }

    var automaticallyDownloads: Bool {
        get { downloads }
        set {
            downloads = newValue
            updater.automaticallyDownloadsUpdates = newValue
        }
    }

    init(updater: SPUUpdater) {
        self.updater = updater
        checks = updater.automaticallyChecksForUpdates
        downloads = updater.automaticallyDownloadsUpdates
    }
}
