import SwiftUI

/*
 * App entry point. Opens the single Code Locker window and adds
 * File > New Account (⌘N) to the menu bar. The app keeps running after the
 * window is closed, and starts at login, so it can lock codes away on schedule.
 */

@main
struct CodeLockerApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var store = AccountStore()
    @State private var isAddingAccount = false

    init() {
        #if !DEBUG
        LoginItem.registerOnce()
        #endif
    }

    var body: some Scene {
        Window("Code Locker", id: "main") {
            AccountListView(store: store, isAddingAccount: $isAddingAccount)
        }
        .defaultSize(width: 340, height: 480)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Account…") { isAddingAccount = true }
                    .keyboardShortcut("n")
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
