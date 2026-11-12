import Foundation
import Security

/*
 * Saves and loads a blob of data in the macOS Keychain, so secrets are encrypted
 * and never sit in a plain file. Used by AccountStore. Each blob is one
 * "generic password" item, filed under this app's bundle ID.
 */

enum Keychain {
    private static let service = Bundle.main.bundleIdentifier ?? "CodeLocker"

    static func read(_ key: String) -> Data? {
        var query = baseQuery(key)
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne

        var result: CFTypeRef?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }

    @discardableResult
    static func write(_ data: Data, to key: String) -> Bool {
        let query = baseQuery(key) as CFDictionary
        var status = SecItemUpdate(query, [kSecValueData: data] as CFDictionary)

        if status == errSecItemNotFound {
            var item = baseQuery(key)
            item[kSecValueData] = data
            status = SecItemAdd(item as CFDictionary, nil)
        }

        return status == errSecSuccess
    }

    private static func baseQuery(_ key: String) -> [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
        ]
    }
}
