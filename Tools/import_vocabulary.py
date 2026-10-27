#!/usr/bin/env python3
"""Build vocabulary.json from the editable, reviewed vocabulary_authoring.jsonl.

This tool never invents translations, definitions, or examples. It fails closed
until every selected source entry has a reviewed English meaning, French gloss,
and exactly three authored French examples.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import sys
import unicodedata
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Resources" / "FleLex_TT_Beacco.tsv"
AUTHORING = ROOT / "Resources" / "vocabulary_authoring"
OUTPUT = ROOT / "Resources" / "vocabulary.json"
PROVENANCE = ROOT / "Resources" / "provenance.json"
EXPECTED_SHA256 = "e0cbdb672fa4f83155acec4c8f01f179b30be08cb3d2d6cf0d9f25042b01e3d4"
EXPECTED_COUNT = 1753


def stable_id(lemma: str, pos: str) -> str:
    return f"{unicodedata.normalize('NFC', lemma).lower()}|{pos.upper()}"


def source_groups() -> tuple[str, list[dict[str, Any]], dict[str, list[int]]]:
    raw = SOURCE.read_bytes()
    sha = hashlib.sha256(raw).hexdigest()
    if sha != EXPECTED_SHA256:
        raise ValueError(
            f"Source checksum changed: expected {EXPECTED_SHA256}, got {sha}. "
            "Review the new source and update provenance explicitly before importing."
        )
    with SOURCE.open(encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        required = {"word", "tag", "level"}
        if not reader.fieldnames or not required.issubset(reader.fieldnames):
            raise ValueError(f"TSV header must include {sorted(required)}")
        groups: dict[str, list[dict[str, Any]]] = defaultdict(list)
        for data_row, row in enumerate(reader, start=1):
            if row["level"] != "B1":
                continue
            lemma = unicodedata.normalize("NFC", row["word"])
            pos = row["tag"].upper()
            groups[stable_id(lemma, pos)].append(
                {"id": stable_id(lemma, pos), "lemma": lemma, "pos": pos, "sourceRow": data_row}
            )
    if len(groups) != EXPECTED_COUNT:
        raise ValueError(f"Expected {EXPECTED_COUNT} unique B1 entries, found {len(groups)}")
    source_rows = {key: [item["sourceRow"] for item in group] for key, group in groups.items()}
    representatives = [group[0] for group in groups.values()]
    return sha, representatives, source_rows


def load_authoring(path: Path) -> dict[str, dict[str, Any]]:
    records: dict[str, dict[str, Any]] = {}
    files = sorted(path.glob("*.jsonl")) if path.is_dir() else [path]
    if not files:
        raise ValueError(f"no .jsonl authoring batches found in {path}")
    for batch_path in files:
        with batch_path.open(encoding="utf-8") as handle:
            for line_number, line in enumerate(handle, start=1):
                if not line.strip():
                    continue
                try:
                    record = json.loads(line)
                except json.JSONDecodeError as exc:
                    raise ValueError(f"{batch_path}:{line_number}: invalid JSON: {exc}") from exc
                if not isinstance(record, dict) or not isinstance(record.get("id"), str):
                    raise ValueError(f"{batch_path}:{line_number}: each line must be an object with an id")
                entry_id = record["id"]
                if entry_id in records:
                    raise ValueError(f"{batch_path}:{line_number}: duplicate authoring id {entry_id!r}")
                records[entry_id] = record
    return records


def validate_record(record: dict[str, Any], source: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    entry_id = source["id"]
    if record.get("id") != entry_id:
        errors.append(f"{entry_id}: authoring id must match the normalized source lemma/POS")
    if record.get("status") != "authored":
        errors.append(f"{entry_id}: status must be 'authored' after linguistic review")
    for key in ("english", "french"):
        if not isinstance(record.get(key), str) or not record[key].strip():
            errors.append(f"{entry_id}: {key} must be a non-empty string")
    examples = record.get("examples")
    if not isinstance(examples, list) or len(examples) != 3:
        errors.append(f"{entry_id}: examples must contain exactly three sentences")
    elif any(not isinstance(item, str) or not item.strip() for item in examples):
        errors.append(f"{entry_id}: all three examples must be non-empty strings")
    elif len({" ".join(item.casefold().split()) for item in examples}) != 3:
        errors.append(f"{entry_id}: examples must be distinct")
    elif any(not item.rstrip().rstrip("»”’\"").rstrip().endswith((".", "!", "?", "…")) for item in examples):
        errors.append(f"{entry_id}: each example must be a complete punctuated sentence")
    is_noun = source["pos"] == "NOM"
    source_tag_note = isinstance(record.get("usageNote"), str) and record["usageNote"].startswith("Source tag note:")
    if is_noun:
        if source_tag_note and record.get("gender") is None and record.get("article") is None:
            pass
        else:
            if record.get("gender") not in {"masculine", "feminine"}:
                errors.append(f"{entry_id}: noun gender must be 'masculine' or 'feminine'")
            if not isinstance(record.get("article"), str) or not record["article"].strip():
                errors.append(f"{entry_id}: noun article must be a non-empty string")
    elif record.get("gender") is not None or record.get("article") is not None:
        errors.append(f"{entry_id}: non-nouns must use null gender and article")
    note = record.get("usageNote")
    if note is not None and (not isinstance(note, str) or not note.strip()):
        errors.append(f"{entry_id}: usageNote must be a non-empty string or null")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=AUTHORING, help="reviewed JSONL authoring source")
    parser.add_argument("--output", type=Path, default=OUTPUT, help="generated vocabulary JSON")
    parser.add_argument("--check-only", action="store_true", help="check coverage without writing output")
    args = parser.parse_args()

    try:
        sha, source_entries, source_rows = source_groups()
        authoring = load_authoring(args.source)
    except (OSError, ValueError) as exc:
        print(f"Import stopped: {exc}", file=sys.stderr)
        return 1

    expected_ids = {item["id"] for item in source_entries}
    actual_ids = set(authoring)
    missing = sorted(expected_ids - actual_ids)
    extra = sorted(actual_ids - expected_ids)
    if missing or extra:
        print(
            f"Coverage mismatch: missing {len(missing)} source entries, "
            f"unexpected {len(extra)} authoring entries.", file=sys.stderr
        )
        if missing:
            print("First missing IDs: " + ", ".join(missing[:12]), file=sys.stderr)
        if extra:
            print("Unexpected IDs: " + ", ".join(extra[:12]), file=sys.stderr)
        return 1

    errors: list[str] = []
    entries: list[dict[str, Any]] = []
    for source in source_entries:
        record = authoring[source["id"]]
        errors.extend(validate_record(record, source))
        entries.append({
            "id": source["id"],
            "lemma": source["lemma"],
            "pos": source["pos"],
            "gender": record.get("gender"),
            "article": record.get("article"),
            "english": record.get("english"),
            "french": record.get("french"),
            "examples": record.get("examples"),
            "sourceRow": source["sourceRow"],
            "usageNote": record.get("usageNote"),
        })
    if errors:
        print(f"Authoring validation failed with {len(errors)} issue(s):", file=sys.stderr)
        for error in errors[:30]:
            print(f"- {error}", file=sys.stderr)
        if len(errors) > 30:
            print(f"- … and {len(errors) - 30} more", file=sys.stderr)
        return 1

    payload = {"schemaVersion": 1, "snapshotSHA256": sha, "entries": entries}
    if not args.check_only:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Validated {len(entries)} entries from {args.source}; output {'not written' if args.check_only else args.output}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
