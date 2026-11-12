import Foundation

/*
 * Says when codes are allowed to be seen. Used by AccountStore to decide when to
 * unlock and re-lock. The real app opens all day on Sundays. Debug builds open
 * for 1 minute in every 3, so the whole cycle can be tested quickly.
 */

enum Schedule {
    case sundays
    case testCycle

    static var current: Schedule {
        #if DEBUG
        .testCycle
        #else
        .sundays
        #endif
    }

    private static let testCycleLength: TimeInterval = 180
    private static let testOpenLength: TimeInterval = 60

    // MARK: - Questions

    func isOpen(at date: Date) -> Bool {
        switch self {
        case .sundays:
            Calendar.current.component(.weekday, from: date) == 1
        case .testCycle:
            date.timeIntervalSince1970.truncatingRemainder(dividingBy: Self.testCycleLength) < Self.testOpenLength
        }
    }

    /// The next time codes become available, strictly after `date`.
    func nextOpening(after date: Date) -> Date {
        switch self {
        case .sundays:
            nextMidnight(after: date, weekday: 1)
        case .testCycle:
            testCycleStart(for: date) + Self.testCycleLength
        }
    }

    /// The next time codes get locked away again, strictly after `date`.
    func nextClosing(after date: Date) -> Date {
        switch self {
        case .sundays:
            nextMidnight(after: date, weekday: 2)
        case .testCycle:
            isOpen(at: date)
                ? testCycleStart(for: date) + Self.testOpenLength
                : testCycleStart(for: date) + Self.testCycleLength + Self.testOpenLength
        }
    }

    // MARK: - Helpers

    private func nextMidnight(after date: Date, weekday: Int) -> Date {
        let midnight = DateComponents(hour: 0, minute: 0, second: 0, weekday: weekday)
        return Calendar.current.nextDate(after: date, matching: midnight, matchingPolicy: .nextTime) ?? .distantFuture
    }

    private func testCycleStart(for date: Date) -> Date {
        let seconds = date.timeIntervalSince1970
        return Date(timeIntervalSince1970: seconds - seconds.truncatingRemainder(dividingBy: Self.testCycleLength))
    }
}
