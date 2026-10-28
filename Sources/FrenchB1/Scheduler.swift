import Foundation

public enum ReviewScheduler {
    public static let intervals = [1, 3, 7, 14, 30, 60]

    public static func initial(now: Date, calendar: Calendar) -> ProgressRecord {
        ProgressRecord(
            learnedAt: now,
            dueAt: adding(days: intervals[0], to: now, calendar: calendar),
            intervalIndex: 0,
            lastReviewedAt: nil
        )
    }

    public static func graded(
        _ record: ProgressRecord,
        remembered: Bool,
        now: Date,
        calendar: Calendar
    ) -> ProgressRecord {
        if remembered {
            let nextIndex: Int
            if let previousIndex = record.intervalIndex {
                nextIndex = min(max(previousIndex + 1, 0), intervals.count - 1)
            } else {
                nextIndex = 0
            }
            return ProgressRecord(
                learnedAt: record.learnedAt,
                dueAt: adding(days: intervals[nextIndex], to: now, calendar: calendar),
                intervalIndex: nextIndex,
                lastReviewedAt: now
            )
        }

        return ProgressRecord(
            learnedAt: record.learnedAt,
            dueAt: now.addingTimeInterval(10 * 60),
            intervalIndex: nil,
            lastReviewedAt: now
        )
    }

    private static func adding(days: Int, to date: Date, calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }
}
