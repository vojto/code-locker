import AppKit

/*
 * Puts text on the clipboard. Used when you click a code to copy it.
 */

enum Pasteboard {
    static func copy(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }
}
