# Verification

## Unit tests

Run the Foundation and review tests from the package root:

```sh
CLANG_MODULE_CACHE_PATH=/private/tmp/FrenchB1-ClangModuleCache \
SWIFTPM_MODULECACHE_OVERRIDE=/private/tmp/FrenchB1-SwiftModuleCache \
swift test --cache-path /private/tmp/FrenchB1-SwiftCache --scratch-path .build --disable-sandbox
```

Tests make small, valid corpus fixtures in temporary folders. They do not use or modify the shipped vocabulary corpus or the user's review file. The suite covers local-calendar scheduling across Toronto daylight-saving changes, progress persistence and save failures, corpus validation, accent-insensitive global search, and due-card ordering.

## Packaged app smoke check

Use the packaged app after vocabulary and conjugation resources are present. The app's review progress is stored separately from the packaged corpus.

1. Open **Learn**, search with a mixed-case, accent-free query such as `cafe`, and confirm that `café` appears. Open it and check its bilingual definitions, examples, and add-to-review action.
2. Search for a verb and check that its conjugation tables open. Select a word or example and confirm the standard macOS text selection and Look Up/Copy menu remain available.
3. Open **Review** with no cards. Confirm that the empty state offers **Learn a word** and returns to Learn.
4. Add a word to review, then choose **All learned**. Confirm that the French prompt appears without its English meaning. Before revealing, there must be no grading buttons. Choose **Show answer** and confirm the English and French meanings, all three examples, and verb tables where applicable appear.
5. Choose **Again** and confirm that the card is scheduled ten minutes later and the next card appears. In **Due now**, confirm only cards with due times at or before the current time are shown. **All learned** should include future cards in earliest-due order.
6. Choose **Remembered** on another revealed card and confirm the next card appears. Quit and reopen the app to verify the progress survives restart.

For screenshot capture, save the Learn/dictionary, verb, and Review app views under `/Users/xavier/Codex/2026-10-27/realtime-voice-chat/outputs/Screenshots/`.
