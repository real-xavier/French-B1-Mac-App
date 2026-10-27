import XCTest
@testable import FrenchB1

final class ReviewSchedulerTests: XCTestCase {
    private var calendar: Calendar { Self.torontoCalendar() }

    func testFirstRememberedGradeSchedulesThreeCalendarDays() {
        let learned = date(2025, 1, 10, 12)
        let initial = ReviewScheduler.initial(now: learned, calendar: calendar)

        let next = ReviewScheduler.graded(initial, remembered: true, now: initial.dueAt, calendar: calendar)

        XCTAssertEqual(next.intervalIndex, 1)
        XCTAssertEqual(next.dueAt, date(2025, 1, 14, 12))
        XCTAssertEqual(next.learnedAt, learned)
    }

    func testIntervalCapsAtSixtyDays() {
        let learned = date(2025, 1, 10, 12)
        let record = ProgressRecord(
            learnedAt: learned,
            dueAt: date(2025, 3, 11, 12),
            intervalIndex: 5,
            lastReviewedAt: date(2025, 1, 10, 12)
        )

        let next = ReviewScheduler.graded(record, remembered: true, now: date(2025, 3, 11, 12), calendar: calendar)

        XCTAssertEqual(next.intervalIndex, 5)
        XCTAssertEqual(next.dueAt, date(2025, 5, 10, 12))
    }

    func testAgainClearsIntervalAndSchedulesTenMinutesLater() {
        let learned = date(2025, 4, 10, 9)
        let record = ReviewScheduler.initial(now: learned, calendar: calendar)

        let next = ReviewScheduler.graded(record, remembered: false, now: date(2025, 4, 11, 10), calendar: calendar)

        XCTAssertNil(next.intervalIndex)
        XCTAssertEqual(next.dueAt, date(2025, 4, 11, 10).addingTimeInterval(600))
        XCTAssertEqual(next.lastReviewedAt, date(2025, 4, 11, 10))
        XCTAssertEqual(next.learnedAt, learned)
    }

    func testRepeatedAgainKeepsIntervalNilAndResetsTenMinuteDelay() {
        let learned = date(2025, 4, 10, 9)
        let first = ProgressRecord(learnedAt: learned, dueAt: learned, intervalIndex: nil, lastReviewedAt: nil)
        let firstAgainAt = date(2025, 4, 11, 10)
        let afterFirstAgain = ReviewScheduler.graded(first, remembered: false, now: firstAgainAt, calendar: calendar)
        let secondAgainAt = firstAgainAt.addingTimeInterval(3 * 60)

        let afterSecondAgain = ReviewScheduler.graded(afterFirstAgain, remembered: false, now: secondAgainAt, calendar: calendar)

        XCTAssertNil(afterSecondAgain.intervalIndex)
        XCTAssertEqual(afterSecondAgain.dueAt, secondAgainAt.addingTimeInterval(600))
        XCTAssertEqual(afterSecondAgain.learnedAt, learned)
    }

    func testRememberedAfterAgainStartsAtOneCalendarDay() {
        let learned = date(2025, 4, 10, 9)
        let againAt = date(2025, 4, 11, 10)
        let afterAgain = ProgressRecord(
            learnedAt: learned,
            dueAt: againAt.addingTimeInterval(600),
            intervalIndex: nil,
            lastReviewedAt: againAt
        )

        let next = ReviewScheduler.graded(afterAgain, remembered: true, now: date(2025, 4, 11, 11), calendar: calendar)

        XCTAssertEqual(next.intervalIndex, 0)
        XCTAssertEqual(next.dueAt, date(2025, 4, 12, 11))
    }

    func testTorontoSpringAndFallTransitionsUseLocalCalendarDays() {
        let springNoon = date(2025, 3, 8, 12)
        let springDue = ReviewScheduler.initial(now: springNoon, calendar: calendar).dueAt
        XCTAssertEqual(springDue, date(2025, 3, 9, 12))
        XCTAssertEqual(springDue.timeIntervalSince(springNoon), 23 * 60 * 60)

        let fallNoon = date(2025, 11, 1, 12)
        let fallDue = ReviewScheduler.initial(now: fallNoon, calendar: calendar).dueAt
        XCTAssertEqual(fallDue, date(2025, 11, 2, 12))
        XCTAssertEqual(fallDue.timeIntervalSince(fallNoon), 25 * 60 * 60)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private static func torontoCalendar() -> Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(identifier: "America/Toronto")!
        return result
    }
}
