import Foundation
import XCTest
@testable import FrenchB1

@MainActor
final class IntegrationAcceptanceTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Toronto")!
        return calendar
    }

    func testAllRememberedIntervalsAndCap() {
        let now = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 12))!
        var record = ReviewScheduler.initial(now: now, calendar: calendar)
        XCTAssertEqual(record.intervalIndex, 0)
        XCTAssertEqual(record.dueAt, calendar.date(byAdding: .day, value: 1, to: now))
        for (index, days) in [(1,3), (2,7), (3,14), (4,30), (5,60), (5,60)] {
            let reviewedAt = record.dueAt
            record = ReviewScheduler.graded(record, remembered: true, now: reviewedAt, calendar: calendar)
            XCTAssertEqual(record.intervalIndex, index)
            XCTAssertEqual(record.dueAt, calendar.date(byAdding: .day, value: days, to: reviewedAt))
        }
    }

    func testAddingAlreadyLearnedEntryIsIdempotent() throws {
        let folder = try TestCorpusFixture.makeResourceFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("progress.json")
        var instant = Date(timeIntervalSince1970: 1_800_000_000)
        let store = AppStore(resourceURL: folder, progressURL: file, now: { instant }, calendar: calendar)
        XCTAssertTrue(store.addToReview("café|NOM"))
        let original = store.progress["café|NOM"]
        let originalBytes = try Data(contentsOf: file)
        instant = instant.addingTimeInterval(600)
        XCTAssertTrue(store.addToReview("café|NOM"))
        XCTAssertEqual(store.progress["café|NOM"], original)
        XCTAssertEqual(try Data(contentsOf: file), originalBytes)
    }

    func testRealAtomicWriteFailurePreservesPreviousFileAndCard() throws {
        let resources = try TestCorpusFixture.makeResourceFolder()
        let parent = resources.appendingPathComponent("read-only-progress", isDirectory: true)
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: parent.path)
            try? FileManager.default.removeItem(at: resources)
        }
        let file = parent.appendingPathComponent("progress.json")
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let original = ProgressRecord(learnedAt: now.addingTimeInterval(-86_400), dueAt: now, intervalIndex: 0, lastReviewedAt: nil)
        try ProgressPersistence(fileURL: file).save(records: ["café|NOM": original])
        let bytes = try Data(contentsOf: file)
        let store = AppStore(resourceURL: resources, progressURL: file, now: { now }, calendar: calendar)
        let cardBefore = store.reviewEntries(all: false).first?.id
        try FileManager.default.setAttributes([.posixPermissions: 0o500], ofItemAtPath: parent.path)
        XCTAssertFalse(store.grade("café|NOM", remembered: true))
        XCTAssertEqual(store.reviewEntries(all: false).first?.id, cardBefore)
        XCTAssertEqual(store.progress["café|NOM"], original)
        XCTAssertEqual(try Data(contentsOf: file), bytes)
        XCTAssertNotNil(store.saveError)
    }
}
