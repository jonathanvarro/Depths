"""Compose #247 state scenes and a local Mobile-renderer review."""
import argparse
import json
from pathlib import Path
import shutil
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/props/traps-sites-3d-v1'
parser=argparse.ArgumentParser()
parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args()
OUT=args.workspace/'build/local-traps-sites-mist-v1'
catalog=json.loads((ART/'catalog.json').read_text(encoding='utf-8'))
DIR='res://art/props/traps-sites-3d-v1/'
image=Image.new('RGB',(256,128),'#383d3c')
for i,colour in enumerate(catalog['palette'].values()):
    x,y=i%8*32,(3-i//8)*32
    image.paste('#'+colour,(x,y,x+32,y+32))
image.save(ART/'palette.png')
template=(ROOT/'art/dressing/mine-3d-v1/palette.tres').read_text()
(ART/'palette.tres').write_text(template.replace('art/dressing/mine-3d-v1/palette.png','art/props/traps-sites-3d-v1/palette.png'),encoding='utf-8',newline='\n')
for recipe in catalog['recipes']:
    resources=[f'[ext_resource type="Script" path="{DIR}prop.gd" id="script"]',f'[ext_resource type="Material" path="{DIR}palette.tres" id="palette"]']
    nodes=['[node name="CaveSite" type="Node3D"]','script=ExtResource("script")','palette_material=ExtResource("palette")',f'metadata/asset_id="{recipe["id"]}"']
    for state,model in recipe['models'].items():
        resources.append(f'[ext_resource type="PackedScene" path="{DIR}{model}.glb" id="{state}"]')
        node={'closed':'Fresh','open':'Open','empty':'Spent'}[state]
        nodes.extend(['',f'[node name="{node}" parent="." instance=ExtResource("{state}")]'])
        if state!='closed': nodes.append('visible=false')
    if recipe['id']=='dart-plate':
        resources.append(f'[ext_resource type="PackedScene" path="{DIR}dart-ports.glb" id="ports"]')
        nodes.extend(['','[node name="Ports" parent="." instance=ExtResource("ports")]','visible=false','position=Vector3(0,0.48,-0.985)'])
    (ART/(recipe['id']+'.tscn')).write_text(f'[gd_scene load_steps={len(resources)+1} format=3]\n'+'\n'.join(resources)+'\n\n'+'\n'.join(nodes)+'\n',encoding='utf-8',newline='\n')
for folder in ['art/props/traps-sites-3d-v1','art/effects/exploration-mist-v1']:
    for path in (ROOT/folder).iterdir():
        if path.is_file():
            target=OUT/folder/path.name
            target.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(path,target)
files=['art/third-party/kaykit-dungeon-remastered/grain-floor1.png',
       'art/effects/ambient-v1/fog-strip.png','art/textures/drowned-water-v1/shallow.png',
       'art/items/field-kit-v1/calming-herbs.png','art/items/field-kit-v1/compact64/calming-herbs.png']
files.extend('art/textures/cave-v1/'+name+'.png' for name in ['wall','floor','ceiling'])
for relative in files:
    target=OUT/relative
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(ROOT/relative,target)
for name in ['review.gd','check.gd']: shutil.copy2(Path(__file__).with_name(name),OUT/name)
(OUT/'project.godot').write_text('''config_version=5
[application]
config/name="Depths / traps, sites and mist"
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
''',encoding='utf-8',newline='\n')
(OUT/'review.tscn').write_text('''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://review.gd" id="1"]
[node name="CaveSiteReview" type="Control"]
layout_mode=3
anchors_preset=15
anchor_right=1.0
anchor_bottom=1.0
grow_horizontal=2
grow_vertical=2
script=ExtResource("1")
''',encoding='utf-8',newline='\n')
exe=args.workspace/'build/research-godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe'
(OUT/'START_REVIEW.cmd').write_text('@echo off\n"'+str(exe)+'" --path "%~dp0." %*\n',encoding='utf-8')
print('TRAPS_SITES_REVIEW',OUT)
