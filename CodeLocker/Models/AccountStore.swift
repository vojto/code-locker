import Foundation
import Observation

/*
 * The accounts shown in the window, and the keeper of the lock. Views read
 * `accounts`, `secrets` and `status`, and call add/delete.
 *
 * Accounts are saved to a file in time-locked form. While the schedule is open,
 * the store fetches the drand signatures and keeps the readable secrets in
 * memory only. When the schedule closes, it locks every account again for the
 * next opening and forgets the secrets. It checks every few seconds.
 */

@Observable
final class AccountStore {
    enum Status {
        case checking
        case offline
        case locked
        case open
    }

    private(set) var accounts: [Account] = []
    private(set) var secrets: [UUID: String] = [:]
    private(set) var status = Status.checking

    let schedule = Schedule.current

    private static let fileURL = URL.applicationSupportDirectory.appending(path: "accounts.json")

    // MARK: - Lifecycle

    init() {
        load()
        Task { await keepInSync() }
    }

    // MARK: - Changes

    func add(name: String, secret: String) {
        // While open, lock for right now so it stays readable until closing time.
        let isOpen = status == .open
        let opening = isOpen ? Date.now : schedule.nextOpening(after: .now)

        guard let account = Account(name: name, secret: secret, opening: opening) else { return }

        accounts.append(account)
        if isOpen { secrets[account.id] = secret }
        save()
    }

    func delete(_ account: Account) {
        accounts.removeAll { $0.id == account.id }
        secrets[account.id] = nil
        save()
    }

    // MARK: - Locking and unlocking

    private func keepInSync() async {
        while true {
            if isOutOfSync { await sync() }
            try? await Task.sleep(for: .seconds(5))
        }
    }

    private var isOutOfSync: Bool {
        switch status {
        case .checking, .offline:
            true
        case .open:
            !schedule.isOpen(at: .now) || accounts.contains { isOpenable($0) && secrets[$0.id] == nil }
        case .locked:
            schedule.isOpen(at: .now) || accounts.contains(where: isOpenable)
        }
    }

    private func isOpenable(_ account: Account) -> Bool {
        Drand.date(of: account.round) <= .now
    }

    /// Opens or re-locks accounts to match the schedule, going by drand's time.
    private func sync() async {
        guard let latestRound = try? await Drand.latestRound() else {
            secrets = [:]
            status = .offline
            return
        }

        let now = Drand.date(of: latestRound)
        let isOpen = schedule.isOpen(at: now)

        for account in accounts where account.round <= latestRound {
            guard let secret = await secret(for: account) else { continue }

            if isOpen {
                secrets[account.id] = secret
            } else {
                relock(account, secret: secret, opening: schedule.nextOpening(after: now))
            }
        }

        if !isOpen { secrets = [:] }
        status = isOpen ? .open : .locked
        save()
    }

    private func secret(for account: Account) async -> String? {
        if let secret = secrets[account.id] { return secret }
        guard let signature = try? await Drand.signature(for: account.round) else { return nil }
        return account.secret(signature: signature)
    }

    private func relock(_ account: Account, secret: String, opening: Date) {
        guard
            let index = accounts.firstIndex(where: { $0.id == account.id }),
            let relocked = Account(id: account.id, name: account.name, secret: secret, opening: opening)
        else { return }

        accounts[index] = relocked
    }

    // MARK: - Storage

    private func load() {
        guard let data = try? Data(contentsOf: Self.fileURL) else { return }
        accounts = (try? JSONDecoder().decode([Account].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(accounts) else { return }
        try? FileManager.default.createDirectory(at: Self.fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: Self.fileURL, options: .atomic)
    }
}
