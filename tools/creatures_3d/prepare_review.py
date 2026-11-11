import argparse,json,shutil
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser();parser.add_argument('--workspace',type=Path,required=True);args=parser.parse_args()
OUT=args.workspace/'build/local-spiders-goblin-v1';OUT.mkdir(parents=True,exist_ok=True)
ART=ROOT/'art/enemies/field-creatures-3d-v1';catalog=json.loads((ART/'catalog.json').read_text(encoding='utf-8'))
image=Image.new('RGB',(256,128))
for i,c in enumerate(catalog['palette'].values()):
    x,y=i%8*32,(3-i//8)*32;image.paste('#'+c,(x,y,x+32,y+32))
image.save(ART/'palette.png')
material=(ROOT/'art/dressing/mine-3d-v1/palette.tres').read_text(encoding='utf-8').replace('art/dressing/mine-3d-v1/palette.png','art/enemies/field-creatures-3d-v1/palette.png')
(ART/'palette.tres').write_text(material,encoding='utf-8')
for entry in catalog['assets']:
    name=entry['id'];height=1.30 if name=='goblin' else .5
    local_import=OUT/'art/enemies/field-creatures-3d-v1'/(name+'.glb.import')
    native_import=ART/(name+'.glb.import')
    if local_import.exists() and not native_import.exists():shutil.copy2(local_import,native_import)
    if native_import.exists():native_import.write_text(native_import.read_text(encoding='utf-8').replace('animation/fps=30','animation/fps=24'),encoding='utf-8')
    (ART/(name+'.tscn')).write_text(f'''[gd_scene load_steps=4 format=3]
[ext_resource type="Script" path="res://art/enemies/field-creatures-3d-v1/actor.gd" id="1"]
[ext_resource type="Material" path="res://art/enemies/field-creatures-3d-v1/palette.tres" id="2"]
[ext_resource type="PackedScene" path="res://art/enemies/field-creatures-3d-v1/{name}.glb" id="3"]
[node name="Creature" type="Node3D"]
script=ExtResource("1")
palette_material=ExtResource("2")
metadata/visual_height={height}
[node name="Model" parent="." instance=ExtResource("3")]
''',encoding='utf-8')
shutil.copytree(ART,OUT/'art/enemies/field-creatures-3d-v1',dirs_exist_ok=True)
for relative in ['art/third-party/kaykit-dungeon-remastered/grain-floor1.png','art/textures/cave-v1/floor.png','art/textures/cave-v1/wall.png']:
    target=OUT/relative;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/relative,target)
rat=args.workspace/'build/rat-landmarks-3d-checkout/art/enemies/rat-3d-v1'
if rat.exists():shutil.copytree(rat,OUT/'art/enemies/rat-3d-v1',dirs_exist_ok=True)
for name in ['review.gd','check.gd']:
    path=Path(__file__).with_name(name)
    if path.exists():shutil.copy2(path,OUT/name)
(OUT/'project.godot').write_text('''config_version=5
[application]
config/name="Depths / spiders and goblin review"
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
(OUT/'review.tscn').write_text('''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://review.gd" id="1"]
[node name="CreatureReview" type="Control"]
layout_mode=3
anchors_preset=15
anchor_right=1.0
anchor_bottom=1.0
grow_horizontal=2
grow_vertical=2
script=ExtResource("1")
''',encoding='utf-8')
exe=args.workspace/'build/research-godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe'
(OUT/'START_REVIEW.cmd').write_text('@echo off\n"'+str(exe)+'" --path "%~dp0." %*\n',encoding='utf-8')
print('CREATURE_REVIEW',OUT)
