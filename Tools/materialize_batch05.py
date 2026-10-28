from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
p=root/'Resources/vocabulary_authoring/batch-05-source.txt'
records=[]
for n,line in enumerate(p.read_text().splitlines(),1):
    if not line.strip():continue
    fields=line.split('§')
    if len(fields) not in (7,8):raise ValueError((n,len(fields),fields[0]))
    identity,g,english,french,*rest=fields
    examples=rest[:3]
    note=rest[3] if len(rest)==4 else None
    records.append(dict(id=identity,english=english,french=french,gender={'m':'masculine','f':'feminine'}.get(g),article={'m':'un','f':'une'}.get(g),examples=examples,usageNote=note,status='authored'))
for r in records:
    if r['id']=='étrange|NOM':r['article']='l’'
    if r['id']=='vrai|NOM':r['article']='le'
ids=[r['id'] for r in records]
assert len(ids)==len(set(ids))
(root/'Resources/vocabulary_authoring/batch-05.jsonl').write_text(''.join(json.dumps(r,ensure_ascii=False,separators=(',',':'))+'\n' for r in records))
print(f'Materialized {len(records)} authored entries')
