# English translations for French examples

Each `translation_batch-NN.json` file is keyed to the matching vocabulary authoring batch. It contains an English translation for every French definition and all three vocabulary examples. Verb entries also contain English translations aligned to every tense and person row in `Resources/verbs.json`.

`Tools/apply_translations.py` checks exact vocabulary, verb, tense, and row coverage before adding these translations to the bundled `vocabulary.json` and `verbs.json` files. No translation service is used by the app at runtime.

The English text is provided as a study aid. Review idioms and context-sensitive senses when adapting the material.
