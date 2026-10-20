"""Check classification preserves every pre-existing pixel binding and resource value."""
from pathlib import Path
import json,re,subprocess,hashlib

ROOT=Path(__file__).resolve().parents[2]
BASELINE='84abb14'
catalogue=json.loads((ROOT/'data/portraits/catalog.json').read_text(encoding='utf-8'))
entries=catalogue['portraits']+catalogue['supporting_resources']
for entry in entries:
    path=ROOT/entry['resource'].removeprefix('res://')
    text=path.read_text(encoding='utf-8')
    original=subprocess.check_output(['git','show',BASELINE+':'+path.relative_to(ROOT).as_posix()],cwd=ROOT,text=True)
    clean=re.sub(r'^(rig_kind|rig_family|face_id) = .*\n','',text,flags=re.M)
    assert clean==original,(path,'non-metadata change')
assert len(catalogue['portraits'])==30
assert sum(e['kind']=='Unique' for e in catalogue['portraits'])==3
assert len({e['face_id'] for e in catalogue['portraits'] if e['kind']=='Reusable'})==9
report={'baseline':BASELINE,'resources_checked':len(entries),'only_rig_metadata_changed':True,'existing_pixel_bindings_unchanged':True,'failures':[]}
(ROOT/'art/concepts/portrait-rigs-v1/resource-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
print('31 resources: only rig identity metadata changed; all original pixel bindings/values preserved.')
