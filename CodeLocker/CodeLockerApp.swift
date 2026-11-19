import ServiceManagement
import SwiftUI

/*
 * App entry point. Opens the single Code Locker window and adds
 * File > New Account (⌘N) to the menu bar. Locks open on their own whenever the
 * app runs, so it doesn't need to run in the background or start at login.
 * Older versions did start at login; release builds undo that at launch.
 * Release builds also update themselves (see Helpers/Updater.swift).
 */

@main
struct CodeLockerApp: App {
    @State private var store = AccountStore()
    @State private var isAddingAccount = false
    private let updater = Updater()

    init() {
        #if !DEBUG
        try? SMAppService.mainApp.unregister()
        #endif
    }

    var body: some Scene {
        Window("Code Locker", id: "main") {
            AccountListView(store: store, isAddingAccount: $isAddingAccount)
        }
        .defaultSize(width: 340, height: 480)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") { updater.checkForUpdates() }
                    .disabled(!Updater.isEnabled)
            }
            CommandGroup(replacing: .newItem) {
                Button("New Account…") { isAddingAccount = true }
                    .keyboardShortcut("n")
            }
        }
    }
}
