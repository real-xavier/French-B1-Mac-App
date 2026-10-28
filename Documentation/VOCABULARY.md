# Vocabulary corpus

The source lexicon is FLELex / Beacco with TreeTagger parts of speech, downloaded from [the official FLELex download page](https://cental.uclouvain.be/cefrlex/flelex/download/) on 2026-10-27. The original tab-separated file is preserved as `Resources/FleLex_TT_Beacco.tsv`.

FLELex reports lexical frequency distributions and CEFR levels. This app selects rows whose `level` is exactly `B1`; it does not treat source rows as usage examples. The snapshot has 14,236 data rows, of which 1,753 are B1. The B1 set has 1,753 unique lemma/POS IDs and no duplicate IDs. Its POS counts are: NOM 976, VER 395, ADJ 269, ADV 92, PRO 9, PRP 5, KON 3, INT 3, and DET:ART 1. The pinned source SHA-256, citations, data URL, selection rule, duplicate mapping, and each source row are recorded in `Resources/provenance.json`.

IDs use `NFC(lemma).lower() + "|" + POS.upper()`, preserving accents. `sourceRow` is the 1-based TSV data row with the header excluded. Source POS labels are retained even when an entry looks unusual. A meaningful correction or ambiguity belongs in `usageNote`; do not silently replace the source POS or normalize away an entry.

## Authoring and generation

Editable linguistic content is kept in the compact JSONL files under `Resources/vocabulary_authoring/`, split into source-order batches listed in that directory’s README. Each line contains the stable `id`, English meaning, simple French definition, noun gender/article where applicable, exactly three original French examples, an optional usage note, and review status. Example sentences are authored for this app and are not taken from FLELex. The source lemmas, POS tags, and row numbers are inferred by ID during import.

After completing every record, generate the final file with:

```sh
python3 Tools/import_vocabulary.py
python3 Tools/validate_content.py
```

The importer refuses to write `Resources/vocabulary.json` if any source ID is missing, unexpected, duplicated, or still needs authoring, or if required fields fail validation. It never fabricates content to fill a gap. After completing or reviewing batches, run `python3 Tools/refresh_vocabulary_provenance.py` to refresh the ready-entry count and per-batch coverage in `Resources/provenance.json`.

## Attribution and reuse

FLELex / Beacco is attributed to François, Gala, Watrin and Fairon (2014), with the Beacco CEFR-level adaptation by Pintard and François (2020). The source and adapted vocabulary database are licensed CC BY-NC-SA 4.0. The full legal code is in `Resources/licenses/CC-BY-NC-SA-4.0-Legalcode.txt` and the attribution notice is in `Resources/licenses/FLELex-CC-BY-NC-SA-4.0.txt`; the official [license text](https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode.en) is linked there as well.
