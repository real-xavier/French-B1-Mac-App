import Foundation
import XCTest
@testable import FrenchB1

@MainActor
final class AppStoreTests: XCTestCase {
    private var calendar: Calendar { Self.torontoCalendar() }
    private var now: Date { date(2025, 5, 15, 12) }

    func testSearchFoldsAccentsAndCaseAcrossUnlearnedEntries() throws {
        let resourceURL = try TestCorpusFixture.makeResourceFolder()
        defer { try? FileManager.default.removeItem(at: resourceURL) }
        let store = makeStore(resourceURL: resourceURL)

        XCTAssertEqual(store.search("CAFE").map(\.id), ["café|NOM"])
        XCTAssertEqual(store.search("TEA").map(\.id), ["thé|NOM"])
        XCTAssertFalse(store.isLearned("café|NOM"))
        XCTAssertFalse(store.isLearned("thé|NOM"))
    }

    func testPackagedResourceRootResolvesInsideNestedSwiftPackageBundle() throws {
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: temporary) }
        let resources = temporary
            .appendingPathComponent("French B1.app/Contents/Resources", isDirectory: true)
        let nestedBundle = resources.appendingPathComponent("FrenchB1_FrenchB1.bundle", isDirectory: true)
        let nestedResources = nestedBundle.appendingPathComponent("Contents/Resources", isDirectory: true)
        try FileManager.default.createDirectory(at: nestedResources, withIntermediateDirectories: true)
        let info: [String: Any] = [
            "CFBundleIdentifier": "local.personal.FrenchB1.resources",
            "CFBundlePackageType": "BNDL",
            "CFBundleName": "FrenchB1_FrenchB1"
        ]
        let infoData = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try infoData.write(to: nestedBundle.appendingPathComponent("Contents/Info.plist"))
        try Data("{}".utf8).write(to: nestedResources.appendingPathComponent("vocabulary.json"))
        try Data("{}".utf8).write(to: nestedResources.appendingPathComponent("verbs.json"))

        let resolved = try XCTUnwrap(CorpusLoader.packagedResourceRoot(inAppResourcesDirectory: resources))
        XCTAssertEqual(resolved.standardizedFileURL.path, nestedResources.standardizedFileURL.path)
    }

    func testDictionaryOrderPlacesPunctuationLeadingLemmaWithItsLetter() throws {
        let hyphenatedParticle = VocabularyEntry(
            id: StableVocabularyID.make(lemma: "-ci", sourcePOS: "ADV"),
            lemma: "-ci",
            pos: "ADV",
            gender: nil,
            article: nil,
            english: "here (used with demonstratives)",
            french: "Particule postposée à un démonstratif pour désigner un élément précis.",
            examples: [
                "Choisis ce sac-ci, il est plus solide.",
                "Cette année-ci, les prix ont moins augmenté.",
                "Celui-ci est libre, tu peux t’asseoir."
            ],
            sourceRow: 1,
            usageNote: nil
        )
        let entries = [
            hyphenatedParticle,
            TestCorpusFixture.noun("abbaye", english: "abbey", french: "Bâtiment où vivent des moines ou des moniales.", row: 2),
            TestCorpusFixture.verb("aborder", english: "to approach", row: 3)
        ]
        let resourceURL = try TestCorpusFixture.makeResourceFolder(entries: entries)
        defer { try? FileManager.default.removeItem(at: resourceURL) }

        let store = AppStore(resourceURL: resourceURL)

        XCTAssertNil(store.loadError)
        XCTAssertEqual(store.entries.map(\.lemma), ["abbaye", "aborder", "-ci"])
    }

    func testDueCardsAreSortedByEarliestDateAndAllIncludesFutureCards() throws {
        let resourceURL = try TestCorpusFixture.makeResourceFolder()
        defer { try? FileManager.default.removeItem(at: resourceURL) }
        let progressURL = resourceURL.appendingPathComponent("progress.json")
        let records = [
            "café|NOM": record(due: now.addingTimeInterval(-60)),
            "thé|NOM": record(due: now.addingTimeInterval(-300)),
            "parler|VER": record(due: now.addingTimeInterval(600))
        ]
        try ProgressPersistence(fileURL: progressURL).save(records: records)
        let store = makeStore(resourceURL: resourceURL, progressURL: progressURL)

        XCTAssertEqual(store.reviewEntries(all: false).map(\.id), ["thé|NOM", "café|NOM"])
        XCTAssertEqual(store.reviewEntries(all: true).map(\.id), ["thé|NOM", "café|NOM", "parler|VER"])
        XCTAssertEqual(store.nextDueDate(), now.addingTimeInterval(-300))
    }

    func testRestartRetainsOrphansAndProgressWhenDictionaryContentChanges() throws {
        let originalResources = try TestCorpusFixture.makeResourceFolder()
        defer { try? FileManager.default.removeItem(at: originalResources) }
        let updatedResources = try TestCorpusFixture.makeResourceFolder()
        defer { try? FileManager.default.removeItem(at: updatedResources) }
        let progressURL = originalResources.appendingPathComponent("progress.json")
        let originalRecord = record(due: now)
        try ProgressPersistence(fileURL: progressURL).save(records: [
            "café|NOM": originalRecord,
            "thé|NOM": record(due: now.addingTimeInterval(86_400)),
            "retired-word|NOM": record(due: now.addingTimeInterval(86_400))
        ])

        let updatedEntries = TestCorpusFixture.entries.compactMap { entry -> VocabularyEntry? in
            guard entry.id != "thé|NOM" else { return nil }
            guard entry.id == "café|NOM" else { return entry }
            return VocabularyEntry(
                id: entry.id,
                lemma: entry.lemma,
                pos: entry.pos,
                gender: entry.gender,
                article: entry.article,
                english: "roasted coffee",
                french: entry.french,
                examples: entry.examples,
                sourceRow: entry.sourceRow,
                usageNote: entry.usageNote
            )
        }
        try rewriteVocabulary(at: updatedResources, entries: updatedEntries)

        let store = makeStore(resourceURL: updatedResources, progressURL: progressURL)

        XCTAssertNil(store.loadError)
        XCTAssertEqual(store.search("roasted coffee").first?.id, "café|NOM")
        XCTAssertEqual(store.progress["café|NOM"], originalRecord)
        XCTAssertNotNil(store.progress["thé|NOM"], "A record removed from the current corpus remains stored as an orphan.")
        XCTAssertNotNil(store.progress["retired-word|NOM"])
        XCTAssertFalse(store.reviewEntries(all: true).contains(where: { $0.id == "thé|NOM" }))

        let restartedStore = makeStore(resourceURL: updatedResources, progressURL: progressURL)
        XCTAssertEqual(restartedStore.progress, store.progress)
    }

    func testFailedSaveLeavesStoreAndExistingDiskFileUnchanged() throws {
        let resourceURL = try TestCorpusFixture.makeResourceFolder()
        defer { try? FileManager.default.removeItem(at: resourceURL) }
        let progressURL = resourceURL.appendingPathComponent("progress.json")
        let existing = ["café|NOM": record(due: now)]
        try ProgressPersistence(fileURL: progressURL).save(records: existing)
        let originalBytes = try Data(contentsOf: progressURL)
        let failingPersistence = ProgressPersistence(fileURL: progressURL) { _, _ in
            throw TestWriteError.diskFull
        }
        let store = AppStore(
            resourceURL: resourceURL,
            progressURL: progressURL,
            now: { self.now },
            calendar: calendar,
            progressPersistence: failingPersistence
        )

        XCTAssertFalse(store.addToReview("thé|NOM"))
        XCTAssertFalse(store.grade("café|NOM", remembered: true))
        XCTAssertEqual(store.progress, existing)
        XCTAssertEqual(try Data(contentsOf: progressURL), originalBytes)
        XCTAssertNotNil(store.saveError)
    }

    func testMalformedCorpusReportsTheInvalidExampleCount() throws {
        let resourceURL = try TestCorpusFixture.makeResourceFolder()
        defer { try? FileManager.default.removeItem(at: resourceURL) }
        let entries = TestCorpusFixture.entries.map { entry -> VocabularyEntry in
            guard entry.id == "café|NOM" else { return entry }
            return VocabularyEntry(
                id: entry.id,
                lemma: entry.lemma,
                pos: entry.pos,
                gender: entry.gender,
                article: entry.article,
                english: entry.english,
                french: entry.french,
                examples: Array(entry.examples.prefix(2)),
                sourceRow: entry.sourceRow,
                usageNote: entry.usageNote
            )
        }
        try rewriteVocabulary(at: resourceURL, entries: entries)

        let store = makeStore(resourceURL: resourceURL)

        XCTAssertTrue(store.entries.isEmpty)
        XCTAssertTrue(store.loadError?.contains("examples must contain exactly 3 sentences") == true)
    }

    func testLoaderDiagnosesMissingVerbCoverage() throws {
        let resourceURL = try TestCorpusFixture.makeResourceFolder()
        defer { try? FileManager.default.removeItem(at: resourceURL) }
        var entries = TestCorpusFixture.entries
        entries.append(TestCorpusFixture.verb("finir", english: "to finish", row: 4))
        let vocabulary = VocabularyFile(
            schemaVersion: 1,
            snapshotSHA256: String(repeating: "c", count: 64),
            entries: entries
        )
        try JSONEncoder().encode(vocabulary).write(to: resourceURL.appendingPathComponent("vocabulary.json"))
        try TestCorpusFixture.writeConjugations(
            for: TestCorpusFixture.entries,
            to: resourceURL
        )

        let store = makeStore(resourceURL: resourceURL)

        XCTAssertTrue(store.loadError?.contains("missing conjugations for: finir|VER") == true)
    }

    private func makeStore(resourceURL: URL, progressURL: URL? = nil) -> AppStore {
        AppStore(resourceURL: resourceURL, progressURL: progressURL, now: { self.now }, calendar: calendar)
    }

    private func record(due: Date) -> ProgressRecord {
        ProgressRecord(learnedAt: now.addingTimeInterval(-86_400), dueAt: due, intervalIndex: 0, lastReviewedAt: nil)
    }

    private func rewriteVocabulary(at root: URL, entries: [VocabularyEntry]) throws {
        let file = VocabularyFile(schemaVersion: 1, snapshotSHA256: String(repeating: "b", count: 64), entries: entries)
        try JSONEncoder().encode(file).write(to: root.appendingPathComponent("vocabulary.json"))
        try TestCorpusFixture.writeConjugations(for: entries, to: root)
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

private enum TestWriteError: Error {
    case diskFull
}
