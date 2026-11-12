import Foundation

/*
 * Locks a 16-byte key until a drand round, and opens it again with that round's
 * signature. Used by Account. Locking works offline. The maths lives in the
 * Rust library in the Timelock folder; this is the Swift face of it.
 */

enum Timelock {
    static let keySize = 16

    static func lock(_ key: Data, untilRound round: UInt64) -> Data? {
        guard key.count == keySize else { return nil }

        let publicKey = [UInt8](Drand.publicKey)
        var locked = [UInt8](repeating: 0, count: 256)
        let length = timelock_encrypt(publicKey, publicKey.count, round, [UInt8](key), &locked, locked.count)

        return length > 0 ? Data(locked.prefix(length)) : nil
    }

    static func unlock(_ locked: Data, signature: Data) -> Data? {
        var key = [UInt8](repeating: 0, count: keySize)
        let status = timelock_decrypt([UInt8](signature), signature.count, [UInt8](locked), locked.count, &key)

        return status == 0 ? Data(key) : nil
    }
}
