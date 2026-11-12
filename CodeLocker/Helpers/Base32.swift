import Foundation

/*
 * Turns the secret key a website gives you ("JBSW Y3DP EHPK 3PXP") into raw bytes.
 * Used by TOTP to make codes and by the add-account sheet to check the key is valid.
 * Ignores spaces, dashes, padding and letter case. Returns nil for anything else.
 */

enum Base32 {
    private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")

    static func decode(_ string: String) -> Data? {
        let characters = string.uppercased().filter { !" -=\n\t".contains($0) }
        guard !characters.isEmpty else { return nil }

        var data = Data()
        var buffer = 0
        var bitCount = 0

        for character in characters {
            guard let value = alphabet.firstIndex(of: character) else { return nil }
            buffer = (buffer << 5) | value
            bitCount += 5

            if bitCount >= 8 {
                bitCount -= 8
                data.append(UInt8((buffer >> bitCount) & 0xFF))
            }
        }

        return data
    }
}
