#!/usr/bin/env python3
"""Refresh authoring progress in provenance.json from the editable batch files."""
from __future__ import annotations

import json
from datetime import date
from pathlib import Path

from import_vocabulary import AUTHORING, PROVENANCE, load_authoring, source_groups, validate_record


def main() -> int:
    _, source_entries, _ = source_groups()
    source_by_id = {entry["id"]: entry for entry in source_entries}
    authoring = load_authoring(AUTHORING)
    expected_ids = set(source_by_id)
    actual_ids = set(authoring)
    ready: set[str] = set()
    for entry_id in expected_ids & actual_ids:
        if not validate_record(authoring[entry_id], source_by_id[entry_id]):
            ready.add(entry_id)

    batch_counts = []
    for batch_path in sorted(AUTHORING.glob("*.jsonl")):
        batch_records = []
        with batch_path.open(encoding="utf-8") as handle:
            batch_records = [json.loads(line) for line in handle if line.strip()]
        batch_ids = [record.get("id") for record in batch_records if isinstance(record, dict)]
        batch_counts.append({
            "file": str(batch_path.relative_to(PROVENANCE.parent.parent)),
            "entries": len(batch_records),
            "authoredStatus": sum(record.get("status") == "authored" for record in batch_records),
            "ready": sum(entry_id in ready for entry_id in batch_ids),
        })

    payload = json.loads(PROVENANCE.read_text(encoding="utf-8"))
    payload["authoringStatus"] = {
        "completedEntries": len(ready),
        "requiredEntries": len(expected_ids),
        "unreviewedEntries": len(expected_ids - ready),
        "unexpectedAuthoringIDs": len(actual_ids - expected_ids),
        "refreshedAt": date.today().isoformat(),
        "batchCounts": batch_counts,
        "note": "Completed means the row has authored, non-empty meanings and definition, three distinct punctuated examples, valid noun metadata (or an explicit source-tag note), and status authored. This count does not certify linguistic quality; entries still require human review.",
    }
    PROVENANCE.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Updated authoring progress: {len(ready)}/{len(expected_ids)} complete.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
