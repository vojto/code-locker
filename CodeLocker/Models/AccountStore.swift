import Foundation
import Observation

/*
 * The accounts shown in the window. Views read `accounts` and call add, lock
 * and delete.
 *
 * New accounts are unlocked. Locking one swaps its plain secret for the
 * time-locked form. Every few seconds the store looks for locks whose time has
 * passed, fetches their drand signature and turns them back into plain ones.
 *
 * Release builds save to accounts.json in iCloud (or locally when not signed
 * in), debug builds to a local file. Nothing is saved until the file has been
 * read, so an empty list can't overwrite real data. `isLoaded` tells the window
 * when that has happened, so it can show "Loading" before it. While the list is empty,
 * the store keeps re-reading the file, in case iCloud brings it in late.
 */

@Observable
final class AccountStore {
    private(set) var accounts: [Account] = []

    /// Set once the file has been read. Saving waits for it.
    private var fileURL: URL?

    var isLoaded: Bool { fileURL != nil }

    // MARK: - Lifecycle

    init() {
        Task { await run() }
    }

    private func run() async {
        await load(from: await Self.findFileURL())

        while true {
            await unlockOpenedAccounts()
            try? await Task.sleep(for: .seconds(5))
            if accounts.isEmpty, let fileURL { await load(from: fileURL) }
        }
    }

    // MARK: - Changes

    func add(name: String, secret: String) {
        accounts.append(Account(name: name, secret: secret))
        save()
    }

    func lock(_ account: Account, for period: LockPeriod) {
        guard let locked = account.locked(for: period) else { return }
        replace(locked)
    }

    func delete(_ account: Account) {
        accounts.removeAll { $0.id == account.id }
        save()
    }

    private func replace(_ account: Account) {
        guard let index = accounts.firstIndex(where: { $0.id == account.id }) else { return }
        accounts[index] = account
        save()
    }

    // MARK: - Unlocking

    /// Opens every lock whose time has passed. If drand can't be reached yet, the next tick tries again.
    private func unlockOpenedAccounts() async {
        for account in accounts {
            guard
                let opening = account.opening,
                opening <= .now,
                let round = account.round,
                let signature = try? await Drand.signature(for: round),
                let unlocked = account.unlocked(signature: signature)
            else { continue }

            replace(unlocked)
        }
    }

    // MARK: - Storage

    private func load(from url: URL) async {
        if let data = await Self.read(url), let saved = try? JSONDecoder().decode([Account].self, from: data) {
            accounts = saved
        }

        fileURL = url
    }

    private func save() {
        guard let fileURL, let data = try? JSONEncoder().encode(accounts) else { return }
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: .atomic)
    }

    /// Reading from iCloud can block, so it happens off the main thread.
    @concurrent
    nonisolated private static func read(_ url: URL) async -> Data? {
        try? FileManager.default.startDownloadingUbiquitousItem(at: url)
        return try? Data(contentsOf: url)
    }

    /// The iCloud file in release builds, falling back to the local one. Moves an
    /// existing local file into iCloud the first time. Can block, so runs off the main thread.
    @concurrent
    nonisolated private static func findFileURL() async -> URL {
        let localURL = URL.applicationSupportDirectory.appending(path: "accounts.json")

        #if DEBUG
        return localURL
        #else
        guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: "iCloud.net.rinik.CodeLocker") else {
            return localURL
        }

        let cloudURL = containerURL.appending(path: "accounts.json")
        if !FileManager.default.fileExists(atPath: cloudURL.path(percentEncoded: false)), FileManager.default.fileExists(atPath: localURL.path(percentEncoded: false)) {
            try? FileManager.default.setUbiquitous(true, itemAt: localURL, destinationURL: cloudURL)
        }
        return cloudURL
        #endif
    }
}
