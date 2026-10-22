"""Bind the four already-implemented foes, preserving all nonvisual fields."""
from pathlib import Path
import json,re,hashlib
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/monsters-v1'
IDS=['cave_bat','goblin_brute','gas_bloat','hollow_miner']
def read(p):return p.read_text(encoding='utf-8-sig')
def nonvisual(s):
    s=re.sub(r'^\[ext_resource type="PackedScene".*\]\n','',s,flags=re.M)
    s=re.sub(r'^(tint|sprite_scale) = .*\n','',s,flags=re.M)
    return s
baseline_path=SOURCE/'bindings-before.json'
baseline=json.loads(read(baseline_path)) if baseline_path.exists() else {'resources':{'data/enemies/'+id+'.tres':read(ROOT/'data/enemies'/(id+'.tres')) for id in IDS},'builder':read(ROOT/'tools/story/build_monsters.gd')}
for id in IDS:
    p=ROOT/'data/enemies'/(id+'.tres');s=read(p);before=baseline['resources'][p.relative_to(ROOT).as_posix()]
    assert nonvisual(s)==nonvisual(before),'Nonvisual fields changed; inspect '+id
    s=re.sub(r'(\[ext_resource type="PackedScene" path=")[^"]+(" id=)',r'\g<1>res://art/enemies/monsters-v1/'+id.replace('_','-')+r'/scene.tscn\2',s)
    s=re.sub(r'^(tint|sprite_scale) = .*\n','',s,flags=re.M)
    p.write_text(s,encoding='utf-8',newline='\n')
p=ROOT/'tools/story/build_monsters.gd';s=read(p)
for id in IDS:
    pattern=r'(_monster\("'+id+r'", \{.*?"scene": load\(")[^"]+("\),\n\s*"tint": )(?:Color\([^\n]+?\)|Color\.WHITE)(, "sprite_scale": )[^,]+,'
    s,count=re.subn(pattern,r'\g<1>res://art/enemies/monsters-v1/'+id.replace('_','-')+r'/scene.tscn\g<2>Color.WHITE\g<3>1.0,',s,flags=re.S)
    assert count==1,('Builder binding',id)
s=s.replace('## on tinted placeholders until ChatGPT\'s art (#141) lands. Rerun to','## with the delivered monster art (#141). Rerun to')
p.write_text(s,encoding='utf-8',newline='\n')
baseline_path.write_text(json.dumps(baseline,indent=2)+'\n',encoding='utf-8',newline='\n')
print('MONSTER_BINDINGS: four live scenes, white tint/unit scale; all nonvisual resource fields retained')
