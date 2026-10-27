import Foundation

public struct VocabularyFile: Codable {
    public let schemaVersion: Int
    public let snapshotSHA256: String
    public let entries: [VocabularyEntry]

    public init(schemaVersion: Int, snapshotSHA256: String, entries: [VocabularyEntry]) {
        self.schemaVersion = schemaVersion
        self.snapshotSHA256 = snapshotSHA256
        self.entries = entries
    }
}

public struct VocabularyEntry: Codable, Identifiable, Hashable {
    public let id: String
    public let lemma: String
    public let pos: String
    public let gender: String?
    public let article: String?
    public let english: String
    public let french: String
    public let examples: [String]
    public let sourceRow: Int
    public let usageNote: String?

    public init(
        id: String,
        lemma: String,
        pos: String,
        gender: String?,
        article: String?,
        english: String,
        french: String,
        examples: [String],
        sourceRow: Int,
        usageNote: String?
    ) {
        self.id = id
        self.lemma = lemma
        self.pos = pos
        self.gender = gender
        self.article = article
        self.english = english
        self.french = french
        self.examples = examples
        self.sourceRow = sourceRow
        self.usageNote = usageNote
    }

    public var isVerb: Bool { pos.uppercased() == "VER" }

    public var displayTitle: String {
        guard !isVerb, let article, !article.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return lemma
        }
        let trimmedArticle = article.trimmingCharacters(in: .whitespacesAndNewlines)
        let separator = (trimmedArticle.hasSuffix("'") || trimmedArticle.hasSuffix("’")) ? "" : " "
        return "\(trimmedArticle)\(separator)\(lemma)"
    }

    public var partOfSpeech: String {
        switch pos.uppercased() {
        case "VER": return "Verb"
        case "NOM": return "Noun"
        case "ADJ": return "Adjective"
        case "ADV": return "Adverb"
        case "PRP", "PRE": return "Preposition"
        case "KON", "CON": return "Conjunction"
        case "PRO": return "Pronoun"
        case "INT": return "Interjection"
        case "DET:ART": return "Article"
        case let value where value.hasPrefix("PRO:"): return "Pronoun"
        case let value where value.hasPrefix("DET:"): return "Determiner"
        default: return pos
        }
    }
}

public struct ConjugationFile: Codable {
    public let schemaVersion: Int
    public let verbs: [VerbConjugation]

    public init(schemaVersion: Int, verbs: [VerbConjugation]) {
        self.schemaVersion = schemaVersion
        self.verbs = verbs
    }
}

public struct VerbConjugation: Codable, Hashable {
    public let entryID: String
    public let infinitive: String
    public let usageNote: String?
    public let tenses: [TenseTable]

    public init(entryID: String, infinitive: String, usageNote: String?, tenses: [TenseTable]) {
        self.entryID = entryID
        self.infinitive = infinitive
        self.usageNote = usageNote
        self.tenses = tenses
    }
}

public struct TenseTable: Codable, Identifiable, Hashable {
    public let id: String
    public let title: String
    public let rows: [ConjugationRow]

    public init(id: String, title: String, rows: [ConjugationRow]) {
        self.id = id
        self.title = title
        self.rows = rows
    }
}

public struct ConjugationRow: Codable, Hashable {
    public let person: String
    public let form: String
    public let example: String

    public init(person: String, form: String, example: String) {
        self.person = person
        self.form = form
        self.example = example
    }
}

public struct ProgressFile: Codable {
    public let schemaVersion: Int
    public let records: [String: ProgressRecord]

    public init(schemaVersion: Int = 1, records: [String: ProgressRecord]) {
        self.schemaVersion = schemaVersion
        self.records = records
    }
}

public struct ProgressRecord: Codable, Hashable {
    public let learnedAt: Date
    public let dueAt: Date
    public let intervalIndex: Int?
    public let lastReviewedAt: Date?

    public init(learnedAt: Date, dueAt: Date, intervalIndex: Int?, lastReviewedAt: Date?) {
        self.learnedAt = learnedAt
        self.dueAt = dueAt
        self.intervalIndex = intervalIndex
        self.lastReviewedAt = lastReviewedAt
    }
}

public enum StableVocabularyID {
    public static func make(lemma: String, sourcePOS: String) -> String {
        let normalizedLemma = lemma.precomposedStringWithCanonicalMapping.lowercased()
        return "\(normalizedLemma)|\(sourcePOS.uppercased())"
    }
}
