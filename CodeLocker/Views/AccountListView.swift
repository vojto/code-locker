import SwiftUI

/*
 * The main window: the list of accounts with their current codes, or padlocks
 * while they are locked. Ticks once a second so codes, countdown rings and
 * "Opens in…" texts stay fresh. Owns the "+" toolbar button, the add-account
 * sheet, the lock sheet and the delete confirmation.
 */

struct AccountListView: View {
    let store: AccountStore
    @Binding var isAddingAccount: Bool

    @State private var accountToLock: Account?
    @State private var accountToDelete: Account?

    var body: some View {
        TimelineView(.periodic(from: startOfCurrentSecond, by: 1)) { timeline in
            List(store.accounts) { account in
                AccountRow(
                    name: account.name,
                    secret: account.secret,
                    opening: account.opening,
                    date: timeline.date,
                    onLock: { accountToLock = account },
                    onDelete: { accountToDelete = account }
                )
            }
        }
        .overlay {
            if !store.isLoaded {
                ContentUnavailableView(
                    "Loading Accounts",
                    systemImage: "hourglass",
                    description: Text("Just a moment.")
                )
            } else if store.accounts.isEmpty {
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
        .sheet(item: $accountToLock) { account in
            LockSheet(name: account.name, initialPeriod: account.lastLockPeriod ?? .standard) { period in
                store.lock(account, for: period)
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
