"""Write reusable scenery recipes and a small, isolated Godot review project."""
import argparse
import json
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "art/dressing/bone-decor-v1"
parser = argparse.ArgumentParser()
parser.add_argument("--workspace", type=Path, required=True)
args = parser.parse_args()
OUTPUT = args.workspace / "build/local-bone-decor-v1"
catalog = json.loads((ART / "catalog.json").read_text(encoding="utf-8"))
families = {entry["name"]: entry["family"] for entry in catalog["assets"]}
DIR = "res://art/dressing/bone-decor-v1/"

for family in ["halloween", "skeletons"]:
    text = f'''[gd_resource type="StandardMaterial3D" load_steps=3 format=3]
[ext_resource type="Texture2D" path="{DIR}texture-{family}.png" id="1"]
[ext_resource type="Texture2D" path="res://art/third-party/kaykit-dungeon-remastered/grain-floor1.png" id="2"]
[resource]
albedo_texture = ExtResource("1")
roughness = 1.0
metallic_specular = 0.1
texture_filter = 2
detail_enabled = true
detail_albedo = ExtResource("2")
detail_blend_mode = 3
detail_uv_layer = 1
uv2_triplanar = true
uv2_world_triplanar = true
uv2_scale = Vector3(0.5, 0.5, 0.5)
'''
    (ART / ("material-" + family + ".tres")).write_text(text, encoding="utf-8")

recipes = {
    "scattered-bones": [
        ("bone_A", (-.15, 0, 0), 18), ("bone_A", (.12, 0, .10), -30),
        ("bone_B", (-.16, 0, .22), -65), ("bone_B", (.20, 0, -.12), 72)],
    "small-remains": [
        ("skull", (0, 0, -.37), 12), ("ribcage", (0, 0, -.04), 0),
        ("bone_A", (-.13, 0, .29), 78), ("bone_A", (.12, 0, .33), 102),
        ("bone_B", (-.26, 0, -.07), 40)],
    "fallen-skeleton": [("skeleton-fallen", (0, 0, 0), 15)],
    "seated-skeleton": [("skeleton-seated", (0, 0, 0), 0)],
}
for name, entries in recipes.items():
    models = list(dict.fromkeys(entry[0] for entry in entries))
    family = families[models[0]]
    resources = ['[ext_resource type="Script" path="' + DIR + 'appearance.gd" id="script"]',
                 '[ext_resource type="Material" path="' + DIR + 'material-' + family + '.tres" id="material"]']
    for index, model in enumerate(models):
        resources.append('[ext_resource type="PackedScene" path="' + DIR + model + '.glb" id="m' + str(index) + '"]')
    nodes = ['[node name="BoneDecor" type="Node3D"]', 'script = ExtResource("script")',
             'appearance = ExtResource("material")']
    for index, (model, position, yaw) in enumerate(entries):
        nodes += ['', '[node name="Piece' + str(index) + '" parent="." instance=ExtResource("m' + str(models.index(model)) + '")]',
                  'position = Vector3(' + ", ".join(str(value) for value in position) + ')',
                  'rotation_degrees = Vector3(0, ' + str(yaw) + ', 0)']
    scene = '[gd_scene load_steps=' + str(len(resources)+1) + ' format=3]\n' + "\n".join(resources) + "\n\n" + "\n".join(nodes) + "\n"
    (ART / (name + ".tscn")).write_text(scene, encoding="utf-8")

OUTPUT.mkdir(parents=True, exist_ok=True)
target = OUTPUT / "art/dressing/bone-decor-v1"
target.mkdir(parents=True, exist_ok=True)
for path in ART.iterdir():
    if path.is_file():
        shutil.copy2(path, target / path.name)
dependencies = ["art/third-party/kaykit-dungeon-remastered/grain-floor1.png",
                "art/textures/cave-v1/floor.png", "art/textures/cave-v1/wall.png"]
for relative in dependencies:
    target = OUTPUT / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / relative, target)
for name in ["review.gd", "check.gd"]:
    shutil.copy2(Path(__file__).with_name(name), OUTPUT / name)
(OUTPUT / "recipes.json").write_text(json.dumps(list(recipes), indent=2)+"\n", encoding="utf-8")
(OUTPUT / "project.godot").write_text('''config_version=5
[application]
config/name="Depths / bone scenery review"
run/main_scene="res://review.tscn"
[display]
window/size/viewport_width=1278
window/size/viewport_height=590
[input_devices]
pointing/emulate_touch_from_mouse=true
[rendering]
renderer/rendering_method="mobile"
rendering_device/driver.windows="d3d12"
''', encoding="utf-8")
(OUTPUT / "review.tscn").write_text('''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://review.gd" id="1"]
[node name="BoneReview" type="Control"]
layout_mode=3
anchors_preset=15
anchor_right=1.0
anchor_bottom=1.0
grow_horizontal=2
grow_vertical=2
script=ExtResource("1")
''', encoding="utf-8")
exe = args.workspace / "build/research-godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe"
(OUTPUT / "START_REVIEW.cmd").write_text('@echo off\n"' + str(exe) + '" --path "%~dp0." %*\n', encoding="utf-8")
print("BONE_REVIEW_PREPARED", OUTPUT)
