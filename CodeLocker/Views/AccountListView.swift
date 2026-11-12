import SwiftUI

/*
 * The main window: the list of accounts with their current codes.
 * Ticks once a second so codes and countdown rings stay fresh. Owns the
 * "+" toolbar button, the add-account sheet and the delete confirmation.
 */

struct AccountListView: View {
    let store: AccountStore
    @Binding var isAddingAccount: Bool

    @State private var accountToDelete: Account?

    var body: some View {
        TimelineView(.periodic(from: startOfCurrentSecond, by: 1)) { timeline in
            List(store.accounts) { account in
                AccountRow(account: account, date: timeline.date) {
                    accountToDelete = account
                }
            }
        }
        .overlay {
            if store.accounts.isEmpty {
                ContentUnavailableView(
                    "No Accounts",
                    systemImage: "lock.shield",
                    description: Text("Click + to add your first account.")
                )
            }
        }
        #if DEBUG
        .safeAreaInset(edge: .bottom, spacing: 0) { DebugBanner() }
        #endif
        .frame(minWidth: 280, minHeight: 240)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add Account", systemImage: "plus") { isAddingAccount = true }
                    .help("Add Account")
            }
        }
        .sheet(isPresented: $isAddingAccount) {
            AddAccountSheet { name, secret in
                store.add(name: name, secret: secret)
            }
        }
        .confirmationDialog(
            "Delete “\(accountToDelete?.name ?? "")”?",
            isPresented: isConfirmingDelete,
            presenting: accountToDelete
        ) { account in
            Button("Delete", role: .destructive) { store.delete(account) }
        } message: { _ in
            Text("You will no longer be able to get codes for this account. Make sure you have another way to sign in first.")
        }
    }

    // MARK: - Helpers

    private var startOfCurrentSecond: Date {
        Date(timeIntervalSince1970: Date.now.timeIntervalSince1970.rounded(.down))
    }

    private var isConfirmingDelete: Binding<Bool> {
        Binding(
            get: { accountToDelete != nil },
            set: { if !$0 { accountToDelete = nil } }
        )
    }
}
