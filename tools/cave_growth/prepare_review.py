"""Write metric decor scenes and an isolated native Mobile review."""
import argparse
import json
from pathlib import Path
import shutil
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/dressing/cave-growth-3d-v1'
parser=argparse.ArgumentParser()
parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args()
OUTPUT=args.workspace/'build/local-cave-growth-v1'
catalog=json.loads((ART/'catalog.json').read_text(encoding='utf-8'))
image=Image.new('RGB',(256,128),'#383d3c')
for i,colour in enumerate(catalog['palette'].values()):
    x,y=i%8*32,(3-i//8)*32
    image.paste('#'+colour,(x,y,x+32,y+32))
image.save(ART/'palette.png')
text=(ROOT/'art/dressing/mine-3d-v1/palette.tres').read_text(encoding='utf-8')
(ART/'palette.tres').write_text(text.replace('art/dressing/mine-3d-v1/palette.png',
                                         'art/dressing/cave-growth-3d-v1/palette.png'),encoding='utf-8')
DIR='res://art/dressing/cave-growth-3d-v1/'
for entry in catalog['assets']:
    name=entry['id']
    text=f'''[gd_scene load_steps=4 format=3]
[ext_resource type="Script" path="{DIR}appearance.gd" id="script"]
[ext_resource type="Material" path="{DIR}palette.tres" id="palette"]
[ext_resource type="PackedScene" path="{DIR}{name}.glb" id="model"]
[node name="CaveGrowth" type="Node3D"]
script=ExtResource("script")
palette_material=ExtResource("palette")
metadata/asset_id="{name}"
metadata/mount="{entry['mount']}"
[node name="Model" parent="." instance=ExtResource("model")]
'''
    (ART/(name+'.tscn')).write_text(text,encoding='utf-8')
for path in ART.iterdir():
    if path.is_file():
        target=OUTPUT/'art/dressing/cave-growth-3d-v1'/path.name
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
config/name="Depths / cave formations and growth"
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
[node name="CaveReview" type="Control"]
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
print('CAVE_REVIEW',OUTPUT)
