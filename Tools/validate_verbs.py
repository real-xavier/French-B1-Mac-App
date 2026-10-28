#!/usr/bin/env python3
"""Validate the materialized conjugations, source trace, and high-risk paradigms."""

from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "Resources" / "verbs.json"
METADATA = ROOT / "Resources" / "verb_metadata.json"
SOURCE = ROOT / "Resources" / "morphology" / "lefff-3.4-target-forms.tsv"
MANIFEST = ROOT / "Resources" / "morphology" / "manifest.json"
BUILDER_PATH = ROOT / "Tools" / "build_verbs.py"

spec = importlib.util.spec_from_file_location("build_verbs", BUILDER_PATH)
assert spec and spec.loader
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


def read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def check(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"FAIL: {message}")


def verb_by_lemma(corpus: dict[str, Any], lemma: str) -> dict[str, Any]:
    matches = [verb for verb in corpus["verbs"] if verb["entryID"] == lemma + "|VER"]
    check(len(matches) == 1, f"expected exactly one `{lemma}|VER` entry")
    return matches[0]


def tense(verb: dict[str, Any], tense_id: str) -> dict[str, Any]:
    matches = [table for table in verb["tenses"] if table["id"] == tense_id]
    check(len(matches) == 1, f"{verb['entryID']} must contain one {tense_id} table")
    return matches[0]


def row(verb: dict[str, Any], tense_id: str, person: str) -> dict[str, Any]:
    matches = [entry for entry in tense(verb, tense_id)["rows"] if entry["person"] == person]
    check(len(matches) == 1, f"{verb['entryID']} {tense_id} missing or duplicates person {person}")
    return matches[0]


def main() -> None:
    corpus = read(OUTPUT)
    metadata = read(METADATA)
    manifest = read(MANIFEST)
    check(corpus.get("schemaVersion") == 1, "verbs.json schemaVersion must be 1")
    check(len(corpus.get("verbs", [])) == 395, "verbs.json must contain all 395 B1 VER entries")
    check(len({v["entryID"] for v in corpus["verbs"]}) == 395, "verb IDs must be unique")
    check(hashlib.sha256(SOURCE.read_bytes()).hexdigest() == manifest["fileSHA256"], "source extract hash differs from pinned manifest")
    check(SOURCE.stat().st_size == manifest["byteCount"], "source extract byte count differs from manifest")

    expected_tenses = [tense_id for tense_id, _title in builder.TENSES]
    metadata_by_id = {v["entryID"]: v for v in metadata["verbs"]}
    check(len(metadata_by_id) == 395, "metadata IDs must be unique")
    check(set(metadata_by_id) == {v["entryID"] for v in corpus["verbs"]}, "metadata and output verb IDs differ")
    for verb in corpus["verbs"]:
        source = metadata_by_id[verb["entryID"]]
        check([t["id"] for t in verb["tenses"]] == expected_tenses, f"{verb['entryID']} tense order is wrong")
        check(bool(verb["infinitive"]), f"{verb['entryID']} infinitive is empty")
        rows_total = 0
        for table in verb["tenses"]:
            seen_people: set[str] = set()
            for entry in table["rows"]:
                check(entry["person"] not in seen_people, f"{verb['entryID']} {table['id']} duplicates {entry['person']}")
                seen_people.add(entry["person"])
                check(bool(entry["form"].strip()), f"{verb['entryID']} {table['id']} has an empty form")
                check(bool(entry["example"].strip()), f"{verb['entryID']} {table['id']} has an empty example")
                check(entry["example"][-1] in ".?!…", f"{verb['entryID']} {table['id']} example lacks sentence punctuation")
                rows_total += 1
            if len(table["rows"]) == 0:
                check(bool(verb.get("usageNote")), f"{verb['entryID']} empty {table['id']} table needs a usage note")
                check(source["exampleFrames"][table["id"]] is None, f"{verb['entryID']} invalid {table['id']} should not have an unused example frame")
        check(rows_total > 0, f"{verb['entryID']} has no valid conjugation rows")

    faillir = verb_by_lemma(corpus, "faillir")
    check(row(faillir, "imperatif", "tu")["form"] == "faillis", "faillir imperative uses the verified faillis variant")
    check(row(faillir, "imperatif", "tu")["example"] == "Ne faillis pas à la parole donnée à l’équipe.", "faillir imperative has a natural negative frame")
    check("par correction éditoriale" in faillir["usageNote"], "faillir usage note documents the editorial paradigm choice")
    overrides = read(ROOT / "Resources" / "morphology" / "verb_morphology_overrides.json")
    check(overrides["forms"]["faillir"]["Y2s"] == "faillis", "faillir editorial form is pinned in morphology overrides")
    check("Larousse" in overrides["editorialNotes"]["faillir.Y2s"], "faillir editorial override includes its source rationale")

    aborder = verb_by_lemma(corpus, "aborder")
    check(row(aborder, "present", "je")["form"] == "j’aborde", "regular -er present pronoun/elision fixture")
    check(row(aborder, "conditionnel", "tu")["form"] == "tu aborderais", "conditional singular fixture")

    acquérir = verb_by_lemma(corpus, "acquérir")
    check(row(acquérir, "present", "je")["form"] == "j’acquiers", "acquérir present irregular stem")
    check(row(acquérir, "present", "ils/elles")["form"] == "ils/elles acquièrent", "acquérir third-person plural accent")
    check(row(acquérir, "futurSimple", "je")["form"] == "j’acquerrai", "acquérir future double-r stem")

    ailler = verb_by_lemma(corpus, "ailler")
    check(row(ailler, "present", "je")["form"] == "j’aille", "ailler must retain its distinct culinary paradigm")
    check("ail" in ailler["usageNote"], "ailler usage note must disambiguate the source-tagged item")

    hier = verb_by_lemma(corpus, "hier")
    check(row(hier, "present", "je")["form"] == "je hie", "technical hier must preserve its h-aspiré spelling")
    check(row(hier, "futurSimple", "je")["form"] == "je hierai", "technical hier future must not elide je")

    enfuir = verb_by_lemma(corpus, "enfuir")
    check(enfuir["infinitive"] == "s’enfuir", "enfuir infinitive must show its required reflexive form")
    check(row(enfuir, "present", "je")["form"] == "je m’enfuis", "enfuir present clitic")
    check(row(enfuir, "passeCompose", "je")["form"] == "je me suis enfui(e)", "enfuir PC auxiliary and agreement variants")
    check(row(enfuir, "futurProche", "je")["form"] == "je vais m’enfuir", "enfuir future-proche clitic position")
    check(row(enfuir, "passeCompose", "je")["example"].startswith("Je me suis enfuie"), "reflexive example chooses one concrete feminine variant")

    mefier = verb_by_lemma(corpus, "méfier")
    check(mefier["infinitive"] == "se méfier", "méfier infinitive must use non-elided se before consonant")
    check(row(mefier, "futurProche", "je")["form"] == "je vais me méfier", "méfier future proche spacing/clitic")

    neiger = verb_by_lemma(corpus, "neiger")
    for table in neiger["tenses"]:
        expected_people = [] if table["id"] == "imperatif" else ["il"]
        check([r["person"] for r in table["rows"]] == expected_people, f"neiger must remain impersonal in {table['id']}")
    check(row(neiger, "present", "il")["form"] == "il neige", "impersonal display uses only il")
    check(row(neiger, "present", "il")["example"].startswith("Il neige"), "impersonal example uses il")

    bruire = verb_by_lemma(corpus, "bruire")
    check([r["person"] for r in tense(bruire, "present")["rows"]] == ["je", "tu", "il/elle/on"], "bruire present defective persons")
    check([r["person"] for r in tense(bruire, "imparfait")["rows"]] == ["je", "tu", "il/elle/on"], "bruire imperfect defective persons")
    check(len(tense(bruire, "passeCompose")["rows"]) == 0, "bruire must not invent a passé composé")
    check(len(tense(bruire, "imperatif")["rows"]) == 0, "bruire has no imperative")
    check(row(bruire, "imparfait", "il/elle/on")["form"] == "il/elle/on bruyait", "bruire imperfect spelling")

    frire = verb_by_lemma(corpus, "frire")
    check([r["person"] for r in tense(frire, "present")["rows"]] == ["je", "tu", "il/elle/on"], "frire present must be singular only")
    check(len(tense(frire, "imparfait")["rows"]) == 0, "frire has no imperfect")
    check([r["person"] for r in tense(frire, "imperatif")["rows"]] == ["tu"], "frire imperative is singular tu only")
    check(row(frire, "passeCompose", "nous")["form"] == "nous avons frit", "frire compound forms remain available")

    redescendre = verb_by_lemma(corpus, "redescendre")
    check(row(redescendre, "passeCompose", "je")["form"] == "je suis redescendu(e)", "redescendre intransitive movement auxiliary")
    check("transitif" in redescendre["usageNote"], "redescendre auxiliary distinction needs a note")

    repasser = verb_by_lemma(corpus, "repasser")
    check(row(repasser, "passeCompose", "je")["form"] == "j’ai repassé", "repasser ironing sense uses avoir")
    check("repasser" in repasser["usageNote"], "repasser auxiliary distinction needs a note")

    ressortir = verb_by_lemma(corpus, "ressortir")
    check(row(ressortir, "present", "il/elle/on")["form"] == "il/elle/on ressort", "ressortir-as-sortir pattern")
    check(row(ressortir, "passeCompose", "je")["form"] == "je suis ressorti(e)", "ressortir movement auxiliary")
    check("ressortit" in ressortir["usageNote"], "ressortir homonym distinction needs a note")

    rentraire = verb_by_lemma(corpus, "rentraire")
    check(row(rentraire, "passeCompose", "je")["form"] == "j’ai rentrait", "rentraire unusual Académie-validated past participle")
    check("textile" in rentraire["usageNote"], "rentraire note must identify its textile sense")
    check(row(rentraire, "futurSimple", "je")["example"].startswith("Je rentrairai un accroc"), "rentraire example must not duplicate its subject")

    envoler = verb_by_lemma(corpus, "envoler")
    check(envoler["infinitive"] == "s’envoler", "envoler should show its common pronominal sense")
    check(row(envoler, "present", "je")["form"] == "je m’envole", "envoler present reflexive clitic")
    check(row(envoler, "passeCompose", "je")["form"] == "je me suis envolé(e)", "envoler compound auxiliary and agreement")

    comporter = verb_by_lemma(corpus, "comporter")
    check(comporter["infinitive"] == "se comporter", "comporter examples should use the common pronominal sense")
    check(row(comporter, "present", "je")["form"] == "je me comporte", "comporter reflexive present")
    check(row(comporter, "imperatif", "tu")["example"].startswith("Comporte-toi"), "comporter reflexive imperative")

    consister = verb_by_lemma(corpus, "consister")
    check("personnification" in consister["usageNote"], "consister note must explain its literary subject context")
    check("Dans cette fable" in row(consister, "present", "je")["example"], "consister example supplies an abstract personification context")

    convenir = verb_by_lemma(corpus, "convenir")
    check(row(convenir, "passeCompose", "je")["form"] == "je suis convenu(e)", "convenir de uses être with agreement")
    check("avoir" in convenir["usageNote"], "convenir note must mention the avoir alternative")

    check("sa colère" not in row(verb_by_lemma(corpus, "contenir"), "present", "je")["example"], "contenir example should not fix a third-person possessor")
    check("l’injustice sous toutes ses apparences" in row(verb_by_lemma(corpus, "haïr"), "present", "je")["example"], "haïr example should fit all persons and tenses")
    check(row(verb_by_lemma(corpus, "fleurir"), "present", "je")["example"].startswith("Je fleuris le balcon"), "fleurir uses a transitive human subject frame")
    check(row(verb_by_lemma(corpus, "couler"), "present", "je")["example"].startswith("Je coule du béton"), "couler uses a transitive human subject frame")
    check(row(verb_by_lemma(corpus, "valoir"), "present", "je")["example"].startswith("Je vaux autant"), "valoir example works with personal pronouns")
    check("un auteur" in verb_by_lemma(corpus, "douer")["usageNote"], "douer note should explain the literary context")
    check("Dans le rôle du vent" in row(verb_by_lemma(corpus, "bruire"), "present", "je")["example"], "bruire example explicitly personifies the subject")

    check(row(verb_by_lemma(corpus, "piquer"), "present", "je")["example"].startswith("Je pique un ourlet à la machine"), "piquer uses its non-reflexive sewing sense")
    check(row(verb_by_lemma(corpus, "témoigner"), "present", "je")["example"].startswith("Je témoigne devant le tribunal"), "témoigner uses a complete natural complement")
    imperative_contexts = {
        "déprimer": "Pour la scène",
        "frissonner": "Pour la scène",
        "grossir": "Pour agrandir le titre",
        "grandir": "Grandis en prenant de nouvelles responsabilités",
        "maigrir": "Pour la scène",
        "sursauter": "Dans la scène",
        "évanouir": "Pour la scène",
        "survivre": "Dans ce jeu",
        "tousser": "À la demande du médecin",
        "trembler": "Pour la scène",
        "rougir": "Dans la scène",
        "paraître": "Pour la photo",
        "ressentir": "Pour le rôle",
        "valoir": "Dans ce dialogue",
    }
    for lemma, context in imperative_contexts.items():
        example = row(verb_by_lemma(corpus, lemma), "imperatif", "tu")["example"]
        check(example.startswith(context), f"{lemma} imperative example has its reviewed natural context")
    check(row(verb_by_lemma(corpus, "paraître"), "imperatif", "nous")["example"].endswith("en pleine forme."), "paraître frame avoids adjective agreement errors")

    print("Validated 395 verb tables, 7 ordered tenses, complete examples, source trace, and irregular/defective/reflexive/editorial fixtures.")


if __name__ == "__main__":
    main()
