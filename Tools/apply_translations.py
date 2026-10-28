#!/usr/bin/env python3
"""Apply reviewed offline English translations to the generated corpus files."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
TRANSLATIONS = ROOT / "Resources" / "example_translations"
VOCABULARY = ROOT / "Resources" / "vocabulary.json"
VERBS = ROOT / "Resources" / "verbs.json"


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def require_text(value: Any, location: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"Missing English translation at {location}")
    return value.strip()


def main() -> int:
    try:
        batches = sorted(TRANSLATIONS.glob("translation_batch-*.json"))
        if len(batches) != 5:
            raise ValueError(f"Expected 5 translation batch files, found {len(batches)}")
        vocabulary_translations: dict[str, Any] = {}
        verb_translations: dict[str, Any] = {}
        for path in batches:
            payload = load(path)
            for entry_id, translation in payload.get("vocabulary", {}).items():
                if entry_id in vocabulary_translations:
                    raise ValueError(f"Duplicate vocabulary translation: {entry_id}")
                vocabulary_translations[entry_id] = translation
            for entry_id, translation in payload.get("verbs", {}).items():
                if entry_id in verb_translations:
                    raise ValueError(f"Duplicate verb translation: {entry_id}")
                verb_translations[entry_id] = translation

        vocabulary = load(VOCABULARY)
        expected_vocabulary_ids = {entry["id"] for entry in vocabulary["entries"]}
        if set(vocabulary_translations) != expected_vocabulary_ids:
            missing = sorted(expected_vocabulary_ids - set(vocabulary_translations))
            extra = sorted(set(vocabulary_translations) - expected_vocabulary_ids)
            raise ValueError(f"Vocabulary translation coverage mismatch: {len(missing)} missing, {len(extra)} extra; first missing={missing[:5]}, extra={extra[:5]}")
        for entry in vocabulary["entries"]:
            translated = vocabulary_translations[entry["id"]]
            entry["frenchTranslation"] = require_text(translated.get("definition"), f"{entry['id']}.definition")
            examples = translated.get("examples")
            if not isinstance(examples, list) or len(examples) != len(entry["examples"]):
                raise ValueError(f"Expected {len(entry['examples'])} example translations for {entry['id']}")
            entry["exampleTranslations"] = [
                require_text(value, f"{entry['id']}.examples[{index}]")
                for index, value in enumerate(examples)
            ]

        verbs = load(VERBS)
        expected_verb_ids = {verb["entryID"] for verb in verbs["verbs"]}
        if set(verb_translations) != expected_verb_ids:
            missing = sorted(expected_verb_ids - set(verb_translations))
            extra = sorted(set(verb_translations) - expected_verb_ids)
            raise ValueError(f"Verb translation coverage mismatch: {len(missing)} missing, {len(extra)} extra; first missing={missing[:5]}, extra={extra[:5]}")
        translated_rows = 0
        for verb in verbs["verbs"]:
            by_tense = verb_translations[verb["entryID"]]
            expected_tenses = {tense["id"] for tense in verb["tenses"]}
            if set(by_tense) != expected_tenses:
                raise ValueError(f"Tense translation coverage mismatch for {verb['entryID']}")
            for tense in verb["tenses"]:
                translations = by_tense[tense["id"]]
                if not isinstance(translations, list) or len(translations) != len(tense["rows"]):
                    raise ValueError(f"Conjugation example count mismatch for {verb['entryID']}.{tense['id']}")
                for index, row in enumerate(tense["rows"]):
                    row["exampleTranslation"] = require_text(
                        translations[index], f"{verb['entryID']}.{tense['id']}[{index}]"
                    )
                    translated_rows += 1

        VOCABULARY.write_text(json.dumps(vocabulary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        VERBS.write_text(json.dumps(verbs, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
        print(f"Translation import stopped: {exc}", file=sys.stderr)
        return 1
    print(f"Applied translations for {len(vocabulary['entries'])} vocabulary entries, {sum(len(e['examples']) for e in vocabulary['entries'])} general examples, and {translated_rows} verb examples.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
