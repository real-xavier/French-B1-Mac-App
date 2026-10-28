import Foundation
@testable import FrenchB1

enum TestCorpusFixture {
    static let entries: [VocabularyEntry] = [
        noun("café", english: "coffee", french: "Une boisson préparée avec des grains torréfiés.", row: 1),
        noun("thé", english: "tea", french: "Une boisson chaude infusée.", row: 2),
        verb("parler", english: "to speak", row: 3)
    ]

    static func makeResourceFolder(entries: [VocabularyEntry] = entries) throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FrenchB1Tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let vocabulary = VocabularyFile(
            schemaVersion: 1,
            snapshotSHA256: String(repeating: "a", count: 64),
            entries: entries
        )
        try JSONEncoder().encode(vocabulary).write(to: root.appendingPathComponent("vocabulary.json"))
        try encodeConjugations(for: entries).write(to: root.appendingPathComponent("verbs.json"))
        return root
    }

    static func writeConjugations(for entries: [VocabularyEntry], to root: URL) throws {
        try encodeConjugations(for: entries).write(to: root.appendingPathComponent("verbs.json"))
    }

    static func entry(_ id: String, in entries: [VocabularyEntry] = entries) -> VocabularyEntry {
        guard let result = entries.first(where: { $0.id == id }) else {
            fatalError("Fixture has no entry with ID \(id)")
        }
        return result
    }

    static func noun(_ lemma: String, english: String, french: String, row: Int) -> VocabularyEntry {
        VocabularyEntry(
            id: StableVocabularyID.make(lemma: lemma, sourcePOS: "NOM"),
            lemma: lemma,
            pos: "NOM",
            gender: "masculine",
            article: "le",
            english: english,
            french: french,
            examples: [
                "Je choisis le \(lemma) avec soin.",
                "Nous parlons souvent de \(lemma) ensemble.",
                "Elle préfère le \(lemma) le matin."
            ],
            sourceRow: row,
            usageNote: nil
        )
    }

    static func verb(_ lemma: String, english: String, row: Int) -> VocabularyEntry {
        VocabularyEntry(
            id: StableVocabularyID.make(lemma: lemma, sourcePOS: "VER"),
            lemma: lemma,
            pos: "VER",
            gender: nil,
            article: nil,
            english: english,
            french: "Produire des mots pour communiquer avec quelqu’un.",
            examples: [
                "Je vais \(lemma) avec mon voisin.",
                "Ils aiment \(lemma) de leurs voyages.",
                "Nous devons \(lemma) plus lentement."
            ],
            sourceRow: row,
            usageNote: nil
        )
    }

    private static func encodeConjugations(for entries: [VocabularyEntry]) throws -> Data {
        let tenses = [
            ("present", "Présent"),
            ("passeCompose", "Passé composé"),
            ("imparfait", "Imparfait"),
            ("futurProche", "Futur proche"),
            ("futurSimple", "Futur simple"),
            ("conditionnel", "Conditionnel"),
            ("imperatif", "Impératif")
        ]
        let verbs = entries.filter(\.isVerb).map { entry in
            VerbConjugation(
                entryID: entry.id,
                infinitive: entry.lemma,
                usageNote: nil,
                tenses: tenses.map { id, title in
                    TenseTable(
                        id: id,
                        title: title,
                        rows: [ConjugationRow(person: "je", form: "je parle", example: "Je parle français avec plaisir.")]
                    )
                }
            )
        }
        return try JSONEncoder().encode(ConjugationFile(schemaVersion: 1, verbs: verbs))
    }
}
