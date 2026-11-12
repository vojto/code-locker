import Foundation

/*
 * Turns hex text like "83cf0f" into raw bytes. Used by Drand, which sends its
 * keys and signatures as hex.
 */

extension Data {
    init(hex: String) {
        let characters = Array(hex)
        let bytes = stride(from: 0, to: characters.count - 1, by: 2).compactMap {
            UInt8(String(characters[$0...$0 + 1]), radix: 16)
        }
        self.init(bytes)
    }
}
