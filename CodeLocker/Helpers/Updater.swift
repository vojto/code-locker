import Sparkle

/*
 * Keeps the app up to date with Sparkle. Created by CodeLockerApp, which also
 * shows its "Check for Updates…" menu item. Sparkle reads the signed feed named
 * in Info.plist (SUFeedURL) and checks on its own schedule. Debug builds never
 * start the updater.
 */
final class Updater {
    #if DEBUG
    static let isEnabled = false
    #else
    static let isEnabled = true
    #endif

    private let controller = isEnabled
        ? SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        : nil

    func checkForUpdates() {
        controller?.checkForUpdates(nil)
    }
}
