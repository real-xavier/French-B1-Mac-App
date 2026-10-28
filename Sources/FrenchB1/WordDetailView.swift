import AppKit
import SwiftUI

public struct WordDetailView: View {
    public let entry: VocabularyEntry
    @ObservedObject private var store: AppStore
    private let showAddButton: Bool

    public init(entry: VocabularyEntry, store: AppStore, showAddButton: Bool = true) {
        self.entry = entry
        self.store = store
        self.showAddButton = showAddButton
    }

    private var progress: ProgressRecord? {
        store.progress[entry.id]
    }

    private var verb: VerbConjugation? {
        store.verbsByEntryID[entry.id]
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    SelectableText(entry.displayTitle, font: .systemFont(ofSize: 34, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    SelectableText(metadata, font: .systemFont(ofSize: 14), color: .secondaryLabelColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 5) {
                        sectionLabel("English")
                        SelectableText(entry.english, font: .systemFont(ofSize: 21, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        sectionLabel("French definition")
                        SelectableText(entry.french, font: .systemFont(ofSize: 17))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if let translation = entry.frenchTranslation, !translation.isEmpty {
                            SelectableText(translation, font: .systemFont(ofSize: 13), color: .secondaryLabelColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("Examples", size: 18)
                    if entry.examples.isEmpty {
                        SelectableText("No examples are available for this word.", color: .secondaryLabelColor)
                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(entry.examples.enumerated()), id: \.offset) { index, example in
                                VStack(alignment: .leading, spacing: 4) {
                                    SelectableText(example, font: .systemFont(ofSize: 15))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    if let translation = translation(forExampleAt: index) {
                                        SelectableText(translation, font: .systemFont(ofSize: 13), color: .secondaryLabelColor)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .padding(.vertical, 11)
                                if index < entry.examples.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    }
                }

                if showAddButton {
                    reviewAction
                        .padding(.top, 2)
                }

                if let usageNote = entry.usageNote, !usageNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        sectionLabel("Usage note")
                        SelectableText(usageNote, font: .systemFont(ofSize: 14), color: .secondaryLabelColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if entry.isVerb {
                    if let verb {
                        VerbTableView(verb: verb)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Divider()
                            sectionLabel("Conjugation", size: 18)
                            SelectableText("No conjugation tables are available for this verb.", color: .secondaryLabelColor)
                        }
                    }
                }

            }
            .padding(.horizontal, 32)
            .padding(.top, 28)
            .padding(.bottom, 36)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var metadata: String {
        var parts = ["B1", entry.partOfSpeech.lowercased()]
        if let gender = entry.gender, !gender.isEmpty {
            parts.append(gender.lowercased())
        }
        return parts.joined(separator: "  •  ")
    }

    @ViewBuilder
    private var reviewAction: some View {
        if let progress {
            VStack(alignment: .leading, spacing: 4) {
                Button("In review", systemImage: "tray.full.fill") {}
                    .buttonStyle(.bordered)
                    .disabled(true)
                SelectableText(dueDescription(progress.dueAt), font: .systemFont(ofSize: 12), color: .secondaryLabelColor)
                    .padding(.leading, 3)
            }
        } else {
            Button("Add to review", systemImage: "plus") {
                store.addToReview(entry.id)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private func sectionLabel(_ title: String, size: CGFloat = 13) -> some View {
        SelectableText(title, font: .systemFont(ofSize: size, weight: .semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func dueDescription(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInTomorrow(date) { return "Due tomorrow" }
        if calendar.isDateInToday(date) { return "Due today" }
        if date <= store.currentDate() { return "Due now" }
        return "Due \(date.formatted(date: .abbreviated, time: .omitted))"
    }

    private func translation(forExampleAt index: Int) -> String? {
        guard let translations = entry.exampleTranslations, translations.indices.contains(index) else { return nil }
        return translations[index].isEmpty ? nil : translations[index]
    }
}
