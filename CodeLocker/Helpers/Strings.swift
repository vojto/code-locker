import Foundation

/*
 * Small text helpers. Used by the views that show login codes.
 */

extension String {
    /// "482913" becomes "482 913", which is easier to read and type.
    var groupedInThrees: String {
        "\(prefix(3)) \(suffix(3))"
    }
}
