# Verb morphology resource notice

The conjugation resource is derived from **Lefff 3.4**, a French morphological lexicon by Benoît Sagot and the Lefff contributors. The version-specific download link on the named maintainer’s page identifies Lefff 3.4 as LGPL-LR and links `lefff-3.4.mlex.tgz`. The full license text accompanies this project in `LEFFF-LGPL-LR.txt`.

The legacy Inria GForge download returned HTTP 403 on 2026-10-27. The pinned mirror file was retrieved from the `ClaudeCoulombe/FrenchLefffLemmatizer` repository at commit `8d5b095d4fd73499ffbec0e7b78b447a26653aa1`. Its Git blob SHA-1 matches the pinned mirror blob; its SHA-256 is recorded in `Resources/morphology/manifest.json`. Only the verb records needed for the 395 source lemmas, plus the three auxiliaries, are retained in the project. Re-fetching and extracting them is deterministic with `Tools/fetch_lefff_morphology.py`.

**License-page discrepancy:** the named maintainer’s current page labels the latest Lefff 3.4 release LGPL-LR; the current ALMAnaCH page labels its Lefff 3.4 download CeCILL-C. This corpus follows the license on the version-specific download link used for this snapshot, LGPL-LR, and retains the upstream notice and license. Confirm the intended terms with the maintainers before redistributing the linguistic resource outside this project.

Lefff source rows are adapted and normalized in `Resources/morphology/lefff-3.4-target-forms.tsv`, with changes documented in the manifest. The materialized verb tables and their editable morphology source are distributed under LGPL-LR. The `hier` entry is a separate manually authored regular -ier paradigm because the tagged source item has no Lefff verb entry; it is identified in the morphology override file and verb documentation.

## References

- Maintainer’s Lefff 3.4 page: <https://pauillac.inria.fr/~sagot/>
- Current ALMAnaCH page: <https://almanach.inria.fr/software_and_resources/custom/Alexina-en.html>
- LGPL-LR text: <https://www.labri.fr/perso/clement/lefff/licence-LGPLLR.html>
- Sagot, Benoît (2010), “The Lefff, a freely available and large-coverage morphological and syntactic lexicon for French,” LREC 2010.
