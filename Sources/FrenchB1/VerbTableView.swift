import AppKit
import SwiftUI

public struct VerbTableView: View {
    public let verb: VerbConjugation
    @State private var selectedTenseID = "present"

    public init(verb: VerbConjugation) {
        self.verb = verb
    }

    private var selectedTense: TenseTable? {
        verb.tenses.first { $0.id == selectedTenseID } ?? verb.tenses.first
    }

    private var tenseSelection: Binding<String> {
        Binding(
            get: { selectedTense?.id ?? "" },
            set: { selectedTenseID = $0 }
        )
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            SelectableText("Conjugation · \(verb.infinitive)", font: .systemFont(ofSize: 18, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            if verb.tenses.isEmpty {
                SelectableText("No conjugation tables are available for this verb.", color: .secondaryLabelColor)
            } else {
                Picker("Tense", selection: tenseSelection) {
                    ForEach(verb.tenses) { tense in
                        Text(tense.title).tag(tense.id)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .accessibilityLabel("Verb tense")

                if let selectedTense {
                    SelectableText(selectedTense.title, font: .systemFont(ofSize: 14, weight: .semibold), color: .secondaryLabelColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if selectedTense.rows.isEmpty {
                        SelectableText(
                            "No standard forms are shown for this tense because this verb is defective or impersonal.",
                            font: .systemFont(ofSize: 14),
                            color: .secondaryLabelColor
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(selectedTense.rows.enumerated()), id: \.offset) { index, row in
                                HStack(alignment: .top, spacing: 18) {
                                    SelectableText(
                                        formLabel(row, tense: selectedTense),
                                        font: .systemFont(ofSize: 14, weight: .semibold)
                                    )
                                    .frame(width: 150, alignment: .leading)

                                    SelectableText(row.example, font: .systemFont(ofSize: 14))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, 10)

                                if index < selectedTense.rows.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: verb.tenses.map(\.id)) { _, ids in
            if !ids.contains(selectedTenseID) {
                selectedTenseID = ids.first ?? ""
            }
        }
    }

    private func formLabel(_ row: ConjugationRow, tense: TenseTable) -> String {
        let form = row.form.trimmingCharacters(in: .whitespacesAndNewlines)
        let person = row.person.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !person.isEmpty else { return form }

        if tense.id == "imperatif" {
            return "\(person) · \(form)"
        }
        return form
    }
}
