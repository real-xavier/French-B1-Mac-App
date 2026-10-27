"""Produce deterministic, inspectable content samples and structural evidence."""
from pathlib import Path
import collections,hashlib,json
root=Path(__file__).resolve().parents[1]
v=json.loads((root/'Resources/vocabulary.json').read_text())
c=json.loads((root/'Resources/verbs.json').read_text())
by_id={x['id']:x for x in v['entries']}
verbs={x['entryID']:x for x in c['verbs']}
ids=['-ci|ADV','afin|KON','de|DET:ART','dont|PRO','hélas|INT','quant|PRP','mécher|VER','rentraire|VER','étrange|NOM','être|NOM']
verb_ids=['enfuir','neiger','frire','bruire','redescendre','repasser','intervenir','acquérir','ailler','consister','faillir']
representative=[]
for lemma in verb_ids:
    verb=verbs[lemma+'|VER']
    tables=[]
    for tense in verb['tenses']:
        if tense['id'] not in ['present','passeCompose','futurProche','imperatif']:continue
        rows=tense['rows']
        picked=rows[:1] if len(rows)<2 else [rows[0],rows[-1]]
        tables.append(dict(id=tense['id'],validRowCount=len(rows),rows=picked))
    representative.append(dict(entryID=verb['entryID'],infinitive=verb['infinitive'],usageNote=verb['usageNote'],emptyTables=[t['id'] for t in verb['tenses'] if not t['rows']],tables=tables))
sentences=[s for e in v['entries'] for s in e['examples']]
counts=dict(rawSourceRows=14236,selectedB1Rows=len(v['entries']),uniqueLemmaPOS=len(by_id),verbs=len(verbs),generalExamples=len(sentences),conjugationRows=sum(len(t['rows']) for x in c['verbs'] for t in x['tenses']),repeatedGeneralSentences=sum(n>1 for n in collections.Counter(s.casefold() for s in sentences).values()))
assert counts['selectedB1Rows']==1753 and counts['generalExamples']==5259 and counts['verbs']==395 and counts['repeatedGeneralSentences']==0
assert 'un alentour' not in (str(by_id['alentour|NOM']['article'])+' '+by_id['alentour|NOM']['lemma'])
assert 'les alentours' in by_id['alentour|NOM']['english']
assert by_id['vendeur|ADJ']['french']=='Qui aide à vendre un produit ou attire les acheteurs.'
assert by_id['travers|NOM']['english']=='quirk; fault'
assert 'par-dessus peut aussi être suivi de de' not in (by_id['par-dessus|ADV']['usageNote'] or '').casefold()
payload=dict(date='2026-10-27',counts=counts,pinnedFLELexSHA256=v['snapshotSHA256'],resources={str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [root/'Resources/vocabulary.json',root/'Resources/verbs.json',root/'Resources/morphology/lefff-3.4-target-forms.tsv']},reviewScope='All glossary records and all editable verb frames received a second read-through. Generated form rows were structurally checked and high-risk paradigms spot-checked against cited resources. This is not certification of every linguistic judgment.',glossary=[by_id[x] for x in ids],representativeVerbs=representative)
p=root/'Documentation/CONTENT_REVIEW_SAMPLES.json'
p.write_text(json.dumps(payload,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(counts))
for e in payload['glossary']:
 print('\n'+e['id']+' — '+e['english']+'\n'+e['french'])
 for s in e['examples']:print(' • '+s)
 if e['usageNote']:print(' Note: '+e['usageNote'])
print('\nFull deterministic verb rows and resource hashes: '+str(p))
