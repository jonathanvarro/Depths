"""Compose #250 scenes and #225 material fixtures in an isolated Mobile project."""
import argparse
import json
from pathlib import Path
import shutil
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/features/transitions-3d-v1'
parser=argparse.ArgumentParser()
parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args()
OUT=args.workspace/'build/local-transitions-regional-v1'
catalog=json.loads((ART/'catalog.json').read_text())
DIR='res://art/features/transitions-3d-v1/'
image=Image.new('RGB',(256,128),'#383d3c')
for i,colour in enumerate(catalog['palette'].values()):
    x,y=i%8*32,(3-i//8)*32
    image.paste('#'+colour,(x,y,x+32,y+32))
image.save(ART/'palette.png')
template=(ROOT/'art/dressing/mine-3d-v1/palette.tres').read_text()
(ART/'palette.tres').write_text(template.replace('art/dressing/mine-3d-v1/palette.png','art/features/transitions-3d-v1/palette.png'),encoding='utf-8',newline='\n')
for entry in catalog['assets']:
    name=entry['id']
    family='stone-v1' if name.startswith('stone') else ('fortress-v1' if name.startswith('fortress') else 'cave-v1')
    (ART/(name+'.tscn')).write_text(f'''[gd_scene load_steps=5 format=3]
[ext_resource type="Script" path="{DIR}appearance.gd" id="script"]
[ext_resource type="Material" path="{DIR}palette.tres" id="palette"]
[ext_resource type="PackedScene" path="{DIR}{name}.glb" id="model"]
[ext_resource type="Material" path="res://art/textures/{family}/floor.tres" id="ground"]
[node name="PassageFeature" type="Node3D"]
script=ExtResource("script")
palette_material=ExtResource("palette")
ground_material=ExtResource("ground")
metadata/asset_id="{name}"
metadata/direction="{entry['direction']}"
metadata/forward="-Z"
[node name="Model" parent="." instance=ExtResource("model")]
''',encoding='utf-8',newline='\n')
for folder in ['art/features/transitions-3d-v1','art/materials/regional-props-v1']:
    for path in (ROOT/folder).iterdir():
        if path.is_file():
            target=OUT/folder/path.name
            target.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(path,target)
files=['art/third-party/kaykit-dungeon-remastered/grain-floor1.png','art/third-party/kaykit-dungeon-remastered/texture-floor1.png',
       'art/textures/descent-walls-v1/fungal-stone.png','art/textures/descent-surfaces-v1/fungal-stone-floor.png',
       'art/textures/descent-surfaces-v1/fungal-stone-ceiling.png','art/textures/waterworks-v1/wet-plain.png',
       'art/textures/descent-surfaces-v1/drowned-masonry-floor.png','art/textures/descent-surfaces-v1/drowned-masonry-ceiling.png']
for family in ['cave-v1','stone-v1','fortress-v1']:
    files.extend('art/textures/'+family+'/'+name+'.png' for name in (['wall_plain','floor','ceiling'] if family=='stone-v1' else ['wall','floor','ceiling']))
    files.append('art/textures/'+family+'/floor.tres')
for filename in ['barrel_large.glb','box_large.glb','bottle_B_green.glb']:
    files.append('art/third-party/kaykit-dungeon-remastered/models/'+filename)
files.extend('scripts/'+name for name in ['level_builder.gd','dungeon_map.gd','environment_theme.gd'])
for relative in files:
    assert (ROOT/relative).is_file(),relative
    target=OUT/relative
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(ROOT/relative,target)
for name in ['review.gd','check.gd']: shutil.copy2(Path(__file__).with_name(name),OUT/name)
(OUT/'project.godot').write_text('''config_version=5
[application]
config/name="Depths / transitions, blockers and regional materials"
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
[node name="TransitionsReview" type="Control"]
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
print('TRANSITIONS_REVIEW',OUT)
