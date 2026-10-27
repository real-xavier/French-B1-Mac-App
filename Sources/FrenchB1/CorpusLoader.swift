import Foundation

public struct LoadedCorpus {
    public let vocabulary: VocabularyFile
    public let conjugations: ConjugationFile

    public init(vocabulary: VocabularyFile, conjugations: ConjugationFile) {
        self.vocabulary = vocabulary
        self.conjugations = conjugations
    }
}

public enum CorpusLoader {
    private static let vocabularyFilename = "vocabulary.json"
    private static let verbsFilename = "verbs.json"
    private static let expectedTenseIDs = [
        "present", "passeCompose", "imparfait", "futurProche", "futurSimple", "conditionnel", "imperatif"
    ]

    public static func defaultResourceURL() -> URL? {
        // A packaged app must resolve content from its own bundle. Do not use
        // SwiftPM's generated development-directory fallback in this branch.
        if Bundle.main.bundleURL.pathExtension.lowercased() == "app" {
            guard let resources = Bundle.main.resourceURL else { return nil }
            return packagedResourceRoot(inAppResourcesDirectory: resources)
        }
        return Bundle.module.resourceURL
    }

    static func packagedResourceRoot(inAppResourcesDirectory resources: URL) -> URL? {
        let resourceBundleURL = resources.appendingPathComponent("FrenchB1_FrenchB1.bundle", isDirectory: true)
        guard let resourceBundle = Bundle(url: resourceBundleURL),
              let root = resourceBundle.resourceURL,
              FileManager.default.fileExists(atPath: root.appendingPathComponent(vocabularyFilename).path),
              FileManager.default.fileExists(atPath: root.appendingPathComponent(verbsFilename).path) else {
            return nil
        }
        return root
    }

    public static func load(resourceURL: URL? = nil) throws -> LoadedCorpus {
        guard let root = resourceURL ?? defaultResourceURL() else {
            throw CorpusLoaderError.resourceRootUnavailable
        }
        let vocabularyURL = root.appendingPathComponent(vocabularyFilename)
        let verbsURL = root.appendingPathComponent(verbsFilename)
        let vocabulary: VocabularyFile = try decode(VocabularyFile.self, from: vocabularyURL)
        let conjugations: ConjugationFile = try decode(ConjugationFile.self, from: verbsURL)
        try validate(vocabulary: vocabulary, conjugations: conjugations)
        if resourceURL == nil {
            guard vocabulary.entries.count == 1753, conjugations.verbs.count == 395 else {
                throw CorpusLoaderError.invalidCount(file: "bundled dictionary", detail: "this pinned snapshot requires 1,753 entries and 395 verbs")
            }
            guard vocabulary.snapshotSHA256 == "e0cbdb672fa4f83155acec4c8f01f179b30be08cb3d2d6cf0d9f25042b01e3d4" else {
                throw CorpusLoaderError.invalidField(file: vocabularyFilename, item: "snapshotSHA256", field: "does not match the pinned FLELex snapshot")
            }
        }
        return LoadedCorpus(vocabulary: vocabulary, conjugations: conjugations)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw CorpusLoaderError.fileReadFailed(url: url, detail: error.localizedDescription)
        }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            let path: String
            if case let DecodingError.keyNotFound(key, context) = error {
                let parents = context.codingPath.map(\.stringValue) + [key.stringValue]
                path = parents.joined(separator: ".")
            } else if let decodingError = error as? DecodingError {
                switch decodingError {
                case let .typeMismatch(_, context), let .valueNotFound(_, context), let .dataCorrupted(context):
                    path = context.codingPath.map(\.stringValue).joined(separator: ".")
                case .keyNotFound:
                    path = ""
                @unknown default:
                    path = ""
                }
            } else {
                path = ""
            }
            let location = path.isEmpty ? "" : " at \(path)"
            throw CorpusLoaderError.invalidJSON(url: url, detail: "\(error.localizedDescription)\(location)")
        }
    }

    private static func validate(vocabulary: VocabularyFile, conjugations: ConjugationFile) throws {
        guard vocabulary.schemaVersion == 1 else {
            throw CorpusLoaderError.unsupportedSchema(file: vocabularyFilename, found: vocabulary.schemaVersion)
        }
        guard conjugations.schemaVersion == 1 else {
            throw CorpusLoaderError.unsupportedSchema(file: verbsFilename, found: conjugations.schemaVersion)
        }
        guard vocabulary.snapshotSHA256.count == 64,
              vocabulary.snapshotSHA256.allSatisfy({ $0.isHexDigit }) else {
            throw CorpusLoaderError.invalidField(file: vocabularyFilename, item: "snapshotSHA256", field: "expected a 64-character SHA-256 hex digest")
        }
        guard !vocabulary.entries.isEmpty else {
            throw CorpusLoaderError.invalidCount(file: vocabularyFilename, detail: "contains no vocabulary entries")
        }

        var entriesByID: [String: VocabularyEntry] = [:]
        for (index, entry) in vocabulary.entries.enumerated() {
            let item = "entries[\(index)] (\(entry.id))"
            try requireText(entry.id, file: vocabularyFilename, item: item, field: "id")
            try requireText(entry.lemma, file: vocabularyFilename, item: item, field: "lemma")
            try requireText(entry.pos, file: vocabularyFilename, item: item, field: "pos")
            try requireText(entry.english, file: vocabularyFilename, item: item, field: "english")
            try requireText(entry.french, file: vocabularyFilename, item: item, field: "french")
            guard entry.sourceRow > 0 else {
                throw CorpusLoaderError.invalidField(file: vocabularyFilename, item: item, field: "sourceRow must be a positive 1-based data row")
            }
            guard entry.id == StableVocabularyID.make(lemma: entry.lemma, sourcePOS: entry.pos) else {
                throw CorpusLoaderError.invalidField(file: vocabularyFilename, item: item, field: "id does not match the stable lemma|POS ID")
            }
            guard entriesByID[entry.id] == nil else {
                throw CorpusLoaderError.duplicateID(file: vocabularyFilename, id: entry.id)
            }
            guard entry.examples.count == 3 else {
                throw CorpusLoaderError.invalidField(file: vocabularyFilename, item: item, field: "examples must contain exactly 3 sentences (found \(entry.examples.count))")
            }
            let normalizedExamples = entry.examples.map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            }
            guard Set(normalizedExamples).count == 3 else {
                throw CorpusLoaderError.invalidField(file: vocabularyFilename, item: item, field: "examples must be three distinct sentences")
            }
            for (exampleIndex, example) in entry.examples.enumerated() {
                try requireText(example, file: vocabularyFilename, item: item, field: "examples[\(exampleIndex)]")
            }
            if entry.pos.uppercased() == "NOM" {
                let documentedSourceTagAnomaly = entry.usageNote?.hasPrefix("Source tag note:") == true
                if entry.gender == nil && entry.article == nil && documentedSourceTagAnomaly {
                    // Preserve the source row without inventing noun morphology for a mis-tagged item.
                } else {
                    try requireOptionalText(entry.gender, file: vocabularyFilename, item: item, field: "gender")
                    try requireOptionalText(entry.article, file: vocabularyFilename, item: item, field: "article")
                    guard entry.gender != nil, entry.article != nil else {
                        throw CorpusLoaderError.invalidField(file: vocabularyFilename, item: item, field: "noun entries require both gender and article unless documented with a ‘Source tag note:’ usageNote")
                    }
                }
            }
            try requireOptionalText(entry.usageNote, file: vocabularyFilename, item: item, field: "usageNote")
            entriesByID[entry.id] = entry
        }

        guard !conjugations.verbs.isEmpty else {
            throw CorpusLoaderError.invalidCount(file: verbsFilename, detail: "contains no verb conjugations")
        }
        let vocabularyVerbIDs = Set(entriesByID.values.filter(\.isVerb).map(\.id))
        let conjugationIDs = Set(conjugations.verbs.map(\.entryID))
        guard vocabularyVerbIDs == conjugationIDs else {
            let missing = vocabularyVerbIDs.subtracting(conjugationIDs).sorted()
            let extra = conjugationIDs.subtracting(vocabularyVerbIDs).sorted()
            var detail = "verb vocabulary and conjugation IDs must match"
            if !missing.isEmpty { detail += "; missing conjugations for: \(missing.prefix(5).joined(separator: ", "))" }
            if !extra.isEmpty { detail += "; unknown conjugations: \(extra.prefix(5).joined(separator: ", "))" }
            throw CorpusLoaderError.invalidCount(file: verbsFilename, detail: detail)
        }
        var seenVerbIDs = Set<String>()
        for (index, verb) in conjugations.verbs.enumerated() {
            let item = "verbs[\(index)] (\(verb.entryID))"
            guard seenVerbIDs.insert(verb.entryID).inserted else {
                throw CorpusLoaderError.duplicateID(file: verbsFilename, id: verb.entryID)
            }
            try requireText(verb.entryID, file: verbsFilename, item: item, field: "entryID")
            try requireText(verb.infinitive, file: verbsFilename, item: item, field: "infinitive")
            try requireOptionalText(verb.usageNote, file: verbsFilename, item: item, field: "usageNote")
            guard let matchingEntry = entriesByID[verb.entryID], matchingEntry.isVerb else {
                throw CorpusLoaderError.invalidField(file: verbsFilename, item: item, field: "entryID must refer to a vocabulary verb")
            }
            guard !verb.tenses.isEmpty else {
                throw CorpusLoaderError.invalidField(file: verbsFilename, item: item, field: "tenses must not be empty")
            }
            let actualTenseIDs = verb.tenses.map(\.id)
            guard actualTenseIDs == expectedTenseIDs else {
                throw CorpusLoaderError.invalidField(
                    file: verbsFilename,
                    item: item,
                    field: "tenses must use the schema 1 IDs in order: \(expectedTenseIDs.joined(separator: ", "))"
                )
            }
            for tense in verb.tenses {
                let tenseItem = "\(item).tenses[\(tense.id)]"
                try requireText(tense.title, file: verbsFilename, item: tenseItem, field: "title")
                if tense.rows.isEmpty && verb.usageNote?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
                    throw CorpusLoaderError.invalidField(file: verbsFilename, item: tenseItem, field: "empty rows require an explanatory usageNote for a defective form")
                }
                var seenPersons = Set<String>()
                for (rowIndex, row) in tense.rows.enumerated() {
                    let rowItem = "\(tenseItem).rows[\(rowIndex)]"
                    try requireText(row.person, file: verbsFilename, item: rowItem, field: "person")
                    try requireText(row.form, file: verbsFilename, item: rowItem, field: "form")
                    try requireText(row.example, file: verbsFilename, item: rowItem, field: "example")
                    guard seenPersons.insert(row.person).inserted else {
                        throw CorpusLoaderError.invalidField(file: verbsFilename, item: tenseItem, field: "duplicate person row \(row.person)")
                    }
                }
            }
        }
    }

    private static func requireText(_ value: String, file: String, item: String, field: String) throws {
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CorpusLoaderError.invalidField(file: file, item: item, field: "\(field) must not be empty")
        }
    }

    private static func requireOptionalText(_ value: String?, file: String, item: String, field: String) throws {
        if let value {
            try requireText(value, file: file, item: item, field: field)
        }
    }
}

public enum CorpusLoaderError: LocalizedError {
    case resourceRootUnavailable
    case fileReadFailed(url: URL, detail: String)
    case invalidJSON(url: URL, detail: String)
    case unsupportedSchema(file: String, found: Int)
    case invalidCount(file: String, detail: String)
    case duplicateID(file: String, id: String)
    case invalidField(file: String, item: String, field: String)

    public var errorDescription: String? {
        switch self {
        case .resourceRootUnavailable:
            return "The French B1 resource folder could not be found in the app bundle."
        case let .fileReadFailed(url, detail):
            return "Could not read \(url.lastPathComponent): \(detail)"
        case let .invalidJSON(url, detail):
            return "Invalid \(url.lastPathComponent): \(detail)"
        case let .unsupportedSchema(file, found):
            return "Unsupported schemaVersion \(found) in \(file); this app supports schema 1."
        case let .invalidCount(file, detail):
            return "Invalid content count in \(file): \(detail)."
        case let .duplicateID(file, id):
            return "Duplicate ID ‘\(id)’ in \(file)."
        case let .invalidField(file, item, field):
            return "Invalid \(file), \(item): \(field)."
        }
    }
}
