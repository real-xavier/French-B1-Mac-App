import AppKit
import SwiftUI

public struct ReviewView: View {
    @ObservedObject private var store: AppStore
    private let searchText: String
    private let onLearn: () -> Void

    @State private var showsAllLearned = false
    @State private var currentEntryID: String?
    @State private var answerIsVisible = false

    public init(
        store: AppStore,
        searchText: String,
        onLearn: @escaping () -> Void = {}
    ) {
        self.store = store
        self.searchText = searchText
        self.onLearn = onLearn
    }

    private var cards: [VocabularyEntry] {
        store.reviewEntries(all: showsAllLearned)
    }

    private var cardIDs: [String] {
        cards.map(\.id)
    }

    private var currentCard: VocabularyEntry? {
        if let currentEntryID, let matchingCard = cards.first(where: { $0.id == currentEntryID }) {
            return matchingCard
        }
        return cards.first
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if let currentCard {
                cardContent(currentCard)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                emptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear(perform: synchronizeCard)
        .onChange(of: cardIDs) { _, _ in synchronizeCard() }
        .onChange(of: showsAllLearned) { _, _ in
            currentEntryID = nil
            answerIsVisible = false
            synchronizeCard()
        }
        .task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
                store.refreshDueState()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                SelectableText("Review", font: .systemFont(ofSize: 25, weight: .semibold))
                SelectableText(
                    showsAllLearned ? "Browse every word you’ve learned." : "Practice the words that are due.",
                    font: .systemFont(ofSize: 13),
                    color: .secondaryLabelColor
                )
            }

            Spacer(minLength: 18)

            Picker("Cards", selection: $showsAllLearned) {
                Text("Due now").tag(false)
                Text("All learned").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 225)
            .accessibilityLabel("Review cards")
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
    }

    @ViewBuilder
    private func cardContent(_ entry: VocabularyEntry) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    SelectableText(
                        showsAllLearned ? "LEARNED WORD" : "DUE NOW",
                        font: .systemFont(ofSize: 11, weight: .bold),
                        color: .secondaryLabelColor
                    )
                    Spacer()
                    SelectableText("\(cards.firstIndex(where: { $0.id == entry.id }).map { $0 + 1 } ?? 1) of \(cards.count)",
                                   font: .systemFont(ofSize: 12), color: .tertiaryLabelColor)
                }
                .padding(.bottom, 20)

                SelectableText(entry.displayTitle, font: .systemFont(ofSize: 38, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                SelectableText(entry.partOfSpeech, font: .systemFont(ofSize: 14), color: .secondaryLabelColor)
                    .padding(.top, 6)

                if answerIsVisible {
                    answer(entry)
                        .padding(.top, 28)
                } else {
                    Button {
                        answerIsVisible = true
                    } label: {
                        Label("Show answer", systemImage: "eye")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.top, 34)
                    .accessibilityHint("Reveals the English and French meanings and examples")
                }

                if answerIsVisible {
                    Divider().padding(.vertical, 24)
                    HStack(spacing: 12) {
                        Button {
                            grade(entry, remembered: false)
                        } label: {
                            Label("Again", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .accessibilityHint("Review this word again in ten minutes")

                        Button {
                            grade(entry, remembered: true)
                        } label: {
                            Label("Remembered", systemImage: "checkmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
            }
            .padding(30)
            .frame(maxWidth: 700, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.35), lineWidth: 1)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 28)
            .padding(.vertical, 32)
        }
    }

    private func answer(_ entry: VocabularyEntry) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                sectionHeading("English")
                SelectableText(entry.english, font: .systemFont(ofSize: 21, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 6) {
                sectionHeading("French definition")
                SelectableText(entry.french, font: .systemFont(ofSize: 16))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 9) {
                sectionHeading("Examples")
                ForEach(Array(entry.examples.enumerated()), id: \.offset) { index, example in
                    SelectableText(example, font: .systemFont(ofSize: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    if index < entry.examples.count - 1 { Divider() }
                }
            }

            if let usageNote = entry.usageNote, !usageNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    sectionHeading("Usage note")
                    SelectableText(usageNote, font: .systemFont(ofSize: 13), color: .secondaryLabelColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if entry.isVerb, let verb = store.verbsByEntryID[entry.id] {
                VerbTableView(verb: verb)
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        let learnedCards = store.reviewEntries(all: true)
        VStack(alignment: .leading, spacing: 12) {
            if learnedCards.isEmpty {
                SelectableText("No cards yet", font: .systemFont(ofSize: 28, weight: .semibold))
                SelectableText("Add a word to review from its dictionary entry, then come back here to practice.", color: .secondaryLabelColor)
                    .frame(maxWidth: 440, alignment: .leading)
                Button("Learn a word", systemImage: "book.closed", action: onLearn)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 6)
            } else {
                SelectableText("Nothing due right now", font: .systemFont(ofSize: 28, weight: .semibold))
                if let nextDueDate = store.nextDueDate() {
                    SelectableText(nextDueDescription(nextDueDate), color: .secondaryLabelColor)
                } else {
                    SelectableText("Your next review will appear here when it’s due.", color: .secondaryLabelColor)
                }
                Button("Show all learned", systemImage: "rectangle.stack", action: { showsAllLearned = true })
                    .buttonStyle(.bordered)
                    .padding(.top, 6)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func sectionHeading(_ title: String) -> some View {
        SelectableText(title, font: .systemFont(ofSize: 13, weight: .semibold), color: .secondaryLabelColor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func grade(_ entry: VocabularyEntry, remembered: Bool) {
        guard store.grade(entry.id, remembered: remembered) else { return }

        answerIsVisible = false
        let updatedCards = store.reviewEntries(all: showsAllLearned)
        currentEntryID = updatedCards.first(where: { $0.id != entry.id })?.id ?? updatedCards.first?.id
    }

    private func synchronizeCard() {
        if let currentEntryID, cardIDs.contains(currentEntryID) { return }
        currentEntryID = cards.first?.id
        answerIsVisible = false
    }

    private func nextDueDescription(_ date: Date) -> String {
        let dateText = date.formatted(date: .abbreviated, time: .shortened)
        return "Your next card is due \(dateText)."
    }
}
