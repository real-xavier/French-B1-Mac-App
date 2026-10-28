# Vocabulary authoring batches

Each JSONL row is a compact editable linguistic record. Source metadata is inferred by the importer from `id`; do not repeat or change the lemma, POS, or source row in the authoring file.

| File | Ordinals | Count |
| --- | ---: | ---: |
| `batch-01.jsonl` | 1–350 | 350 |
| `batch-02.jsonl` | 351–700 | 350 |
| `batch-03.jsonl` | 701–1050 | 350 |
| `batch-04.jsonl` | 1051–1400 | 350 |
| `batch-05.jsonl` | 1401–1753 | 353 |

Each line has this exact shape:

```json
{"id":"aborder|VER","english":"to approach; to address a subject","french":"Commencer à parler d’un sujet ou s’approcher de quelqu’un.","gender":null,"article":null,"examples":["J’aborde ce sujet avec prudence.","Elle aborde le problème sous un autre angle.","Nous aborderons la question après la réunion."],"usageNote":null,"status":"authored"}
```

`status` stays `needs_authoring` until the meaning, definition, noun information, usage note, and three original French sentences have been completed and reviewed. Do not copy FLELex examples: FLELex provides frequencies, CEFR levels, lemmas and POS tags, not usage examples. Preserve source POS even when a tag looks unusual; explain material anomalies in `usageNote`.

For `NOM`, set `gender` to `masculine` or `feminine` and `article` to a natural singular article such as `un`, `une`, `le`, or `la`. For other POS, both fields must be `null`. Every completed entry needs a concise English meaning, a simple French definition, exactly three distinct natural French example sentences, and either a useful usage note or `null`.

Run `python3 Tools/import_vocabulary.py --check-only` to check authoring coverage. The importer accepts this directory, checks exact source coverage and required fields, and writes `Resources/vocabulary.json` only when every row has `status: "authored"` and passes validation. It never fills linguistic fields automatically.
