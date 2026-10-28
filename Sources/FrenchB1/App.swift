import SwiftUI
import AppKit

@main
struct FrenchB1App: App {
    @StateObject private var store = AppStore(progressURL: Self.launchProgressURL)
    @State private var section: StudySection? = .learn
    @State private var searchText = ""

    // UI verification can use an isolated local progress file without touching personal progress.
    private static var launchProgressURL: URL? {
        guard let path = ProcessInfo.processInfo.environment["FRENCHB1_PROGRESS_PATH"], !path.isEmpty else { return nil }
        return URL(fileURLWithPath: path)
    }

    var body: some Scene {
        WindowGroup("French B1") {
            NavigationSplitView {
                List(selection: $section) {
                    Label("Learn", systemImage: "book.closed")
                        .tag(StudySection.learn)
                    Label("Review", systemImage: "rectangle.on.rectangle")
                        .tag(StudySection.review)
                }
                .listStyle(.sidebar)
                .navigationTitle("French B1")
                .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 240)
            } detail: {
                Group {
                    if let error = store.loadError {
                        ContentUnavailableView {
                            Label("The dictionary could not open", systemImage: "exclamationmark.triangle")
                        } description: {
                            Text(error).textSelection(.enabled)
                        }
                    } else if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || section != .review {
                        DictionaryView(store: store, searchText: searchText)
                    } else {
                        ReviewView(store: store, searchText: searchText, onLearn: { section = .learn })
                    }
                }
                .frame(minWidth: 640, minHeight: 540)
            }
            .searchable(text: $searchText, placement: .toolbar, prompt: "Search French or English")
            .frame(minWidth: 880, minHeight: 600)
            .onChange(of: section) { _, _ in searchText = "" }
            .alert("Progress could not be saved", isPresented: Binding(
                get: { store.saveError != nil },
                set: { if !$0 { store.saveError = nil } }
            )) {
                Button("OK", role: .cancel) { store.saveError = nil }
            } message: {
                Text(store.saveError ?? "Please try again.")
            }
        }
        .defaultSize(width: 1120, height: 760)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About French B1") {
                    NSApplication.shared.orderFrontStandardAboutPanel(options: [
                        .applicationName: "French B1",
                        .applicationVersion: "1.0",
                        .credits: NSAttributedString(string: "Offline vocabulary practice using the B1-classified entries in the pinned FLELex/Beacco snapshot.\nPersonal, noncommercial use. Source and license notices are bundled with this app.")
                    ])
                }
                Button("Source and License Notices") { showNotices() }
            }
        }
    }

    private func showNotices() {
        let candidates = [Bundle.main.resourceURL?.appendingPathComponent("Notices"), Bundle.main.resourceURL]
        if let url = candidates.compactMap({$0}).first(where: { FileManager.default.fileExists(atPath: $0.path) }) {
            NSWorkspace.shared.open(url)
        }
    }
}

enum StudySection: String, Hashable {
    case learn, review
}
