"""Preserve built-in ImageGen originals and exact prompts for #142."""
from pathlib import Path
import hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/events-trinkets-v1'
manifest=SOURCE/'generation.json'
known={a['id']:a.get('sha256') for a in json.loads(manifest.read_text())['assets']} if manifest.exists() else {}
entries=[]
for record in sorted((SOURCE/'records').glob('*.json')):
    entry=json.loads(record.read_text(encoding='utf-8-sig'))
    origin=Path(entry['original_path']);dest=ROOT/entry['source']
    assert dest.resolve().is_relative_to(SOURCE.resolve())
    if dest.exists():
        if origin.exists():assert dest.read_bytes()==origin.read_bytes(),entry['id']
    else:
        dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(origin,dest)
    entry['sha256']=hashlib.sha256(dest.read_bytes()).hexdigest()
    assert known.get(entry['id']) in [None,entry['sha256']],'Immutable source changed'
    entries.append(entry)
assert len(entries)==15,len(entries)
(SOURCE/'.gdignore').write_text('')
manifest.write_text(json.dumps({'issue':142,'date':'2026-10-22','tool':'built-in image_gen','assets':entries},indent=2)+'\n',encoding='utf-8')
print('EVENT_TRINKET_SOURCES: 15 byte-exact masters, prompts and hashes')
