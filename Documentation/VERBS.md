# Verb conjugations

`Resources/verbs.json` is the bundled, materialized conjugation corpus. `Resources/verb_metadata.json` is its editable source: it records every B1 verb, stable `lemma|VER` ID, TSV data-row number, infinitive, auxiliary choice, reflexive behavior, participle agreement, usage note, valid persons for defective verbs, and one example frame per tense.

Each example frame is a complete original French sentence with exactly one `{form}` placeholder. The builder substitutes a concrete pronoun and gender variant, then capitalizes the first character of the sentence. For example, `Après la randonnée, {form} vers la vallée.` can yield `Après la randonnée, elle est redescendue vers la vallée.` Frames should remain idiomatic for the verb’s complement pattern and for the tense. An empty frame is permitted only when the verb has no valid rows in that tense and its usage note explains why.

Build the JSON with:

```sh
python3 Tools/build_verbs.py
```

Check metadata and morphology without writing the output with:

```sh
python3 Tools/build_verbs.py --check-only
```

The builder reads the compact, project-local Lefff extract at `Resources/morphology/lefff-3.4-target-forms.tsv`, never calls a service or model, and writes all forms and examples into `Resources/verbs.json`. Recreate the extract from the pinned source with `python3 Tools/fetch_lefff_morphology.py`; the script verifies the complete input SHA-256 before selecting records. See `Resources/morphology/manifest.json` for the mirror commit, source and output hashes, selection rule, and the documented status of the canonical download endpoint.

Lefff’s compact person tags are expanded deterministically. Compound forms use reviewed metadata because the morphology file does not encode auxiliary selection. The intransitive movement senses of `redescendre` and `ressortir` use être in this table; their usage notes explain the avoir alternatives. `Repasser` illustrates the transitive ironing sense with avoir and notes the intransitive movement alternative. `Convenir` illustrates « convenir de » with être and notes the « convenir à » alternative. The source headwords `envoler` and `comporter` display the common pronominal infinitives `s’envoler` and `se comporter`; their stable IDs still use the source lemmas. `Mécher` is presented with its medical or oenological senses, not hair streaking (`émécher`). Required pronominal forms receive the appropriate subject clitics, auxiliary être, and past-participle agreement. Gender alternatives are shown together in the form, while each example uses one concrete, natural variant. The rare literary verb `faillir` retains its Lefff simple-tense variants; its `tu` imperative is explicitly overridden to `faillis` from Larousse’s recognized imperative variants, with the rationale recorded in `Resources/morphology/verb_morphology_overrides.json` and `usageNote`.

The Lefff tables overgenerate ordinary paradigms for defective verbs. `bruire` and `frire` therefore have explicit valid-person maps; `neiger` is restricted to its impersonal third-person singular. The rare source-tagged `hier` is a technical, h-aspiré verb meaning “to drive in with a hie”; it is not the common adverb. `ailler` means to season with garlic. `rentraire` is a textile term; the Académie française records its unusual past participle as `rentrait` and distinguishes the related variant `rentrayer`.

## Selected morphology references

- [Lefff 3.4 maintainer page](https://pauillac.inria.fr/~sagot/) and [LGPL-LR license text](https://www.labri.fr/perso/clement/lefff/licence-LGPLLR.html)
- [Larousse: bruire](https://www.larousse.fr/conjugaison/francais/bruire/1182) and [frire](https://www.larousse.fr/fr/conjugaison/francais/frire/4929)
- [Académie française: rentraire](https://www.dictionnaire-academie.fr/conjuguer/A9R1776) and [rentrayer](https://www.dictionnaire-academie.fr/conjuguer/A9R1780)
- [Larousse: ressortir](https://www.larousse.fr/dictionnaires/francais/ressortir/68734)
- [Larousse: ailler](https://www.larousse.fr/dictionnaires/francais/ailler/1913) and [hier](https://fr.wiktionary.org/wiki/hier)
- [Larousse: mécher](https://www.larousse.fr/dictionnaires/francais/m%C3%A9cher/50049) and [Académie française: mécher](https://www.dictionnaire-academie.fr/article/A9M1471) distinguish its wine/medical senses from hair-streaking `émécher`.

The language data and generated verb resource are subject to LGPL-LR as documented in `Resources/licenses/README.md`; this is separate from the application source license.
