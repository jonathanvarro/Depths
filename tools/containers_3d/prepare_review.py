"""Write #242 scene compositions and a local native review."""
import argparse
import json
from pathlib import Path
import shutil
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/props/expedition-3d-v1'
parser=argparse.ArgumentParser()
parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args()
OUTPUT=args.workspace/'build/local-expedition-props-v1'
catalog=json.loads((ART/'catalog.json').read_text(encoding='utf-8'))
DIR='res://art/props/expedition-3d-v1/'
image=Image.new('RGB',(256,128),'#383d3c')
for index,colour in enumerate(catalog['palette'].values()):
    x,y=index%8*32,(3-index//8)*32
    image.paste('#'+colour,(x,y,x+32,y+32))
image.save(ART/'palette.png')
material=(ROOT/'art/dressing/mine-3d-v1/palette.tres').read_text(encoding='utf-8')
(ART/'palette.tres').write_text(material.replace('art/dressing/mine-3d-v1/palette.png',
                                              'art/props/expedition-3d-v1/palette.png'),encoding='utf-8')
recipes={
    'chest':{'Base':'chest-body','LidPivot/Model':'chest-lid','Contents':'contents'},
    'strongbox':{'Base':'strongbox-body','LidPivot/Model':'strongbox-lid','Contents':'contents','Spent':'broken-lock'},
    'abandoned-pack':{'Fresh':'pack-fresh','Spent':'pack-spent'},
    'dry-alcove':{'Fresh':'alcove-fresh','Spent':'alcove-spent'},
    'cold-camp':{'Fresh':'camp-fresh','Spent':'camp-spent'},
    'old-workings':{'Fresh':'workings-fresh','Spent':'workings-spent'},
    'rails':{'Model':'rails'},'rails-broken':{'Model':'rails-broken'},
}
for name,parts in recipes.items():
    resources=[f'[ext_resource type="Script" path="{DIR}prop.gd" id="script"]',
               f'[ext_resource type="Material" path="{DIR}palette.tres" id="palette"]']
    for model in dict.fromkeys(parts.values()):
        resources.append(f'[ext_resource type="PackedScene" path="{DIR}{model}.glb" id="{model}"]')
    nodes=['[node name="ExpeditionProp" type="Node3D"]','script=ExtResource("script")',
           'palette_material=ExtResource("palette")']
    if name in ['chest','strongbox']:
        hinge=catalog[name+'_hinge']
        nodes.extend(['','[node name="LidPivot" type="Node3D" parent="."]',
                      'position=Vector3('+','.join(str(v) for v in hinge)+')'])
    for node,model in parts.items():
        parent='LidPivot' if node.startswith('LidPivot/') else '.'
        child=node.split('/')[-1]
        nodes.extend(['',f'[node name="{child}" parent="{parent}" instance=ExtResource("{model}")]'])
        if node in ['Spent','Contents']: nodes.append('visible=false')
        if node=='Contents': nodes.append('position=Vector3(0,0.02,0)')
    text=f'[gd_scene load_steps={len(resources)+1} format=3]\n'+'\n'.join(resources)+'\n\n'+'\n'.join(nodes)+'\n'
    (ART/(name+'.tscn')).write_text(text,encoding='utf-8')
catalog['recipes']=recipes
(ART/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8')
for path in ART.iterdir():
    if path.is_file():
        target=OUTPUT/'art/props/expedition-3d-v1'/path.name
        target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(path,target)
for relative in ['art/third-party/kaykit-dungeon-remastered/grain-floor1.png',
                 'art/textures/cave-v1/floor.png','art/textures/cave-v1/wall.png','art/textures/cave-v1/ceiling.png']:
    target=OUTPUT/relative
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(ROOT/relative,target)
for name in ['review.gd','check.gd']:
    shutil.copy2(Path(__file__).with_name(name),OUTPUT/name)
(OUTPUT/'project.godot').write_text('''config_version=5
[application]
config/name="Depths / expedition props review"
run/main_scene="res://review.tscn"
[filesystem]
import/blender/enabled=false
[display]
window/size/viewport_width=1278
window/size/viewport_height=590
[input_devices]
pointing/emulate_touch_from_mouse=true
[rendering]
renderer/rendering_method="mobile"
rendering_device/driver.windows="d3d12"
''',encoding='utf-8')
(OUTPUT/'review.tscn').write_text('''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://review.gd" id="1"]
[node name="ExpeditionReview" type="Control"]
layout_mode=3
anchors_preset=15
anchor_right=1.0
anchor_bottom=1.0
grow_horizontal=2
grow_vertical=2
script=ExtResource("1")
''',encoding='utf-8')
exe=args.workspace/'build/research-godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe'
(OUTPUT/'START_REVIEW.cmd').write_text('@echo off\n"'+str(exe)+'" --path "%~dp0." %*\n',encoding='utf-8')
print('EXPEDITION_REVIEW',OUTPUT)
