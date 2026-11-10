import argparse,json,shutil
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser();parser.add_argument('--workspace',type=Path,required=True);args=parser.parse_args()
OUT=args.workspace/'build/local-rat-landmarks-v1'
ART=ROOT/'art/props/shrine-events-3d-v1'
catalog=json.loads((ART/'catalog.json').read_text())
image=Image.new('RGB',(256,128))
for i,c in enumerate(catalog['palette'].values()):
    x,y=i%8*32,(3-i//8)*32;image.paste('#'+c,(x,y,x+32,y+32))
image.save(ART/'palette.png')
(ART/'palette.tres').write_text((ROOT/'art/dressing/mine-3d-v1/palette.tres').read_text().replace('art/dressing/mine-3d-v1/palette.png','art/props/shrine-events-3d-v1/palette.png'))
for name,parts in catalog['recipes'].items():
    prefix='res://art/props/shrine-events-3d-v1/'
    resources=[f'[ext_resource type="Script" path="{prefix}prop.gd" id="script"]',f'[ext_resource type="Material" path="{prefix}palette.tres" id="palette"]']
    for model in parts:resources.append(f'[ext_resource type="PackedScene" path="{prefix}{model}.glb" id="{model}"]')
    text='[gd_scene load_steps=6 format=3]\n'+'\n'.join(resources)+'\n[node name="Landmark" type="Node3D"]\nscript=ExtResource("script")\npalette_material=ExtResource("palette")\n'
    for node,model in zip(['Base','Fresh','Spent'],parts):
        text+=f'[node name="{node}" parent="." instance=ExtResource("{model}")]\n'
        if node=='Spent':text+='visible=false\n'
    (ART/(name+'.tscn')).write_text(text)
for folder in ['art/enemies/rat-3d-v1','art/props/shrine-events-3d-v1']:
    shutil.copytree(ROOT/folder,OUT/folder,dirs_exist_ok=True)
for relative in ['art/third-party/kaykit-dungeon-remastered/grain-floor1.png','art/textures/cave-v1/floor.png','art/textures/cave-v1/wall.png']:
    target=OUT/relative;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/relative,target)
for name in ['review.gd','check.gd']:
    source=Path(__file__).with_name(name)
    if source.exists():shutil.copy2(source,OUT/name)
(OUT/'project.godot').write_text('''config_version=5
[application]
config/name="Depths / rat and landmarks"
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
''')
(OUT/'review.tscn').write_text('''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://review.gd" id="1"]
[node name="RatLandmarksReview" type="Control"]
layout_mode=3
anchors_preset=15
anchor_right=1.0
anchor_bottom=1.0
grow_horizontal=2
grow_vertical=2
script=ExtResource("1")
''')
exe=args.workspace/'build/research-godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe'
(OUT/'START_REVIEW.cmd').write_text('@echo off\n"'+str(exe)+'" --path "%~dp0." %*\n')
print('REVIEW_PREPARED',OUT)
