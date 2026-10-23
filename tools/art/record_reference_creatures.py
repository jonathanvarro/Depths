"""Preserve reference-led concept inputs, built-in outputs and exact prompts."""
from pathlib import Path
import hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[2];SOURCE=ROOT/'art/source/reference-creatures-v1';OUT=ROOT/'art/concepts/reference-creatures-v1'
for folder in [SOURCE,OUT,SOURCE/'references',SOURCE/'records']:folder.mkdir(parents=True,exist_ok=True)
for folder in [SOURCE,OUT]:(folder/'.gdignore').write_text('')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def retain(origin,dest):
    assert dest.resolve().is_relative_to(ROOT.resolve())
    if dest.exists():
        if origin.exists():assert dest.read_bytes()==origin.read_bytes(),str(dest)
    else:shutil.copyfile(origin,dest)
refs=[]
for e in json.loads((SOURCE/'reference-inputs.json').read_text()):
    retain(Path(e['file']),ROOT/e['copy']);e['sha256']=sha(ROOT/e['copy']);refs.append(e)
old=json.loads((SOURCE/'generation.json').read_text()) if (SOURCE/'generation.json').exists() else {'assets':[],'references':[]}
known={e['id']:e['sha256'] for e in old['assets']}
for e in old['references']:assert sha(ROOT/e['copy'])==e['sha256'],'Reference changed'
entries=[]
for p in sorted((SOURCE/'records').glob('*.json')):
    e=json.loads(p.read_text());dest=ROOT/e['source'];retain(Path(e['original_path']),dest)
    e['sha256']=sha(dest);assert known.get(e['id'],e['sha256'])==e['sha256']
    review=OUT/(e['id']+'.png');retain(dest,review);e['review']=str(review.relative_to(ROOT)).replace('\\','/')
    e['reference_sha256']=next(r['sha256'] for r in refs if r['id']==e['id']);entries.append(e)
(SOURCE/'generation.json').write_text(json.dumps({'issue':153,'date':'2026-10-22','tool':'built-in image_gen','scope':'Five exploratory concepts; no production or story assignment','references':refs,'assets':entries},indent=2)+'\n',encoding='utf-8',newline='\n')
print('REFERENCE_CREATURE_SOURCES:',len(refs),'references,',len(entries),'unchanged generated masters')
