# Vocabulary content audit findings

Reviewed batches 01, 02, 04, and 05 (1,403 entries). These are the specific corrections found; this is not a line-by-line linguistic certification.

## Corrections

- **`alentour|NOM` — `gender`, `article`, `usageNote`:** The intended meaning and examples are the plural-only noun *les alentours*, but the row assigns singular *un alentour*, which is a different, specialized tapestry term. Since the schema requests a natural singular article and none exists for this sense, set both noun fields to `null` and start the note with `Source tag note:` explaining that the standard noun for this meaning is plural-only *les alentours*. Keep the plural examples. [Larousse: *alentour / alentours*](https://www.larousse.fr/dictionnaires/francais/alentour/2163)
- **`aise|NOM` — `examples[1]`:** “Le fauteuil offre une grande aise…” is not idiomatic; the noun *aise* is chiefly used in fixed expressions, as the row’s own note says. Replace it with a natural fixed-phrase example such as “Ce fauteuil permet aux passagers de voyager à leur aise.”
- **`par-dessus|ADV` — `usageNote`:** “Par-dessus peut aussi être suivi de de” is incorrect and conflicts with its own examples. Replace with “Par-dessus se construit avec un complément nominal : par-dessus le mur, par-dessus la tête.”
- **`travers|NOM` — `english`, `french`, `examples`:** The current translation/definition foreground dated breadth/crosswise senses, while two of three examples use the prepositional/adverbial phrases *à travers* and *de travers*. For the common count-noun sense, use `english: "quirk; fault"` and a definition such as “Défaut ou habitude particulière d’une personne.” Make at least two examples use the noun directly, e.g. “L’impatience est un de ses travers.” and “Son principal travers est de répondre sans écouter.” [Larousse: *travers*](https://www.larousse.fr/dictionnaires/francais/travers/79303)
- **`vendeur|ADJ` — `french`:** “ou qui est proposé à la vente” describes an item being for sale, not the adjective’s sense in these examples. Replace with a precise definition such as “Qui aide à vendre un produit ou attire les acheteurs.”


## Integration disposition

All five findings above were applied to the editable authoring records by the coordinator on 2026-10-27, before final corpus materialization. Batch05 compact source was updated as well so regeneration preserves the corrections.

## Batch 03: ordinals 701–900

These are findings from the additional read-only audit; the batch records have not been changed.

- **langage|NOM — examples[0]:** “Le langage des signes” is less precise than the recognized name for sign languages. Use “La langue des signes permet de communiquer sans parler.” The OQLF notes that “langage des signes” is encountered in usage, but identifies signed languages as languages. [OQLF: langue des signes](https://vitrinelinguistique.oqlf.gouv.qc.ca/fiche-gdt/fiche/26526970/langue-des-signes)
- **impossible|NOM — examples[2]:** “Ce qui semblait l’impossible au départ” is awkward. Replace with “L’impossible est devenu possible grâce au travail de l’équipe.” This retains the nominalized-adjective sense.
- **impôt|NOM — usageNote:** The note has a subject–verb agreement error: “les impôts peut désigner.” Replace the sentence with “L’expression « les impôts » désigne l’ensemble des taxes payées par un particulier.”
- **largement|ADV — examples[1]:** “La porte est assez large pour laisser passer le fauteuil roulant largement chargé” is semantically incoherent. Replace with “La nouvelle route est largement plus large que l’ancienne.”
- **licence|NOM — usageNote:** “Au Canada, licence désigne aussi un diplôme universitaire” is misleading as a current regional note. In Québec, *licence* was replaced by *baccalauréat* around 1970; France and Belgium use *licence* for a first-cycle university degree. [OQLF: licence](https://vitrinelinguistique.oqlf.gouv.qc.ca/fiche-gdt/fiche/8871167/licence)
- **légion|NOM — examples[1]:** “Les bénévoles sont une légion à se mobiliser…” is an unnatural construction. Replace with “Les bénévoles qui se mobilisent avant le festival sont légion.”

## Batch 03: ordinals 901–1050

These are findings from the final read-only slice; the batch records have not been changed.

- **magie|NOM — french:** The definition needs an article in its second coordinated phrase. Change “Art de produire des illusions ou impression merveilleuse créée par quelque chose” to “Art de produire des illusions ou une impression merveilleuse créée par quelque chose.”
- **mal|ADJ — usageNote:** The note labels *mal* as an adjective in *se sentir mal*, while standard dictionaries analyze that expression as adverbial. Preserve the source POS but clarify the usage note, e.g. “Mal reste invariable dans ces emplois; dans « se sentir mal » et « pas mal », il s’emploie adverbialement. Le mot s’emploie aussi comme nom.” [Larousse: mal](https://www.larousse.fr/dictionnaires/francais/mal/48788)

### Batch03 integration disposition

The coordinator applied all six lower-slice findings. The langage example now uses the accurate collocation langage du corps; the largement example uses largement assez de temps; the licence note specifically distinguishes the contemporary French and Québec degree names and the vehicle example was replaced with a sports-licence context. These preserve the target word in each example while correcting the cited issue.

### Final glossary disposition

The coordinator applied the magie and mal findings as well. All 13 recorded glossary findings are resolved in the editable sources. The source lemma alentour is visibly taught as les alentours in its English meaning and French definition, with a source-identity note; no singular un alentour is displayed for that sense. The independent read-through covered all 1,753 records. Structural validation and this audit remain distinct from professional linguistic certification.
