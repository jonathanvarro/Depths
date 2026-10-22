"""Preserve built-in concept sheets and exact prompts without altering pixels."""
from pathlib import Path
import hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/descent-horror-v1';OUT=ROOT/'art/concepts/descent-horror-v1'
SOURCE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
for folder in [SOURCE,OUT]:(folder/'.gdignore').write_text('')
manifest=SOURCE/'generation.json'
previous=json.loads(manifest.read_text())['assets'] if manifest.exists() else []
known={e['id']:e['sha256'] for e in previous}
known_refs={e['id']:{r['path']:r['sha256'] for r in e['reference_images'] if 'sha256' in r} for e in previous}
entries=[]
for p in sorted((SOURCE/'records').glob('*.json')):
    entry=json.loads(p.read_text(encoding='utf-8'));dest=ROOT/entry['source'];origin=Path(entry['original_path'])
    assert dest.resolve().is_relative_to(SOURCE.resolve())
    if dest.exists():
        if origin.exists():assert dest.read_bytes()==origin.read_bytes(),entry['id']
    else:shutil.copyfile(origin,dest)
    h=hashlib.sha256(dest.read_bytes()).hexdigest();assert known.get(entry['id'],h)==h
    entry['sha256']=h
    for ref in entry['reference_images']:
        ref['sha256']=hashlib.sha256((ROOT/ref['path']).read_bytes()).hexdigest()
        assert known_refs.get(entry['id'],{}).get(ref['path'],ref['sha256'])==ref['sha256'],'Reference changed: '+ref['path']
    review=OUT/(entry['id']+'.png')
    if review.exists():assert review.read_bytes()==dest.read_bytes()
    else:shutil.copyfile(dest,review)
    entry['review']=str(review.relative_to(ROOT)).replace('\\','/');entries.append(entry)
manifest.write_text(json.dumps({'issues':[150,151,152],'date':'2026-10-22','tool':'built-in image_gen','scope':'draft concept sheets only; owner selections pending','assets':entries},indent=2)+'\n',encoding='utf-8',newline='\n')
print('HORROR_CONCEPT_SOURCES:',len(entries),'unaltered masters and exact prompts')
