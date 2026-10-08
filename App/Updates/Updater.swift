import os

@MainActor
final class Updater {
    private let logger = Logger(subsystem: "com.daughhetee.Readout", category: "updates")

    var settings: UpdaterSettings? { nil }

    func checkForUpdates() {
        logger.info("update checks are not wired up yet")
    }
}
