# French B1

A native macOS vocabulary app for personal, noncommercial study. It works offline from its first launch and stores review progress locally. No account, API key, content downloads, or AI runtime are used.

## Study

Open **French B1.app**. Use **Learn** to browse the dictionary or search French and English without worrying about case or accents. Click a word to see its English meaning, a simple French definition followed by a smaller gray English translation, and three French examples each followed by a smaller gray English translation. **Add to review** schedules the word for tomorrow. Verb entries also show seven tense/mood tables; every conjugated form's French example is followed by its English translation.

In **Review**, **Due now** shows cards whose due time has arrived, earliest first. **All learned** includes future cards. **Show answer** reveals the meanings and examples. Then choose **Again** to retry in ten minutes, or **Remembered** to advance through 3, 7, 14, 30, and 60 calendar-day intervals. Later successes stay at 60 days. A success after Again starts again at one calendar day. Words remain available in both sections.

Select text in meanings, examples, headings, and forms to use native macOS Copy, Look Up, and other text services offered by your system. External web services in those menus need internet; studying does not.

## Coverage

The app includes every entry classified exactly B1 in the pinned **FLELex/Beacco TreeTagger snapshot**: **1,753 unique lemma/POS entries**, including **395 verbs**. This source-based selection is not a claim to universal or official CEFR completeness. FLELex supplies lemmas, POS labels, frequency data, and levels. The English meanings, French explanations, examples, and verb-use choices were added for this app. Unusual source tags and rare senses are explained in usage notes rather than silently dropped.

Verbs have seven tables: présent, passé composé, imparfait, futur proche, futur simple, conditionnel présent, and impératif présent. Defective or impersonal verbs show only valid forms. Gender alternatives share one row; its example uses one concrete form. Verb-specific sentence frames may recur across persons and tenses so the form change remains easy to compare.

## Local files

Ordinary progress lives at `~/Library/Application Support/FrenchB1/progress.json`. It is versioned and saved atomically. Existing records, including entries absent from a future dictionary version, are retained. A malformed progress file is preserved and writes are blocked with a diagnostic rather than replacing it silently.

The app bundles materialized content, notices, full license texts, the pinned source selection, and editable linguistic resources. The accompanying source archive includes Swift sources, authoring batches, deterministic morphology generators, and meaningful tests. See `Documentation/VERBS.md` for source licensing and rare-word notes.

## Build and check

Requirements: macOS 14 or later, Apple silicon, Xcode/Swift 5.9 or later, and Python 3 for rebuilding the editable data. The runnable app itself needs only macOS.

```sh
python3 Tools/import_vocabulary.py
python3 Tools/refresh_vocabulary_provenance.py
python3 Tools/validate_content.py
python3 Tools/build_verbs.py
python3 Tools/apply_translations.py
python3 Tools/validate_verbs.py
CLANG_MODULE_CACHE_PATH=/private/tmp/FrenchB1-ClangModuleCache \
SWIFTPM_MODULECACHE_OVERRIDE=/private/tmp/FrenchB1-SwiftModuleCache \
swift test --cache-path /private/tmp/FrenchB1-SwiftCache --scratch-path .build --disable-sandbox
Tools/build_app.sh
```

`Tools/build_app.sh` checks complete content before creating an ad-hoc signed local `.app`. It currently writes to the approved output folder recorded in that script. A packaged app resolves its study content explicitly within its own bundle, without using SwiftPM development paths. `FRENCHB1_PROGRESS_PATH` can point to an isolated local JSON file for UI verification; normal launches use Application Support.

English definition and example translations are bundled with the corpus, so they display without an internet connection.

## Attribution

FLELex / Beacco: François, Gala, Watrin and Fairon (2014); Pintard and François (2020), **CC BY-NC-SA 4.0**. Lefff 3.4: Benoît Sagot and contributors (2010), **LGPL-LR** for the pinned morphology snapshot. Full notices, license texts, source hashes, retrieval locations, modifications, and a source-page license discrepancy are preserved under `Resources/licenses` and `Resources/morphology`.

The application source is provided for personal use and modification. The linguistic resources retain their respective licenses. This app has not been notarized for public distribution.
