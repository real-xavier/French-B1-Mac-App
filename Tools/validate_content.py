#!/usr/bin/env python3
"""Validate the final vocabulary corpus against the frozen FLELex snapshot."""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
import unicodedata
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Resources" / "FleLex_TT_Beacco.tsv"
VOCABULARY = ROOT / "Resources" / "vocabulary.json"
EXPECTED_SHA256 = "e0cbdb672fa4f83155acec4c8f01f179b30be08cb3d2d6cf0d9f25042b01e3d4"
EXPECTED_COUNT = 1753


def stable_id(lemma: str, pos: str) -> str:
    return f"{unicodedata.normalize('NFC', lemma).lower()}|{pos.upper()}"


def expected_entries() -> tuple[str, dict[str, dict[str, Any]], dict[str, list[int]]]:
    raw = SOURCE.read_bytes()
    sha = hashlib.sha256(raw).hexdigest()
    if sha != EXPECTED_SHA256:
        raise ValueError(f"source checksum mismatch: {sha}")
    import csv
    with SOURCE.open(encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        rows: dict[str, list[dict[str, Any]]] = defaultdict(list)
        for data_row, row in enumerate(reader, start=1):
            if row["level"] == "B1":
                lemma = unicodedata.normalize("NFC", row["word"])
                pos = row["tag"].upper()
                entry_id = stable_id(lemma, pos)
                rows[entry_id].append({"id": entry_id, "lemma": lemma, "pos": pos, "sourceRow": data_row})
    if len(rows) != EXPECTED_COUNT:
        raise ValueError(f"expected {EXPECTED_COUNT} B1 IDs, found {len(rows)}")
    return sha, {key: group[0] for key, group in rows.items()}, {key: [row["sourceRow"] for row in group] for key, group in rows.items()}


def validate_entry(entry: Any, source: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if not isinstance(entry, dict):
        return [f"{source['id']}: entry must be an object"]
    entry_id = source["id"]
    for key in ("id", "lemma", "pos", "sourceRow"):
        if entry.get(key) != source[key]:
            errors.append(f"{entry_id}: {key} mismatch; expected {source[key]!r}, found {entry.get(key)!r}")
    for key in ("english", "french"):
        if not isinstance(entry.get(key), str) or not entry[key].strip():
            errors.append(f"{entry_id}: {key} must be non-empty")
    examples = entry.get("examples")
    if not isinstance(examples, list) or len(examples) != 3:
        errors.append(f"{entry_id}: must have exactly 3 examples")
    else:
        cleaned: list[str] = []
        for index, example in enumerate(examples, start=1):
            if not isinstance(example, str) or not example.strip():
                errors.append(f"{entry_id}: example {index} must be non-empty")
                continue
            normalized = " ".join(example.casefold().split())
            cleaned.append(normalized)
            if not example.rstrip().rstrip("»”’\"").rstrip().endswith((".", "!", "?", "…")):
                errors.append(f"{entry_id}: example {index} must be a complete punctuated sentence")
            if "[" in example or "]" in example or "TODO" in example or "NEEDS_AUTHORING" in example:
                errors.append(f"{entry_id}: example {index} contains an authoring placeholder")
        if len(set(cleaned)) != len(cleaned):
            errors.append(f"{entry_id}: examples are not distinct")
    source_tag_note = isinstance(entry.get("usageNote"), str) and entry["usageNote"].startswith("Source tag note:")
    if source["pos"] == "NOM":
        if source_tag_note and entry.get("gender") is None and entry.get("article") is None:
            pass
        else:
            if entry.get("gender") not in {"masculine", "feminine"}:
                errors.append(f"{entry_id}: noun gender must be masculine or feminine")
            if not isinstance(entry.get("article"), str) or not entry["article"].strip():
                errors.append(f"{entry_id}: noun article must be non-empty")
    elif entry.get("gender") is not None or entry.get("article") is not None:
        errors.append(f"{entry_id}: non-nouns must have null gender and article")
    note = entry.get("usageNote")
    if note is not None and (not isinstance(note, str) or not note.strip()):
        errors.append(f"{entry_id}: usageNote must be null or a non-empty string")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", type=Path, nargs="?", default=VOCABULARY)
    args = parser.parse_args()
    try:
        sha, expected, source_rows = expected_entries()
        payload = json.loads(args.path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(f"Validation stopped: {exc}", file=sys.stderr)
        return 1

    errors: list[str] = []
    if not isinstance(payload, dict):
        errors.append("root must be a JSON object")
        payload = {}
    if payload.get("schemaVersion") != 1:
        errors.append("schemaVersion must be 1")
    if payload.get("snapshotSHA256") != sha:
        errors.append(f"snapshotSHA256 must equal {sha}")
    entries = payload.get("entries")
    if not isinstance(entries, list):
        errors.append("entries must be an array")
        entries = []
    actual: dict[str, Any] = {}
    for index, entry in enumerate(entries):
        if not isinstance(entry, dict) or not isinstance(entry.get("id"), str):
            errors.append(f"entries[{index}] must be an object with a string id")
            continue
        entry_id = entry["id"]
        if entry_id in actual:
            errors.append(f"duplicate id {entry_id}")
        else:
            actual[entry_id] = entry
    expected_ids = set(expected)
    actual_ids = set(actual)
    for missing in sorted(expected_ids - actual_ids):
        errors.append(f"missing source entry {missing}")
    for extra in sorted(actual_ids - expected_ids):
        errors.append(f"unexpected id {extra}")
    for entry_id in sorted(expected_ids & actual_ids):
        errors.extend(validate_entry(actual[entry_id], expected[entry_id]))
        if source_rows[entry_id] and actual[entry_id].get("sourceRow") != source_rows[entry_id][0]:
            errors.append(f"{entry_id}: sourceRow must be first matching source row")

    if errors:
        print(f"Vocabulary validation failed with {len(errors)} issue(s):", file=sys.stderr)
        for error in errors[:50]:
            print(f"- {error}", file=sys.stderr)
        if len(errors) > 50:
            print(f"- … and {len(errors) - 50} more", file=sys.stderr)
        return 1
    print(f"Vocabulary valid: {len(actual)} unique B1 entries; SHA-256 {sha}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
