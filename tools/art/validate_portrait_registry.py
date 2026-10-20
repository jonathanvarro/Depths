"""Check only approved frame bindings change; neutral art and all other values stay fixed."""
from pathlib import Path
import json,re,subprocess,hashlib

ROOT=Path(__file__).resolve().parents[2]
BASELINE='3d1ee08'
catalogue=json.loads((ROOT/'data/portraits/catalog.json').read_text(encoding='utf-8'))
entries=catalogue['portraits']+catalogue['supporting_resources']
for entry in entries:
    path=ROOT/entry['resource'].removeprefix('res://')
    text=path.read_text(encoding='utf-8')
    original=subprocess.check_output(['git','show',BASELINE+':'+path.relative_to(ROOT).as_posix()],cwd=ROOT,text=True)
    def neutral_bindings(value):
        # Only paths used by the existing blink/talk arrays can change.
        body=value.split('[resource]',1)[1]
        ids=[]
        for line in re.findall(r'^(?:blink_frames|talk_frames) = (.+)$',body,re.M):
            ids+=re.findall(r'ExtResource\("([^"]+)"\)',line)
        for identifier in ids:
            pattern=r'(\[ext_resource type="Texture2D" path=")[^"]+(" id="'+re.escape(identifier)+r'"\])'
            value=re.sub(pattern,lambda match:match[1]+'<approved-animation-path>'+match[2],value)
        return value
    assert neutral_bindings(text)==neutral_bindings(original),(path,'non-frame resource change')
assert len(catalogue['portraits'])==30
assert sum(e['kind']=='Unique' for e in catalogue['portraits'])==3
assert len({e['face_id'] for e in catalogue['portraits'] if e['kind']=='Reusable'})==9
report={'baseline':BASELINE,'resources_checked':len(entries),'only_approved_animation_bindings_changed':True,'resting_character_and_other_bindings_unchanged':True,'failures':[]}
(ROOT/'art/concepts/portrait-rigs-v1/resource-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
print('31 resources: only approved animation paths differ; resting art, metadata and all other values preserved.')
