import Foundation

/*
 * How long to lock an account for, like "2 weeks". Picked in LockSheet and
 * remembered on each Account, so locking again suggests the same period.
 */

struct LockPeriod: Codable, Equatable {
    enum Unit: String, Codable, CaseIterable, Identifiable {
        case minutes
        case hours
        case days
        case weeks

        var id: Self { self }

        var title: String {
            rawValue.capitalized
        }
    }

    var amount: Int
    var unit: Unit

    static let standard = LockPeriod(amount: 1, unit: .weeks)

    /// When a lock that starts at `date` opens again.
    func end(from date: Date) -> Date {
        Calendar.current.date(byAdding: component, value: amount, to: date) ?? date
    }

    private var component: Calendar.Component {
        switch unit {
        case .minutes: .minute
        case .hours: .hour
        case .days: .day
        case .weeks: .weekOfYear
        }
    }
}
