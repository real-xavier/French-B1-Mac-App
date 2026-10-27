import AppKit
import SwiftUI

public struct DictionaryView: View {
    @ObservedObject private var store: AppStore
    private let searchText: String
    @State private var selectedEntryID: String?

    public init(store: AppStore, searchText: String) {
        self.store = store
        self.searchText = searchText
    }

    private var results: [VocabularyEntry] {
        store.search(searchText)
    }

    private var resultIDs: [String] {
        results.map(\.id)
    }

    private var selectedEntry: VocabularyEntry? {
        guard let selectedEntryID else { return nil }
        return results.first { $0.id == selectedEntryID }
    }

    public var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 0) {
                SelectableText("Vocabulary", font: .systemFont(ofSize: 13, weight: .semibold), color: .secondaryLabelColor)
                    .padding(.horizontal, 15)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                if results.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SelectableText("No matching words", font: .systemFont(ofSize: 15, weight: .medium))
                        SelectableText("Try a French word, an English meaning, or part of an example.", font: .systemFont(ofSize: 13), color: .secondaryLabelColor)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                } else {
                    List {
                        ForEach(results) { entry in
                            let isSelected = entry.id == selectedEntryID
                            SelectableText(
                                entry.displayTitle,
                                font: .systemFont(ofSize: 14, weight: isSelected ? .semibold : .regular),
                                color: isSelected ? .controlAccentColor : .labelColor,
                                onClick: { selectedEntryID = entry.id }
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                            .background {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(Color.accentColor.opacity(0.13))
                                }
                            }
                            .onTapGesture { selectedEntryID = entry.id }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(entry.displayTitle)
                            .accessibilityAddTraits(.isButton)
                            .accessibilityAction { selectedEntryID = entry.id }
                            .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .frame(minWidth: 205, idealWidth: 255, maxWidth: 340, maxHeight: .infinity)

            Group {
                if let selectedEntry {
                    WordDetailView(entry: selectedEntry, store: store)
                } else if results.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SelectableText("No results", font: .systemFont(ofSize: 25, weight: .semibold))
                        SelectableText("No vocabulary matches “\(searchText.trimmingCharacters(in: .whitespacesAndNewlines))”.", color: .secondaryLabelColor)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(30)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        SelectableText("Choose a word", font: .systemFont(ofSize: 25, weight: .semibold))
                        SelectableText("Select a word from the list to see its meaning and examples.", color: .secondaryLabelColor)
                    }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(30)
                }
            }
            .frame(minWidth: 380, maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear { synchronizeSelection(with: resultIDs) }
        .onChange(of: resultIDs) { _, ids in synchronizeSelection(with: ids) }
    }

    private func synchronizeSelection(with ids: [String]) {
        guard let selectedEntryID, ids.contains(selectedEntryID) else {
            selectedEntryID = ids.first
            return
        }
    }
}
