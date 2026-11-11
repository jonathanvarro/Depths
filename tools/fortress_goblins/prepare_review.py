"""Prepare an isolated native review that can run without opening the game."""
import argparse
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TOOL = Path(__file__).resolve().parent
parser = argparse.ArgumentParser()
parser.add_argument("--workspace",type=Path,required=True)
parser.add_argument("--review-output",type=Path)
args = parser.parse_args()
out = args.review_output or args.workspace/"build/local-fortress-goblins-3d-v1"
out.mkdir(parents=True,exist_ok=True)

for path in ("art/enemies/fortress-goblins-3d-v1","art/enemies/combat-roster-3d-v1",
             "art/props/treatment-supplies-v1"):
    shutil.copytree(ROOT/path,out/path,dirs_exist_ok=True)
for path in ("art/textures/cave-v1/floor.png","art/third-party/kaykit-dungeon-remastered/grain-floor1.png"):
    target = out/path
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(ROOT/path,target)
for name in ("review.gd","check.gd","check_polish.gd"):
    shutil.copy2(TOOL/name,out/name)
(out/"project.godot").write_text('''config_version=5
[application]
config/name="Depths / Fortress goblins review"
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
[importer_defaults]
scene={
"animation/fps": 24
}
''',encoding="utf-8")
(out/"review.tscn").write_text('''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://review.gd" id="1"]
[node name="RosterReview" type="Control"]
layout_mode=3
anchors_preset=15
anchor_right=1.0
anchor_bottom=1.0
grow_horizontal=2
grow_vertical=2
script=ExtResource("1")
''',encoding="utf-8")
godot = args.workspace/"build/research-godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe"
(out/"START_REVIEW.cmd").write_text(f'@echo off\n"{godot}" --path "%~dp0." %*\n',encoding="utf-8")
