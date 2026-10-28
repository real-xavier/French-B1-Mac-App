import Combine
import Foundation

@MainActor
public final class AppStore: ObservableObject {
    @Published public private(set) var entries: [VocabularyEntry] = []
    @Published public private(set) var verbsByEntryID: [String: VerbConjugation] = [:]
    @Published public private(set) var progress: [String: ProgressRecord] = [:]
    @Published public var loadError: String?
    @Published public var saveError: String?

    private let now: () -> Date
    private let calendar: Calendar
    private let persistence: ProgressPersistence
    private var progressCanBeSafelyWritten = true
    private var lastDueEntryIDs = Set<String>()

    public init(
        resourceURL: URL? = nil,
        progressURL: URL? = nil,
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = .current,
        progressPersistence: ProgressPersistence? = nil
    ) {
        self.now = now
        self.calendar = calendar
        self.persistence = progressPersistence ?? ProgressPersistence(fileURL: progressURL)

        do {
            let corpus = try CorpusLoader.load(resourceURL: resourceURL)
            self.entries = corpus.vocabulary.entries.sorted { lhs, rhs in
                let leftKey = Self.orderingKey(lhs.lemma)
                let rightKey = Self.orderingKey(rhs.lemma)
                if leftKey != rightKey {
                    return leftKey.localizedStandardCompare(rightKey) == .orderedAscending
                }
                return lhs.id.localizedStandardCompare(rhs.id) == .orderedAscending
            }
            self.verbsByEntryID = Dictionary(uniqueKeysWithValues: corpus.conjugations.verbs.map { ($0.entryID, $0) })
        } catch {
            self.loadError = error.localizedDescription
        }

        do {
            self.progress = try persistence.load().records
        } catch {
            self.progressCanBeSafelyWritten = false
            self.saveError = error.localizedDescription
        }
        let initializationTime = now()
        self.lastDueEntryIDs = Set(entries.compactMap { entry in
            guard let record = progress[entry.id], record.dueAt <= initializationTime else { return nil }
            return entry.id
        })
    }

    public func search(_ query: String) -> [VocabularyEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return entries }
        let foldedQuery = Self.fold(trimmed)
        return entries.filter { entry in
            let searchableText = [entry.lemma, entry.displayTitle, entry.english, entry.french] + entry.examples
            return searchableText.contains { Self.fold($0).contains(foldedQuery) }
        }
    }

    @discardableResult
    public func addToReview(_ id: String) -> Bool {
        guard entries.contains(where: { $0.id == id }) else { return false }
        guard progress[id] == nil else { return true }

        var proposed = progress
        proposed[id] = ReviewScheduler.initial(now: currentDate(), calendar: calendar)
        return commit(proposed)
    }

    @discardableResult
    public func grade(_ id: String, remembered: Bool) -> Bool {
        guard entries.contains(where: { $0.id == id }), let record = progress[id] else { return false }
        var proposed = progress
        proposed[id] = ReviewScheduler.graded(record, remembered: remembered, now: currentDate(), calendar: calendar)
        return commit(proposed)
    }

    public func reviewEntries(all: Bool) -> [VocabularyEntry] {
        let now = currentDate()
        return entries
            .filter { entry in
                guard let record = progress[entry.id] else { return false }
                return all || record.dueAt <= now
            }
            .sorted { lhs, rhs in
                let lhsDue = progress[lhs.id]?.dueAt ?? .distantFuture
                let rhsDue = progress[rhs.id]?.dueAt ?? .distantFuture
                if lhsDue != rhsDue { return lhsDue < rhsDue }
                return lhs.id < rhs.id
            }
    }

    public func nextDueDate() -> Date? {
        entries.compactMap { progress[$0.id]?.dueAt }.min()
    }

    public func refreshDueState() {
        let now = currentDate()
        let dueIDs = Set<String>(entries.compactMap { entry in
            guard let record = progress[entry.id], record.dueAt <= now else { return nil }
            return entry.id
        })
        guard dueIDs != lastDueEntryIDs else { return }
        lastDueEntryIDs = dueIDs
        objectWillChange.send()
    }

    public func isLearned(_ id: String) -> Bool {
        progress[id] != nil
    }

    public func currentDate() -> Date { now() }

    private func commit(_ proposed: [String: ProgressRecord]) -> Bool {
        guard progressCanBeSafelyWritten else {
            if saveError == nil {
                saveError = "Saved progress could not be safely updated because the existing file failed to load."
            }
            return false
        }
        do {
            try persistence.save(records: proposed)
        } catch {
            saveError = error.localizedDescription
            return false
        }
        progress = proposed
        saveError = nil
        return true
    }

    private static func fold(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }

    private static func orderingKey(_ lemma: String) -> String {
        fold(lemma).trimmingCharacters(in: .punctuationCharacters.union(.whitespacesAndNewlines))
    }
}
