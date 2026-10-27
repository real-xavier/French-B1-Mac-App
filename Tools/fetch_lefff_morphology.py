#!/usr/bin/env python3
"""Fetch the pinned Lefff 3.4 source and extract only the B1 verb lemmas."""

from __future__ import annotations

import csv
import hashlib
import json
import urllib.request
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE_TSV = ROOT / "Resources" / "FleLex_TT_Beacco.tsv"
OUTPUT = ROOT / "Resources" / "morphology" / "lefff-3.4-target-forms.tsv"
MANIFEST = ROOT / "Resources" / "morphology" / "manifest.json"
PINNED_URL = (
    "https://raw.githubusercontent.com/ClaudeCoulombe/FrenchLefffLemmatizer/"
    "8d5b095d4fd73499ffbec0e7b78b447a26653aa1/"
    "french_lefff_lemmatizer/data/lefff-3.4.mlex"
)
PINNED_SHA256 = "f3da25e58aec161c5ae34d598038dd6304056c2649867ede7e220a74fd34fe12"
MIRROR_BLOB_SHA = "f7528d68175dd5926eeeca8557773975ba397d4f"
CAPTURE_DATE = "2026-10-27"


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def b1_verbs() -> list[str]:
    with SOURCE_TSV.open(encoding="utf-8", newline="") as handle:
        rows = csv.DictReader(handle, delimiter="\t")
        words = {
            unicodedata.normalize("NFC", row["word"]).lower()
            for row in rows
            if row["level"] == "B1" and row["tag"] == "VER"
        }
    return sorted(words)


def main() -> None:
    request = urllib.request.Request(PINNED_URL, headers={"User-Agent": "FrenchB1-resource-builder/1.0"})
    with urllib.request.urlopen(request, timeout=60) as response:
        source = response.read()
    actual_hash = digest(source)
    if actual_hash != PINNED_SHA256:
        raise SystemExit(f"Pinned Lefff SHA-256 mismatch: expected {PINNED_SHA256}, got {actual_hash}")

    targets = set(b1_verbs()) | {"aller", "avoir", "être"}
    selected: list[str] = []
    seen: set[str] = set()
    found: set[str] = set()
    for raw in source.decode("utf-8").splitlines():
        columns = raw.split("\t")
        if len(columns) >= 4 and columns[1] == "v" and columns[2] in targets:
            found.add(columns[2])
            if raw not in seen:
                selected.append(raw)
                seen.add(raw)
    if found != targets - {"hier"}:
        raise SystemExit(f"Unexpected source lemma coverage; missing={sorted(targets - found)}")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    subset = ("\n".join(selected) + "\n").encode("utf-8")
    OUTPUT.write_bytes(subset)
    manifest = {
        "schemaVersion": 1,
        "capturedAt": CAPTURE_DATE,
        "resource": "Lefff 3.4 extensional morphology (.mlex), target-form extract",
        "officialMaintainerPage": "https://pauillac.inria.fr/~sagot/",
        "officialDownloadLink": "https://gforge.inria.fr/frs/download.php/file/34601/lefff-3.4.mlex.tgz",
        "officialDownloadStatus": "403 at capture; pinned file retrieved from mirror",
        "mirrorURL": PINNED_URL,
        "mirrorCommit": "8d5b095d4fd73499ffbec0e7b78b447a26653aa1",
        "mirrorBlobSHA1": MIRROR_BLOB_SHA,
        "sourceSHA256": actual_hash,
        "selectedPOS": "v",
        "selectedLemmaCount": len(targets),
        "selectedLemmaListSource": "Resources/FleLex_TT_Beacco.tsv rows with level=B1 and tag=VER plus aller/avoir/être",
        "selectionRule": "Keep Lefff v entries for selected lemmas; remove byte-identical repeated rows, preserving upstream row order. The B1 technical verb hier has no Lefff v entry and is authored in verb_morphology_overrides.json.",
        "outputFile": OUTPUT.relative_to(ROOT).as_posix(),
        "outputLineCount": len(selected),
        "outputSHA256": digest(subset),
        "license": "LGPL-LR (as identified for Lefff 3.4 on the maintainer page)",
        "licenseURL": "https://www.labri.fr/perso/clement/lefff/licence-LGPLLR.html",
    }
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(selected)} unique source rows ({len(subset)} bytes) to {OUTPUT}")
    print(f"Source SHA-256: {actual_hash}")
    print(f"Extract SHA-256: {digest(subset)}")


if __name__ == "__main__":
    main()
