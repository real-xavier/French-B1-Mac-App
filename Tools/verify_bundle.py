"""Verify the packaged study data and editable source live inside the app."""
from pathlib import Path
import hashlib,json,sys
app=Path(sys.argv[1]) if len(sys.argv)>1 else Path('/Users/xavier/Codex/2026-10-27/realtime-voice-chat/outputs/French B1.app')
resources=app/'Contents/Resources'
bundle=resources/'FrenchB1_FrenchB1.bundle'/'Contents/Resources'
vocabulary=json.loads((bundle/'vocabulary.json').read_text())
verbs=json.loads((bundle/'verbs.json').read_text())
assert len(vocabulary['entries'])==1753
assert len(verbs['verbs'])==395
assert {e['id'] for e in vocabulary['entries'] if e['pos']=='VER'}=={v['entryID'] for v in verbs['verbs']}
assert all(len(e['examples'])==3 and e['english'] and e['french'] for e in vocabulary['entries'])
editable=resources/'Notices/Editable linguistic resources'
raw=editable/'FleLex_TT_Beacco.tsv'
assert hashlib.sha256(raw.read_bytes()).hexdigest()==vocabulary['snapshotSHA256']
assert (editable/'licenses/CC-BY-NC-SA-4.0-Legalcode.txt').stat().st_size>20_000
assert (editable/'licenses/LEFFF-LGPL-LR.txt').stat().st_size>10_000
assert (editable/'morphology/lefff-3.4-target-forms.tsv').exists()
assert len(list((editable/'vocabulary_authoring').glob('batch-*.jsonl')))==5
assert (editable/'verb_metadata.json').exists()
assert (app/'Contents/MacOS/FrenchB1').stat().st_mode & 0o111
print(f'Packaged bundle valid: 1753 entries, 395 verbs, {sum(len(t["rows"]) for v in verbs["verbs"] for t in v["tenses"])} form examples; complete editable resources and full licenses present.')
