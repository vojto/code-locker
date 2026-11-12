import SwiftUI

/*
 * The main window: the list of accounts with their current codes, or padlocks
 * while they are locked. Ticks once a second so codes and countdown rings stay
 * fresh. The line under the window title says whether codes are locked and when
 * that changes. Owns the "+" toolbar button, the add-account sheet and the
 * delete confirmation.
 */

struct AccountListView: View {
    let store: AccountStore
    @Binding var isAddingAccount: Bool

    @State private var accountToDelete: Account?

    var body: some View {
        TimelineView(.periodic(from: startOfCurrentSecond, by: 1)) { timeline in
            List(store.accounts) { account in
                AccountRow(name: account.name, secret: store.secrets[account.id], date: timeline.date) {
                    accountToDelete = account
                }
            }
            .navigationSubtitle(statusText(at: timeline.date))
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

    // MARK: - Status

    private func statusText(at date: Date) -> String {
        switch store.status {
        case .checking:
            "Checking…"
        case .offline:
            "Offline. Codes stay locked."
        case .open:
            "Unlocked. Locks \(relativeText(store.schedule.nextClosing(after: date), from: date))."
        case .locked:
            "Locked. Opens \(relativeText(store.schedule.nextOpening(after: date), from: date))."
        }
    }

    private func relativeText(_ target: Date, from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: target, relativeTo: date)
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
