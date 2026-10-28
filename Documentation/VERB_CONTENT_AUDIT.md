# Independent verb-content audit

Reviewed on 2026-10-27 against `Resources/verb_metadata.json` and the materialized examples in `Resources/verbs.json`.

## Scope

- Reviewed all 395 editable verb records and all 2,765 example-frame slots across the seven contract tenses. There are 424 distinct nonempty frame strings because several verbs deliberately vary examples by tense.
- Checked subject compatibility and argument structure in the frame set, with particular attention to generated first-person and third-person plural examples and to passé composé, futur proche, and imperative frames.
- Spot-checked rendered rows in `verbs.json`, especially rare, defective, reflexive, or auxiliary-sensitive verbs. This is a linguistic audit, not a certification of every generated paradigm.
- The already corrected entries reported by the coordinator (`comporter`, `consister`, `contenir`, `couler`, `fleurir`, `valoir`, and `envoler`) were re-read and are acceptable in their documented senses. `bruire` (personified wind), `douer` (an author creating a character), and the source-tagged rare verbs `ailler`, `hier`, and `mécher` are acceptable with their explicit usage notes.

## Findings

### P1 — `faillir|VER`, `imperatif` (`tu`)

`Resources/verbs.json` renders the row as **« Faille à la parole donnée à toute l’équipe. »** The imperative of *faillir* is listed as *faillis* (or the alternate *faux*), not *faille*; *faille* is a subjunctive form. Use **« Ne faillis pas à la parole donnée à toute l’équipe. »** or **« Ne fais pas défaut à l’équipe. »** for a natural imperative example. The current *je faux* family is a recognized but less-used conjugation; Larousse says the *je faillis* family is more common and that non-compound forms of *faillir* are rare. Either select and document a consistent paradigm, or add a usage note marking the retained forms and the literary sense as rare. [Larousse conjugation of *faillir*](https://www.larousse.fr/conjugaison/francais/faillir/4596), [Larousse usage note for *faillir*](https://www.larousse.fr/dictionnaires/francais/faillir/32693).

### P2 — `piquer|VER`, all example frames

The frame **« {form} un doigt avec une aiguille en cousant. »** produces examples such as **« Je pique un doigt avec une aiguille en cousant. »** In the intended accidental self-injury sense, French uses the pronominal construction *se piquer le doigt*; the current non-pronominal row instead suggests that the subject pricks someone else’s finger. To keep the existing non-reflexive lemma and avoid changing its conjugation, replace the object with a sewing item, for example **« {form} un ourlet à la machine pour le raccourcir. »** Larousse explicitly gives *se piquer le doigt avec une aiguille* and uses *piquer un ourlet* for machine sewing. [Larousse: *piquer*](https://www.larousse.fr/dictionnaires/francais/piquer/61107).

### P2 — `témoigner|VER`, all example frames

**« {form} de soutien aux familles touchées. »** has a bare noun after *de*. In this sense, *témoigner* takes a direct object (*témoigner son soutien*) or *de* plus a determined noun phrase (*témoigner de la solidarité*). Replace the frame with **« {form} de la solidarité envers les familles touchées. »** Larousse distinguishes these constructions and gives *témoigner de l’intérêt* / *témoigner son amitié*. [Larousse: *témoigner*](https://www.larousse.fr/dictionnaires/francais/t%C3%A9moigner/77202).

### P2 — Imperative examples for involuntary events or outcomes

The forms are morphologically imperative, but several present frames make the imperative read as a command to cause an involuntary event or outcome without a role-play or figurative context. Examples include **`déprimer|VER`** (« Déprime à cause du manque de soleil. »), **`frissonner|VER`** (« Frissonne de froid sous la pluie. »), **`grossir|VER`** (« Grossis à cause des repas trop copieux de l’hiver. »), **`maigrir|VER`** (« Maigris après un régime trop strict. »), **`sursauter|VER`** (« Sursaute en entendant un bruit dans le couloir. »), **`s’évanouir|VER`** (« Évanouis-toi sous l’effet de la chaleur dans le métro. »), **`survivre|VER`** (« Survis à l’accident grâce à l’intervention rapide des secours. »), **`tousser|VER`** (« Tousse toute la nuit à cause de la poussière. »), and **`trembler|VER`** (« Tremble de froid en attendant le bus. »). These are not conjugation errors; revise the imperative examples to give a plausible request, warning, or explicit acting context (for example, **« Toussez pour que le médecin puisse écouter votre respiration. »**). The *grandir* imperative also reads as an implausible life-outcome command in its current frame (« Grandis dans une petite ville à la campagne. »); either frame it as an exhortation or use a more actionable sense.

## Disposition (2026-10-27)

All findings above have been applied in `Resources/verb_metadata.json` and regenerated into `Resources/verbs.json`; verb counts and row counts are unchanged.

- `faillir`: the `tu` imperative is now `faillis`, selected over Lefff’s `faille` through the pinned, source-noted editorial override in `Resources/morphology/verb_morphology_overrides.json`. Its imperative example is negative (`Ne faillis pas…`), and the usage note explains that the non-compound literary sense is rare and that the retained non-imperative paradigm follows Lefff. The choice matches Larousse’s listed imperative forms.
- `piquer` keeps the non-reflexive paradigm and now uses the ordinary sewing sense of stitching an *ourlet*. `témoigner` now takes a complete context (*devant le tribunal pour raconter les faits*).
- The imperative frames for `déprimer`, `frissonner`, `sursauter`, `trembler`, and `s’évanouir` explicitly direct a performance in a scene; `tousser` has a doctor-request context; `survivre` is framed as a video-game challenge; `grossir` means enlarging print; `grandir` is an exhortation to mature; and `maigrir` is an acting direction.
- Similar checks revised `rougir`, `paraître`, `ressentir`, and `valoir`: their imperative examples now use an acting/photo/role-play or encouragement context. `paraître` uses invariant *en pleine forme* to avoid adjective-agreement errors across persons.
- `Tools/validate_verbs.py` now has explicit fixtures for the override, the corrected complement frames, and every reviewed imperative context.

This remains a targeted content audit rather than a certification of every generated paradigm or sentence. The independent review inspected all editable frames and materialized examples, but the most detailed linguistic fixtures are concentrated on irregular, defective, reflexive, auxiliary-sensitive, and audited imperative cases.

Coordinator final follow-up: the grandir imperative frame now uses « {form} en prenant de nouvelles responsabilités. » so every imperative person agrees without a hard-coded second verb. This correction is retained in the editable metadata and regenerated output.
