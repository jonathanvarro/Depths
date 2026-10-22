"""Copy built-in outputs byte-exact and consolidate immutable #141 records."""
from pathlib import Path
import hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/monsters-v1'
entries=[]
manifest=SOURCE/'generation.json'
known={a['id']:a.get('sha256') for a in json.loads(manifest.read_text(encoding='utf-8-sig'))['assets']} if manifest.exists() else {}
for record in sorted((SOURCE/'records').glob('*.json')):
    entry=json.loads(record.read_text(encoding='utf-8-sig'))
    origin=Path(entry['original_path']);dest=ROOT/entry['source']
    assert dest.resolve().is_relative_to(SOURCE.resolve())
    if dest.exists():
        if origin.exists():assert dest.read_bytes()==origin.read_bytes(),entry['id']
    else:
        assert origin.is_file(),origin
        dest.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(origin,dest)
    entry['sha256']=hashlib.sha256(dest.read_bytes()).hexdigest()
    assert known.get(entry['id']) in [None,entry['sha256']],'Immutable master changed: '+entry['id']
    entries.append(entry)
(SOURCE/'generation.json').write_text(json.dumps({'issue':141,'date':'2026-10-21','tool':'built-in image_gen','assets':entries},indent=2)+'\n',encoding='utf-8',newline='\n')
print('MONSTER_SOURCES: %d byte-exact masters, prompts and hashes'%len(entries))
