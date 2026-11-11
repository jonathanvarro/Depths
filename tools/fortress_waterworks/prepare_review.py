"""Compose #246 pieces and prepare an isolated Mobile-renderer inspection."""
import argparse
import json
from pathlib import Path
import shutil
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/props/fortress-waterworks-3d-v1'
parser=argparse.ArgumentParser()
parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args()
OUTPUT=args.workspace/'build/local-fortress-waterworks-v1'
catalog=json.loads((ART/'catalog.json').read_text(encoding='utf-8'))
DIR='res://art/props/fortress-waterworks-3d-v1/'
image=Image.new('RGB',(256,128),'#383d3c')
for i,colour in enumerate(catalog['palette'].values()):
    x,y=i%8*32,(3-i//8)*32
    image.paste('#'+colour,(x,y,x+32,y+32))
image.save(ART/'palette.png')
material=(ROOT/'art/dressing/mine-3d-v1/palette.tres').read_text(encoding='utf-8')
(ART/'palette.tres').write_text(material.replace('art/dressing/mine-3d-v1/palette.png',
    'art/props/fortress-waterworks-3d-v1/palette.png'),encoding='utf-8')
def vector(values): return 'Vector3('+','.join(str(v) for v in values)+')'
for entry in catalog['recipes']:
    resources=[f'[ext_resource type="Script" path="{DIR}prop.gd" id="script"]',
               f'[ext_resource type="Material" path="{DIR}palette.tres" id="palette"]']
    for model in dict.fromkeys(entry['parts'].values()):
        resources.append(f'[ext_resource type="PackedScene" path="{DIR}{model}.glb" id="{model}"]')
    nodes=['[node name="Structure" type="Node3D"]','script=ExtResource("script")',
           'palette_material=ExtResource("palette")',f'metadata/asset_id="{entry["id"]}"',
           f'metadata/mount="{entry["mount"]}"']
    if 'lift' in entry:
        nodes.extend(['lift_metres='+str(entry['lift']),'lift_origin='+vector(entry['lift_origin']),
            'spin_axis='+vector(entry['spin_axis']),'','[node name="Lift" type="Node3D" parent="."]',
            'position='+vector(entry['lift_origin']),'','[node name="Wheel" type="Node3D" parent="."]',
            'position='+vector(entry['wheel_origin'])])
    for node,model in entry['parts'].items():
        parent,child=node.split('/') if '/' in node else ('.',node)
        nodes.extend(['',f'[node name="{child}" parent="{parent}" instance=ExtResource("{model}")]'])
        if node=='Spent': nodes.append('visible=false')
    (ART/(entry['id']+'.tscn')).write_text(f'[gd_scene load_steps={len(resources)+1} format=3]\n'+'\n'.join(resources)+'\n\n'+'\n'.join(nodes)+'\n',encoding='utf-8')
for path in ART.iterdir():
    if path.is_file():
        target=OUTPUT/'art/props/fortress-waterworks-3d-v1'/path.name
        target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(path,target)
files=['art/third-party/kaykit-dungeon-remastered/grain-floor1.png',
       'art/textures/waterworks-v1/wet-plain.png',
       'art/textures/descent-surfaces-v1/drowned-masonry-floor.png',
       'art/textures/descent-surfaces-v1/drowned-masonry-ceiling.png']
files.extend('art/textures/fortress-v1/'+name+'.png' for name in ['wall','floor','ceiling'])
for relative in files:
    target=OUTPUT/relative
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(ROOT/relative,target)
for name in ['review.gd','check.gd']: shutil.copy2(Path(__file__).with_name(name),OUTPUT/name)
(OUTPUT/'project.godot').write_text('''config_version=5
[application]
config/name="Depths / fortress and waterworks"
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
[node name="FortressWaterworksReview" type="Control"]
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
print('FORTRESS_WATERWORKS_REVIEW',OUTPUT)
