import Foundation

/*
 * Small date helpers. Used by AccountRow to say when a locked account opens.
 */

extension Date {
    /// "in 3 days", counted from `date` instead of from now, so it follows the
    /// view's ticking clock.
    func relativeText(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: date)
    }
}
