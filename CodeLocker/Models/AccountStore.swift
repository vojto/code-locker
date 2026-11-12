import Foundation
import Observation

/*
 * The list of accounts shown in the window. Views read `accounts` and call add/delete.
 * The whole list is kept as one encrypted item in the Keychain, and saved again
 * after every change.
 */

@Observable
final class AccountStore {
    private static let keychainKey = "accounts"

    private(set) var accounts: [Account] = []

    // MARK: - Lifecycle

    init() {
        guard let data = Keychain.read(Self.keychainKey) else { return }
        accounts = (try? JSONDecoder().decode([Account].self, from: data)) ?? []
    }

    // MARK: - Changes

    func add(name: String, secret: String) {
        accounts.append(Account(name: name, secret: secret))
        save()
    }

    func delete(_ account: Account) {
        accounts.removeAll { $0.id == account.id }
        save()
    }

    // MARK: - Storage

    private func save() {
        guard let data = try? JSONEncoder().encode(accounts) else { return }
        Keychain.write(data, to: Self.keychainKey)
    }
}
