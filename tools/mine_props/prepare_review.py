"""Write shared materials, reusable scenes and the isolated native art review."""
import argparse
import json
from pathlib import Path
import shutil
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/dressing/mine-3d-v1'
parser=argparse.ArgumentParser()
parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args()
OUTPUT=args.workspace/'build/local-mine-props-v1'
(OUTPUT/'masters/.gdignore').write_text('', encoding='utf-8')
catalog=json.loads((ART/'catalog.json').read_text(encoding='utf-8'))
image=Image.new('RGB',(256,128),'#383d3c')
for index,colour in enumerate(catalog['palette'].values()):
    left,top=(index%8)*32,(3-index//8)*32
    image.paste('#'+colour,(left,top,left+32,top+32))
image.save(ART/'palette.png')
DIR='res://art/dressing/mine-3d-v1/'
(ART/'palette.tres').write_text('''[gd_resource type="StandardMaterial3D" load_steps=3 format=3]
[ext_resource type="Texture2D" path="res://art/dressing/mine-3d-v1/palette.png" id="1"]
[ext_resource type="Texture2D" path="res://art/third-party/kaykit-dungeon-remastered/grain-floor1.png" id="2"]
[resource]
albedo_texture=ExtResource("1")
roughness=1.0
metallic_specular=0.1
texture_filter=2
detail_enabled=true
detail_albedo=ExtResource("2")
detail_blend_mode=3
detail_uv_layer=1
uv2_triplanar=true
uv2_world_triplanar=true
uv2_scale=Vector3(0.5,0.5,0.5)
''',encoding='utf-8')
for name in ['support','support-damaged','lantern-standing','lantern-hanging','miners-shrine']:
    resources=[f'[ext_resource type="Script" path="{DIR}prop.gd" id="script"]',
               f'[ext_resource type="Material" path="{DIR}palette.tres" id="material"]']
    models=['shrine-base','offerings-fresh','offerings-spent'] if name=='miners-shrine' else [name]
    for model in models:
        resources.append(f'[ext_resource type="PackedScene" path="{DIR}{model}.glb" id="{model}"]')
    nodes=['[node name="MineProp" type="Node3D"]','script=ExtResource("script")',
           'palette_material=ExtResource("material")']
    if name=='miners-shrine':
        nodes.extend(['','[node name="Base" parent="." instance=ExtResource("shrine-base")]','',
            '[node name="Fresh" parent="." instance=ExtResource("offerings-fresh")]','',
            '[node name="Spent" parent="." instance=ExtResource("offerings-spent")]','visible=false','',
            '[node name="Flames" type="Node3D" parent="."]'])
        resources.append('[sub_resource type="CylinderMesh" id="flame"]\ntop_radius=0.0\nbottom_radius=0.009\nheight=0.032\nradial_segments=6\nrings=1')
        for index,position in enumerate(catalog['candle_flames']):
            x,y,z=position
            nodes.extend(['',f'[node name="Flame{index}" type="MeshInstance3D" parent="Flames"]',
                          f'position=Vector3({x},{y+.016},{z})','mesh=SubResource("flame")'])
    else:
        nodes.extend(['',f'[node name="Model" parent="." instance=ExtResource("{name}")]'])
    text=f'[gd_scene load_steps={len(resources)+1} format=3]\n'+'\n'.join(resources)+'\n\n'+'\n'.join(nodes)+'\n'
    (ART/(name+'.tscn')).write_text(text,encoding='utf-8')

dependencies=['art/third-party/kaykit-dungeon-remastered/grain-floor1.png',
              'art/textures/cave-v1/floor.png','art/textures/cave-v1/wall.png',
              'art/textures/cave-v1/ceiling.png']
for path in ART.iterdir():
    if path.is_file():
        target=OUTPUT/'art/dressing/mine-3d-v1'/path.name
        target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(path,target)
for relative in dependencies:
    target=OUTPUT/relative
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(ROOT/relative,target)
for name in ['review.gd','check.gd']:
    shutil.copy2(Path(__file__).with_name(name),OUTPUT/name)
(OUTPUT/'project.godot').write_text('''config_version=5
[application]
config/name="Depths / mine props review"
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
[node name="MineReview" type="Control"]
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
print('Prepared',OUTPUT)
