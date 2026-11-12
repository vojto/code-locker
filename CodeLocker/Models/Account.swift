import CryptoKit
import Foundation

/*
 * One login you have codes for, like "GitHub", in its locked form. This is what
 * gets saved to disk by AccountStore. The secret is encrypted with a random key,
 * and that key is time-locked to a drand round. So the saved data is useless
 * until the round's signature is published.
 */

struct Account: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let round: UInt64
    let lockedKey: Data
    let sealedSecret: Data

    // MARK: - Locking

    /// Locks `secret` so it can't be read before `opening`. Works offline.
    init?(id: UUID = UUID(), name: String, secret: String, opening: Date) {
        let key = SymmetricKey(size: .bits128)
        let round = Drand.round(at: opening)

        guard
            let lockedKey = Timelock.lock(key.withUnsafeBytes { Data($0) }, untilRound: round),
            let sealedSecret = try? AES.GCM.seal(Data(secret.utf8), using: key).combined
        else { return nil }

        self.id = id
        self.name = name
        self.round = round
        self.lockedKey = lockedKey
        self.sealedSecret = sealedSecret
    }

    // MARK: - Unlocking

    /// Reads the secret using the drand signature for this account's round.
    func secret(signature: Data) -> String? {
        guard
            let key = Timelock.unlock(lockedKey, signature: signature),
            let box = try? AES.GCM.SealedBox(combined: sealedSecret),
            let secret = try? AES.GCM.open(box, using: SymmetricKey(data: key))
        else { return nil }

        return String(decoding: secret, as: UTF8.self)
    }
}
