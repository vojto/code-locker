import Foundation

/*
 * One login you have codes for, like "GitHub". Holds its name and its secret key.
 * Saved by AccountStore and shown by AccountRow.
 */

struct Account: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var secret: String

    func code(at date: Date) -> String {
        guard let secretData = Base32.decode(secret) else { return "------" }
        return TOTP.code(secret: secretData, at: date)
    }
}
