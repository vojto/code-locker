import CryptoKit
import Foundation

/*
 * One login you have codes for, like "GitHub". This is what AccountStore saves.
 * An unlocked account keeps its secret as plain text. A locked one has no plain
 * secret: it is encrypted with a random key, and that key is time-locked to a
 * drand round. So the saved data is useless until that round's signature is
 * published. Old saved files (always locked) read in as locked accounts.
 */

struct Account: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    var secret: String?
    var lastLockPeriod: LockPeriod?

    // Only set while locked.
    private(set) var round: UInt64?
    private(set) var lockedKey: Data?
    private(set) var sealedSecret: Data?

    init(name: String, secret: String) {
        self.id = UUID()
        self.name = name
        self.secret = secret
    }

    /// When the lock opens, or nil while unlocked.
    var opening: Date? {
        round.map { Drand.date(of: $0) }
    }

    // MARK: - Locking

    /// A copy that can't be read until `period` is over. Works offline.
    func locked(for period: LockPeriod) -> Account? {
        let key = SymmetricKey(size: .bits128)
        let round = Drand.round(at: period.end(from: .now))

        guard
            let secret,
            let lockedKey = Timelock.lock(key.withUnsafeBytes { Data($0) }, untilRound: round),
            let sealedSecret = try? AES.GCM.seal(Data(secret.utf8), using: key).combined
        else { return nil }

        var account = self
        account.secret = nil
        account.round = round
        account.lockedKey = lockedKey
        account.sealedSecret = sealedSecret
        account.lastLockPeriod = period
        return account
    }

    // MARK: - Unlocking

    /// A plain copy, opened with the drand signature for this account's round.
    func unlocked(signature: Data) -> Account? {
        guard
            let lockedKey,
            let sealedSecret,
            let key = Timelock.unlock(lockedKey, signature: signature),
            let box = try? AES.GCM.SealedBox(combined: sealedSecret),
            let secret = try? AES.GCM.open(box, using: SymmetricKey(data: key))
        else { return nil }

        var account = self
        account.secret = String(decoding: secret, as: UTF8.self)
        account.round = nil
        account.lockedKey = nil
        account.sealedSecret = nil
        return account
    }
}
