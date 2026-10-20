"""Check only the explicit complete-component bindings change in live resources."""
from pathlib import Path
import json,re,subprocess,hashlib

ROOT=Path(__file__).resolve().parents[2]
BASELINE='3d1ee08'
catalogue=json.loads((ROOT/'data/portraits/catalog.json').read_text(encoding='utf-8'))
entries=catalogue['portraits']+catalogue['supporting_resources']
manifest=ROOT/'art/concepts/portrait-components-v3/components.json'
refined=ROOT/'art/concepts/portrait-drawings-v4/components.json'
if refined.exists() and json.loads(refined.read_text(encoding='utf-8')).get('status')=='live':manifest=refined
components=json.loads(manifest.read_text(encoding='utf-8'))
approved={resource:face['bindings'] for face in components['faces'] for resource in face['resources']}
for entry in entries:
    path=ROOT/entry['resource'].removeprefix('res://')
    text=path.read_text(encoding='utf-8')
    original=subprocess.check_output(['git','show',BASELINE+':'+path.relative_to(ROOT).as_posix()],cwd=ROOT,text=True)
    expected=original
    for old,new in approved.get(entry['resource'],{}).items():
        expected=expected.replace('path="'+old+'"','path="'+new+'"')
    assert text==expected,(path,'change outside explicit clean-character/neutral/animation bindings')
assert len(catalogue['portraits'])==30
assert sum(e['kind']=='Unique' for e in catalogue['portraits'])==3
assert len({e['face_id'] for e in catalogue['portraits'] if e['kind']=='Reusable'})==9
report={'baseline':BASELINE,'resources_checked':len(entries),'only_explicit_component_bindings_changed':True,'static_expressions_and_all_other_resource_values_unchanged':True,'failures':[]}
(ROOT/'art/concepts/portrait-rigs-v1/resource-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
print('31 resources: only explicit clean-character/neutral/animation paths differ; static expressions and all other values preserved.')
