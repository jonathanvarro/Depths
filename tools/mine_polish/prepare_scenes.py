"""Create native wrappers; leave the original recipes and art families intact."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
MINE=ROOT/'art/dressing/mine-refined-v2'
CHESTS=ROOT/'art/props/loot-chests-v2'

def write(folder,name,models,nodes,script='prop.gd',extra=None):
    uri='res://'+folder.relative_to(ROOT).as_posix()+'/'
    resources=[f'[ext_resource type="Script" path="{uri}{script}" id="script"]']
    for model in models:resources.append(f'[ext_resource type="PackedScene" path="{uri}{model}.glb" id="{model}"]')
    if extra:resources+=extra
    text=f'[gd_scene load_steps={len(resources)+1} format=3]\n'+'\n'.join(resources)+'\n\n'
    text+='\n'.join(nodes)+'\n'
    (folder/(name+'.tscn')).write_text(text,encoding='utf-8',newline='\n')

for name in ['support','support-damaged','lantern-standing','lantern-hanging','rails','rails-broken']:
    write(MINE,name,[name],['[node name="MineProp" type="Node3D"]','script=ExtResource("script")',
        f'metadata/asset_id="{name}"','[node name="Model" parent="." instance=ExtResource("'+name+'")]'])
catalog=json.loads((MINE/'catalog.json').read_text())
nodes=['[node name="MinersShrine" type="Node3D"]','script=ExtResource("script")','metadata/asset_id="miners-shrine"',
 '[node name="Base" parent="." instance=ExtResource("shrine-base")]','[node name="Fresh" parent="." instance=ExtResource("offerings-fresh")]',
 '[node name="Spent" parent="." instance=ExtResource("offerings-spent")]','visible=false','[node name="Flames" parent="." instance=ExtResource("flames")]']
write(MINE,'miners-shrine',['shrine-base','offerings-fresh','offerings-spent','flames'],nodes)
write(MINE,'old-workings',['workings-fresh','workings-spent'],['[node name="OldWorkings" type="Node3D"]','script=ExtResource("script")',
 'metadata/asset_id="old-workings"','[node name="Fresh" parent="." instance=ExtResource("workings-fresh")]',
 '[node name="Spent" parent="." instance=ExtResource("workings-spent")]','visible=false'])
catalog=json.loads((CHESTS/'catalog.json').read_text())
for tier in catalog['tiers']:
    x,y,z=catalog['hinges'][tier]
    write(CHESTS,tier,[tier+'-body',tier+'-lid','contents'],['[node name="LootChest" type="Node3D"]',
     'script=ExtResource("script")',f'metadata/chest_type="{tier}"',f'metadata/asset_id="chest-{tier}"',
     f'[node name="Base" parent="." instance=ExtResource("{tier}-body")]',
     '[node name="LidPivot" type="Node3D" parent="."]',f'position=Vector3({x},{y},{z})',
     f'[node name="Model" parent="LidPivot" instance=ExtResource("{tier}-lid")]',
     '[node name="Contents" parent="." instance=ExtResource("contents")]','visible=false'])
print('Prepared eight refined mine scenes and three hinged loot chest types.')
