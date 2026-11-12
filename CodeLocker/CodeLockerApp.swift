import SwiftUI

/*
 * App entry point. Opens the single Code Locker window and adds
 * File > New Account (⌘N) to the menu bar.
 */

@main
struct CodeLockerApp: App {
    @State private var store = AccountStore()
    @State private var isAddingAccount = false

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
