# Frozen shared contract — schema 1

Workspace: /Users/xavier/Codex/2026-10-27/realtime-voice-chat/work/FrenchB1

## Ownership
Foundation: Package.swift, Sources/FrenchB1/Models.swift, CorpusLoader.swift, AppStore.swift, Scheduler.swift, Persistence.swift.
Vocabulary: Resources/FleLex_TT_Beacco.tsv, Resources/vocabulary.json, Resources/provenance.json, vocabulary authoring source, Tools/import_vocabulary.py, Tools/validate_content.py, Documentation/VOCABULARY.md, vocabulary licenses.
Verbs: Resources/verbs.json, morphology data/source/licenses, verb generator/validators, Documentation/VERBS.md.
Dictionary interface: Sources/FrenchB1/SelectableText.swift, DictionaryView.swift, WordDetailView.swift, VerbTableView.swift.
Review/testing: Sources/FrenchB1/ReviewView.swift, Tests/FrenchB1Tests/*, Tools/ui_check* and test documentation.
Integrator: App.swift, build/package scripts, app metadata, README, integration fixes.

Do not overwrite another owner's files; send requested shared changes to integrator.

## Stable ID
`lemma.precomposedStringWithCanonicalMapping.lowercased() + "|" + sourcePOS.uppercased()` (Python unicodedata.normalize('NFC', lemma).lower()). Preserve accents. Source POS verb is VER; noun NOM. IDs are readable and deterministic.

## vocabulary.json
{"schemaVersion":1,"snapshotSHA256":"...","entries":[{"id":"aborder|VER","lemma":"aborder","pos":"VER","gender":null,"article":null,"english":"to approach; to address a subject","french":"Commencer à parler d’un sujet ou s’approcher de quelqu’un.","examples":["...","...","..."],"sourceRow":42,"usageNote":null}]}
Exactly 3 nonempty varied original sentences per entry. gender/article required as applicable to nouns, null otherwise. Source row is 1-based TSV data row (header excluded). Single entry per unique lemma+POS, and provenance retains raw row counts/duplicate mapping.

## verbs.json
{"schemaVersion":1,"verbs":[{"entryID":"aborder|VER","infinitive":"aborder","usageNote":"...","tenses":[{"id":"present","title":"Présent","rows":[{"person":"je","form":"j’aborde","example":"J’aborde ce sujet avec prudence."}]}]}]}
Tense IDs in order: present, passeCompose, imparfait, futurProche, futurSimple, conditionnel, imperatif. Each row exactly one sentence. Normally persons je, tu, il/elle/on, nous, vous, ils/elles; imperative tu, nous, vous. Impersonal/defective omit invalid rows. Forms include subject pronouns except imperative. Gender variants in same row form, one natural example. Context-specific auxiliary and reflexive usage explained in usageNote; infinitive can show relevant pronominal form.

## Swift types (Foundation implements exactly)
VocabularyFile: Codable { schemaVersion:Int, snapshotSHA256:String, entries:[VocabularyEntry] }
VocabularyEntry: Codable, Identifiable, Hashable { id:String, lemma:String, pos:String, gender:String?, article:String?, english:String, french:String, examples:[String], sourceRow:Int, usageNote:String? }; computed `isVerb:Bool`, `displayTitle:String`, `partOfSpeech:String`.
ConjugationFile: Codable { schemaVersion:Int, verbs:[VerbConjugation] }
VerbConjugation: Codable, Hashable { entryID:String, infinitive:String, usageNote:String?, tenses:[TenseTable] }
TenseTable: Codable, Identifiable, Hashable { id:String, title:String, rows:[ConjugationRow] }
ConjugationRow: Codable, Hashable { person:String, form:String, example:String }
ProgressFile: Codable { schemaVersion:Int, records:[String:ProgressRecord] }
ProgressRecord: Codable, Hashable { learnedAt:Date, dueAt:Date, intervalIndex:Int?, lastReviewedAt:Date? }
Progress dates ISO8601. Version 1. Retain orphaned records.

## Shared AppStore (Foundation)
@MainActor final class AppStore: ObservableObject
@Published private(set) var entries:[VocabularyEntry]
@Published private(set) var verbsByEntryID:[String:VerbConjugation]
@Published private(set) var progress:[String:ProgressRecord]
@Published var loadError:String?
@Published var saveError:String?
init(resourceURL:URL?=nil, progressURL:URL?=nil, now:@escaping ()->Date=Date.init, calendar:Calendar=.current)
func search(_ query:String)->[VocabularyEntry] // all entries; French/English folded accents/case
func addToReview(_ id:String)->Bool // idempotent, persist before publish
func grade(_ id:String, remembered:Bool)->Bool // persist before publish
func reviewEntries(all:Bool)->[VocabularyEntry] // due <= now sorted earliest; all includes future
func nextDueDate()->Date?
func refreshDueState() // clock tick/objectWillChange if needed
func isLearned(_ id:String)->Bool
func currentDate()->Date

Scheduler pure `ReviewScheduler` with static intervals=[1,3,7,14,30,60], `initial(now:calendar:)->ProgressRecord` and `graded(_:remembered:now:calendar:)->ProgressRecord`. Again nil/+600 seconds. Remembered nil=>0/+1 calendar day; otherwise min(index+1,5) days. Preserve learnedAt. Local calendar arithmetic.
`ProgressPersistence` allows injected throwing writer for atomic-save-failure tests, keeps old valid file and published state. Public init signatures can be finalized with test owner.
CorpusLoader throws useful diagnostics for malformed JSON/schema/count/IDs/missing fields/example counts/tenses. Default bundle resource root from Bundle.module under SPM. App is built and resources bundled with executable by integrator.

## UI contracts
DictionaryView(store: AppStore, searchText:String)
ReviewView(store: AppStore, searchText:String)
WordDetailView(entry:VocabularyEntry, store:AppStore, showAddButton:Bool=true)
VerbTableView(verb:VerbConjugation)
SelectableText(_ text:String, font:NSFont = .systemFont(ofSize:14), color:NSColor = .labelColor)
App shell with sidebar exactly Learn and Review, toolbar global search belongs integrator. Search must reveal all corpus results even from Review; coordinator routes active search to DictionaryView. Show native read-only selectable NSTextView; preserve standard menus, no custom menu overrides.
