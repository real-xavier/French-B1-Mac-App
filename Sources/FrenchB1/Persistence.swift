import Foundation

public struct ProgressPersistence {
    public typealias Writer = (_ data: Data, _ destination: URL) throws -> Void

    public let fileURL: URL?
    private let writer: Writer

    public init(fileURL: URL? = nil, writer: @escaping Writer = ProgressPersistence.atomicWriter) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
        self.writer = writer
    }

    public func load() throws -> ProgressFile {
        guard let fileURL else { throw ProgressPersistenceError.storageURLUnavailable }
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return ProgressFile(records: [:])
        }

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw ProgressPersistenceError.readFailed(url: fileURL, detail: error.localizedDescription)
        }

        let progressFile: ProgressFile
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let text = try container.decode(String.self)
                let fractional = ISO8601DateFormatter()
                fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = fractional.date(from: text) { return date }
                let standard = ISO8601DateFormatter()
                standard.formatOptions = [.withInternetDateTime]
                if let date = standard.date(from: text) { return date }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected an ISO8601 date string, found ‘\(text)’.")
            }
            progressFile = try decoder.decode(ProgressFile.self, from: data)
        } catch {
            throw ProgressPersistenceError.invalidFile(url: fileURL, detail: error.localizedDescription)
        }

        guard progressFile.schemaVersion == 1 else {
            throw ProgressPersistenceError.unsupportedSchema(url: fileURL, found: progressFile.schemaVersion)
        }
        try Self.validate(progressFile)
        return progressFile
    }

    public func save(records: [String: ProgressRecord]) throws {
        guard let fileURL else { throw ProgressPersistenceError.storageURLUnavailable }
        let file = ProgressFile(records: records)
        try Self.validate(file)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            var container = encoder.singleValueContainer()
            try container.encode(formatter.string(from: date))
        }
        let data: Data
        do {
            data = try encoder.encode(file)
        } catch {
            throw ProgressPersistenceError.encodingFailed(error.localizedDescription)
        }
        do {
            try writer(data, fileURL)
        } catch {
            throw ProgressPersistenceError.writeFailed(url: fileURL, detail: error.localizedDescription)
        }
    }

    public static func atomicWriter(_ data: Data, _ destination: URL) throws {
        let parent = destination.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        try data.write(to: destination, options: .atomic)
    }

    public static func defaultFileURL() -> URL? {
        guard let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return applicationSupport
            .appendingPathComponent("FrenchB1", isDirectory: true)
            .appendingPathComponent("progress.json", isDirectory: false)
    }

    private static func validate(_ file: ProgressFile) throws {
        for (id, record) in file.records {
            guard !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw ProgressPersistenceError.invalidRecord(id: id, detail: "record ID must not be empty")
            }
            if let index = record.intervalIndex, !(0..<ReviewScheduler.intervals.count).contains(index) {
                throw ProgressPersistenceError.invalidRecord(id: id, detail: "intervalIndex must be between 0 and \(ReviewScheduler.intervals.count - 1), or null")
            }
        }
    }
}

public enum ProgressPersistenceError: LocalizedError {
    case storageURLUnavailable
    case readFailed(url: URL, detail: String)
    case invalidFile(url: URL, detail: String)
    case unsupportedSchema(url: URL, found: Int)
    case encodingFailed(String)
    case writeFailed(url: URL, detail: String)
    case invalidRecord(id: String, detail: String)

    public var errorDescription: String? {
        switch self {
        case .storageURLUnavailable:
            return "The app could not determine where to store review progress."
        case let .readFailed(url, detail):
            return "Could not read saved progress at \(url.path): \(detail)"
        case let .invalidFile(url, detail):
            return "Saved progress at \(url.path) is invalid: \(detail)"
        case let .unsupportedSchema(url, found):
            return "Saved progress at \(url.path) uses schema \(found); this app supports schema 1."
        case let .encodingFailed(detail):
            return "Could not encode review progress: \(detail)"
        case let .writeFailed(url, detail):
            return "Could not save review progress at \(url.path): \(detail)"
        case let .invalidRecord(id, detail):
            return "Invalid saved progress record ‘\(id)’: \(detail)."
        }
    }
}
