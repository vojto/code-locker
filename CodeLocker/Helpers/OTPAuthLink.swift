import Foundation

/*
 * Reads an "otpauth://totp/GitHub:me?secret=ABC&issuer=GitHub" link, the text hidden
 * inside a setup QR code. Used by the add-account sheet so you can paste the whole
 * link instead of just the key. Pulls out the secret and a name for the account.
 */

struct OTPAuthLink {
    let name: String
    let secret: String

    init?(_ string: String) {
        guard
            let components = URLComponents(string: string.trimmingCharacters(in: .whitespacesAndNewlines)),
            components.scheme == "otpauth",
            let secret = components.queryItems?.first(where: { $0.name == "secret" })?.value
        else { return nil }

        let issuer = components.queryItems?.first(where: { $0.name == "issuer" })?.value
        let label = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        self.name = issuer ?? label
        self.secret = secret
    }
}
