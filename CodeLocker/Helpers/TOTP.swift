import CryptoKit
import Foundation

/*
 * Makes the 6-digit login codes, the same way Google Authenticator does (RFC 6238).
 * Used by AccountRow. Time is cut into 30-second steps; the step number is signed
 * with the account's secret (HMAC-SHA1) and squeezed down to 6 digits.
 */

enum TOTP {
    static let period: TimeInterval = 30
    private static let digitCount = 6

    /// The code for a secret key as the website shows it ("JBSW Y3DP…"), or nil if the key is not valid.
    static func code(base32Secret: String, at date: Date) -> String? {
        Base32.decode(base32Secret).map { code(secret: $0, at: date) }
    }

    static func code(secret: Data, at date: Date) -> String {
        let counter = UInt64(date.timeIntervalSince1970 / period).bigEndian
        let counterData = withUnsafeBytes(of: counter) { Data($0) }
        let hash = Array(HMAC<Insecure.SHA1>.authenticationCode(for: counterData, using: SymmetricKey(data: secret)))

        let offset = Int(hash[hash.count - 1] & 0x0F)
        let number = hash[offset...offset + 3].reduce(UInt32(0)) { ($0 << 8) | UInt32($1) } & 0x7FFF_FFFF

        let code = String(number % 1_000_000)
        return String(repeating: "0", count: digitCount - code.count) + code
    }

    static func secondsRemaining(at date: Date) -> TimeInterval {
        period - date.timeIntervalSince1970.truncatingRemainder(dividingBy: period)
    }
}
