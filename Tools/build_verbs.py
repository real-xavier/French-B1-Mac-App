#!/usr/bin/env python3
"""Build materialized verb tables from pinned Lefff 3.4 forms and reviewed frames."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import unicodedata
from collections import defaultdict
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
SOURCE_FORMS = ROOT / "Resources" / "morphology" / "lefff-3.4-target-forms.tsv"
OVERRIDES = ROOT / "Resources" / "morphology" / "verb_morphology_overrides.json"
METADATA = ROOT / "Resources" / "verb_metadata.json"
OUTPUT = ROOT / "Resources" / "verbs.json"

TENSES = [
    ("present", "Présent"),
    ("passeCompose", "Passé composé"),
    ("imparfait", "Imparfait"),
    ("futurProche", "Futur proche"),
    ("futurSimple", "Futur simple"),
    ("conditionnel", "Conditionnel présent"),
    ("imperatif", "Impératif"),
]
PERSON_ORDER = ["je", "tu", "il/elle/on", "nous", "vous", "ils/elles"]
SIMPLE_TAGS = {
    "present": ["P1s", "P2s", "P3s", "P1p", "P2p", "P3p"],
    "imparfait": ["I12s", "I3s", "I1p", "I2p", "I3p"],
    "futurSimple": ["F1s", "F2s", "F3s", "F1p", "F2p", "F3p"],
    "conditionnel": ["C12s", "C3s", "C1p", "C2p", "C3p"],
    "imperatif": ["Y2s", "Y1p", "Y2p"],
}
TAG_FOR_PERSON = {
    "present": {**dict(zip(PERSON_ORDER, SIMPLE_TAGS["present"])), "il": "P3s"},
    "imparfait": {"je": "I1s", "tu": "I2s", "il/elle/on": "I3s", "il": "I3s", "nous": "I1p", "vous": "I2p", "ils/elles": "I3p"},
    "futurSimple": {**dict(zip(PERSON_ORDER, SIMPLE_TAGS["futurSimple"])), "il": "F3s"},
    "conditionnel": {"je": "C1s", "tu": "C2s", "il/elle/on": "C3s", "il": "C3s", "nous": "C1p", "vous": "C2p", "ils/elles": "C3p"},
    "imperatif": {"tu": "Y2s", "nous": "Y1p", "vous": "Y2p"},
}
ALL_PERSONS = set(PERSON_ORDER)
IMPERATIVE_PERSONS = {"tu", "nous", "vous"}
VALID_GROUPS = {"present": ALL_PERSONS, "passeCompose": ALL_PERSONS, "imparfait": ALL_PERSONS,
                "futurProche": ALL_PERSONS, "futurSimple": ALL_PERSONS,
                "conditionnel": ALL_PERSONS, "imperatif": IMPERATIVE_PERSONS}
SUBJECT_DISPLAY = {
    "je": "je", "tu": "tu", "il/elle/on": "il/elle/on", "il": "il", "nous": "nous", "vous": "vous", "ils/elles": "ils/elles"
}
EXAMPLE_SUBJECT = {"je": "je", "tu": "tu", "il/elle/on": "elle", "il": "il", "nous": "nous", "vous": "vous", "ils/elles": "elles"}
JE_ELIDED_H = {"habiter", "habituer", "héberger", "hésiter", "honorer"}
REFLEXIVE_CLITICS = {
    "je": ("me", "m’"), "tu": ("te", "t’"), "il/elle/on": ("se", "s’"),
    "nous": ("nous", "nous"), "vous": ("vous", "vous"), "ils/elles": ("se", "s’"),
}
SOURCE_TAG_RE = re.compile(r"([A-Z]+)([123]+)([sp])")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def stable_id(lemma: str) -> str:
    return unicodedata.normalize("NFC", lemma).lower() + "|VER"


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def read_morphology() -> tuple[dict[str, dict[str, set[str]]], dict[str, dict[str, str]]]:
    forms: dict[str, dict[str, set[str]]] = defaultdict(lambda: defaultdict(set))
    for line_no, raw in enumerate(SOURCE_FORMS.read_text(encoding="utf-8").splitlines(), start=1):
        if not raw or raw.startswith("#"):
            continue
        columns = raw.split("\t")
        if len(columns) != 4 or columns[1] != "v":
            raise ValueError(f"Unexpected Lefff record at {SOURCE_FORMS}:{line_no}: {raw!r}")
        form, _pos, lemma, tag = columns
        forms[lemma][tag].add(form)
    overrides = load_json(OVERRIDES).get("forms", {})
    if not isinstance(overrides, dict):
        raise ValueError("Morphology override file needs a `forms` object")
    for lemma, tagged_forms in overrides.items():
        if not isinstance(tagged_forms, dict):
            raise ValueError(f"Morphology overrides for {lemma} must be an object")
        for tag, form in tagged_forms.items():
            if not isinstance(form, str) or not form:
                raise ValueError(f"Invalid morphology override {lemma}.{tag}")
            forms[lemma][tag].add(form)
    preferred = load_json(OVERRIDES).get("preferredForms", {})
    if not isinstance(preferred, dict):
        raise ValueError("Morphology override file needs a `preferredForms` object")
    return forms, preferred


def tagged_persons(tag: str) -> list[tuple[str, str]]:
    """Expand Lefff tags such as PS13s or PJ12s into the supported tense codes."""
    match = SOURCE_TAG_RE.fullmatch(tag)
    if not match:
        return []
    marker_group, digits, number = match.groups()
    out: list[tuple[str, str]] = []
    for marker in marker_group:
        if marker not in {"P", "I", "F", "C", "Y"}:
            continue
        for digit in digits:
            out.append((marker + digit + number, marker))
    return out


def resolved_forms(raw: dict[str, set[str]], preferred: dict[str, str] | None = None) -> dict[str, str]:
    """Build requested person/tense forms, resolving only explicitly reviewed variants."""
    candidates: dict[str, set[str]] = defaultdict(set)
    for tag, values in raw.items():
        if tag.startswith("K"):
            candidates[tag].update(values)
        for target_code, _marker in tagged_persons(tag):
            candidates[target_code].update(values)
    result: dict[str, str] = {}
    for code, values in candidates.items():
        if len(values) == 1:
            result[code] = next(iter(values))
        elif preferred and code in preferred and preferred[code] in values:
            result[code] = preferred[code]
        else:
            raise ValueError(f"Ambiguous Lefff forms for target `{code}`: {sorted(values)}; add preferredForms")
    return result


def has_vowel_or_mute_h(word: str, lemma: str) -> bool:
    lower = word.lower()
    if lower.startswith("h"):
        return lemma in JE_ELIDED_H
    return lower[:1] in "aeiouyàâäéèêëîïôöùûüÿœæ"


def pronoun_form(person: str, verb: str, lemma: str, metadata: dict[str, Any], *, example: bool = False) -> str:
    if example:
        p = metadata.get("exampleSubjectOverrides", {}).get(person, EXAMPLE_SUBJECT[person])
    else:
        p = SUBJECT_DISPLAY[person]
    if person == "je" and has_vowel_or_mute_h(verb, lemma):
        return "j’"
    return p + " "


def selected(form_map: dict[str, str], tag: str, lemma: str, tense: str, metadata: dict[str, Any]) -> str | None:
    if tag in form_map:
        return form_map[tag]
    # Preserve ordinary Lefff morphology; hand overrides may use a direct person code.
    override_codes = metadata.get("manualForms", {})
    return override_codes.get(tense, {}).get(tag)


def conjugated_base(form_map: dict[str, str], tense: str, person: str, lemma: str, metadata: dict[str, Any]) -> str | None:
    code = TAG_FOR_PERSON[tense].get(person)
    if not code:
        return None
    return selected(form_map, code, lemma, tense, metadata)


def clitic(person: str, following_form: str, lemma: str) -> str:
    normal, elided = REFLEXIVE_CLITICS[person]
    return elided if has_vowel_or_mute_h(following_form, lemma) else normal


def clitic_plus_form(person: str, following_form: str, lemma: str) -> str:
    before = clitic(person, following_form, lemma)
    if before.endswith("’"):
        return before + following_form
    return before + " " + following_form


def inflected_clause(form_map: dict[str, str], tense: str, person: str, metadata: dict[str, Any], *, example: bool = False,
                     example_gender: str = "f", auxiliaries: dict[str, dict[str, str]] | None = None) -> str | None:
    lemma = metadata["lemma"]
    infinitive = metadata["infinitive"]
    ref = metadata["reflexive"] == "required"
    person_label = EXAMPLE_SUBJECT[person] if example else SUBJECT_DISPLAY[person]
    if tense in SIMPLE_TAGS:
        base = conjugated_base(form_map, tense, person, lemma, metadata)
        if base is None:
            return None
        if tense == "imperatif":
            if ref:
                post = {"tu": "toi", "nous": "nous", "vous": "vous"}[person]
                # Affirmative imperatives place the reflexive pronoun after the verb.
                return f"{base}-{post}"
            return base
        subject = pronoun_form(person, base, lemma, metadata, example=example)
        if ref:
            # Simple tenses place the reflexive clitic immediately before the finite verb.
            before = clitic(person, base, lemma)
            subject = (EXAMPLE_SUBJECT[person] if example else SUBJECT_DISPLAY[person]) + " "
            return subject + clitic_plus_form(person, base, lemma)
        if subject.endswith("’"):
            return subject + base
        return subject + base

    if tense == "futurProche":
        aux_forms = (auxiliaries or {}).get("aller", {})
        aller = conjugated_base(aux_forms, "present", person, "aller", metadata)
        if aller is None:
            return None
        subject = pronoun_form(person, aller, lemma, metadata, example=example)
        if ref:
            inf = (infinitive[2:] if infinitive.startswith(("s’", "s'", "se")) else infinitive).strip()
            subject = (EXAMPLE_SUBJECT[person] if example else SUBJECT_DISPLAY[person]) + " "
            return f"{subject}{aller} {clitic_plus_form(person, inf, lemma)}"
        return f"{subject}{aller} {infinitive}"

    if tense == "passeCompose":
        aux = "être" if ref else metadata["auxiliary"]
        aux_forms = (auxiliaries or {}).get(aux, {})
        aux_form = conjugated_base(aux_forms, "present", person, aux, metadata)
        if aux_form is None:
            return None
        pp = past_participle(form_map, metadata, person, example=example, example_gender=example_gender)
        if pp is None:
            return None
        subject = pronoun_form(person, aux_form, lemma, metadata, example=example)
        if ref:
            before = clitic(person, aux_form, lemma)
            subject = (EXAMPLE_SUBJECT[person] if example else SUBJECT_DISPLAY[person]) + " "
            if before.endswith("’"):
                return f"{subject}{before}{aux_form} {pp}"
            return f"{subject}{before} {aux_form} {pp}"
        if subject.endswith("’"):
            return f"{subject}{aux_form} {pp}"
        return f"{subject}{aux_form} {pp}"
    return None


def past_participle(form_map: dict[str, str], metadata: dict[str, Any], person: str, *, example: bool, example_gender: str) -> str | None:
    lemma = metadata["lemma"]
    agreeing = metadata["ppAgreement"] == "subject" or metadata["reflexive"] == "required" or metadata["auxiliary"] == "être"
    singular = person in {"je", "tu", "il/elle/on", "il"}
    gender = example_gender if example else "f"
    if not agreeing:
        return form_map.get("Kms") or form_map.get("K") or form_map.get("Km") or form_map.get("Kfs")
    if form_map.get("K"):
        return form_map["K"]
    if singular:
        if example:
            return form_map.get("Kfs" if gender == "f" else "Kms") or form_map.get("Kms")
        return gender_variant(form_map.get("Kms"), form_map.get("Kfs"))
    if example:
        tag = "Kfp" if gender == "f" else "Kmp"
        return form_map.get(tag) or form_map.get("Kmp") or form_map.get("Kfp")
    return plural_gender_variant(form_map.get("Kmp"), form_map.get("Kfp"), form_map.get("Kms"), form_map.get("Kfs"))


def gender_variant(masc: str | None, fem: str | None) -> str | None:
    if not masc:
        return fem
    if not fem or fem == masc:
        return masc
    if fem == masc + "e":
        return masc + "(e)"
    prefix = 0
    while prefix < min(len(masc), len(fem)) and masc[prefix] == fem[prefix]:
        prefix += 1
    return masc[:prefix] + "(" + fem[prefix:] + ")" + masc[prefix:]


def plural_gender_variant(masc_p: str | None, fem_p: str | None, masc_s: str | None, fem_s: str | None) -> str | None:
    if masc_s and fem_s and masc_p == masc_s + "s" and fem_p == fem_s + "s" and fem_s == masc_s + "e":
        return masc_s + "(e)s"
    if not masc_p:
        return fem_p
    if not fem_p or fem_p == masc_p:
        return masc_p
    prefix = 0
    while prefix < min(len(masc_p), len(fem_p)) and masc_p[prefix] == fem_p[prefix]:
        prefix += 1
    return masc_p[:prefix] + "(" + fem_p[prefix:] + ")" + masc_p[prefix:]


def compose_example(metadata: dict[str, Any], tense: str, form: str) -> str:
    frame = metadata["exampleFrames"].get(tense)
    if not isinstance(frame, str) or frame.count("{form}") != 1:
        raise ValueError(f"{metadata['lemma']}: {tense} needs exactly one reviewed {{form}} frame")
    sentence = frame.replace("{form}", form)
    sentence = sentence[:1].upper() + sentence[1:]
    if sentence[-1:] not in ".?!…":
        raise ValueError(f"{metadata['lemma']}: {tense} frame must end with punctuation")
    if "{" in sentence or "}" in sentence:
        raise ValueError(f"{metadata['lemma']}: unexpected placeholder in {tense} frame")
    return sentence


def build_verb(metadata: dict[str, Any], all_forms: dict[str, dict[str, set[str]]], preferred: dict[str, dict[str, str]]) -> dict[str, Any]:
    lemma = metadata["lemma"]
    forms = resolved_forms(all_forms.get(lemma, {}), preferred.get(lemma, {}))
    auxiliaries = {aux: resolved_forms(all_forms.get(aux, {}), preferred.get(aux, {})) for aux in ("aller", "avoir", "être")}
    output_tenses = []
    for tense, title in TENSES:
        rows = []
        persons = ("tu", "nous", "vous") if tense == "imperatif" else PERSON_ORDER
        if "validPersonsByTense" in metadata:
            persons = tuple(person for person in persons if person in metadata["validPersonsByTense"].get(tense, []))
        elif metadata.get("validPersons") is not None:
            allowed = metadata["validPersons"]
            available = tuple(person for person in (*PERSON_ORDER, "il") if person in allowed)
            persons = available
        for person in persons:
            form = inflected_clause(forms, tense, person, metadata, example=False, auxiliaries=auxiliaries)
            if form is None:
                continue
            example_form = inflected_clause(forms, tense, person, metadata, example=True, auxiliaries=auxiliaries)
            if example_form is None:
                continue
            rows.append({
                "person": person,
                "form": form,
                "example": compose_example(metadata, tense, example_form),
            })
        output_tenses.append({"id": tense, "title": title, "rows": rows})
    return {
        "entryID": stable_id(lemma),
        "infinitive": metadata["infinitive"],
        "usageNote": metadata.get("usageNote"),
        "tenses": output_tenses,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check-only", action="store_true", help="validate metadata, source coverage, and all examples without writing verbs.json")
    args = parser.parse_args()
    metadata = load_json(METADATA)
    if metadata.get("schemaVersion") != 1:
        raise SystemExit("verb_metadata.json schemaVersion must be 1")
    entries = metadata.get("verbs")
    if not isinstance(entries, list) or len(entries) != 395:
        raise SystemExit(f"Expected exactly 395 editable verb metadata records, found {len(entries) if isinstance(entries, list) else 'invalid'}")
    ids = [item.get("entryID") for item in entries]
    if len(set(ids)) != len(ids) or any(item.get("entryID") != stable_id(item.get("lemma", "")) for item in entries):
        raise SystemExit("metadata entryIDs must be unique stable lemma|VER IDs")
    with (ROOT / "Resources" / "FleLex_TT_Beacco.tsv").open(encoding="utf-8", newline="") as handle:
        source_rows = [
            (stable_id(unicodedata.normalize("NFC", row["word"]).lower()), row["word"], index + 1)
            for index, row in enumerate(csv.DictReader(handle, delimiter="\t"))
            if row["level"] == "B1" and row["tag"] == "VER"
        ]
    expected = {entry_id: (lemma, row_no) for entry_id, lemma, row_no in source_rows}
    actual = {item["entryID"]: (item["lemma"], item.get("sourceRow")) for item in entries}
    if actual != expected:
        raise SystemExit("verb_metadata.json does not exactly match B1 VER source lemmas and 1-based data row numbers")
    forms, preferred = read_morphology()
    out = {"schemaVersion": 1, "verbs": []}
    for item in entries:
        if item.get("lemma") not in forms and item.get("lemma") != "hier":
            raise SystemExit(f"No Lefff forms for {item.get('lemma')}")
        if item.get("reflexive") not in {"never", "optional", "required"}:
            raise SystemExit(f"{item['lemma']}: reflexive must be never, optional, or required")
        if item.get("auxiliary") not in {"avoir", "être"}:
            raise SystemExit(f"{item['lemma']}: auxiliary must be avoir or être")
        if item.get("ppAgreement") not in {"invariant", "subject"}:
            raise SystemExit(f"{item['lemma']}: ppAgreement must be invariant or subject")
        out["verbs"].append(build_verb(item, forms, preferred))
    if not args.check_only:
        OUTPUT.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"Wrote {len(out['verbs'])} verbs to {OUTPUT}")
    else:
        print(f"Metadata/source checks passed for {len(out['verbs'])} verbs")


if __name__ == "__main__":
    main()
