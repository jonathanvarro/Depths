"""Export first-pass #257 fortress characters with the established roster helpers."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
sys.dont_write_bytecode = True
sys.path.insert(0,str(ROOT/"tools/combat_roster"))
sys.path.insert(0,str(Path(__file__).resolve().parent))
from build_roster import PALETTE, activate, fit_floor, goblin_clips, make_action, open_master, rotate
from enemies import fit_goblin
from mesh_parts import Mesh, prior_colours, set_uv
from king import create_king

ART = ROOT/"art/enemies/fortress-goblins-3d-v1"
ROSTER = "res://art/enemies/combat-roster-3d-v1/"
LOCAL = "res://art/enemies/fortress-goblins-3d-v1/"
LABELS = {
    "fortress-goblin":"Fortress goblin",
    "fortress-guard":"Fortress guard",
    "fortress-archer":"Fortress archer",
    "goblin-king":"Goblin King",
}


def recolour(obj):
    palette = prior_colours(obj.data,PALETTE)
    shades = {"cloth_light":"cloth","cloth":"leather"}
    set_uv(obj.data,PALETTE,[shades.get(c,c) for c in palette])


def aim_archer(rig):
    baseline={bone.name:bone.matrix_basis.copy() for bone in rig.pose.bones}
    arms={}
    for side in "LR":
        arms[side]=[rig.pose.bones[piece+"_"+side].matrix.copy() for piece in ("upperarm","forearm","hand")]
    local=rig.matrix_world.inverted()
    targets={"L":local@Vector((.42,-.154,.995)), "R":local@Vector((-.092,-.20,1.055))}
    poles={"L":local@Vector((.35,-.054,.82)), "R":local@Vector((-.45,.013,.98))}

    def aim(arm, amount):
        for side,(upper,lower,grip) in arms.items():
            shoulder,elbow,wrist=upper.translation,lower.translation,grip.translation
            top_length=(elbow-shoulder).length
            lower_length=(wrist-elbow).length
            end=wrist.lerp(targets[side],amount)
            along=(end-shoulder).normalized()
            reach=min((end-shoulder).length,(top_length+lower_length)*.996)
            length=(top_length**2-lower_length**2+reach**2)/(2*reach)
            pole=elbow.lerp(poles[side],amount)-shoulder
            bend=(pole-along*pole.dot(along)).normalized()
            hinge=shoulder+length*along+math.sqrt(max(0,top_length**2-length**2))*bend
            end=shoulder+reach*along
            for key,matrix,origin,source,target in (
                ("upperarm",upper,shoulder,elbow-shoulder,hinge-shoulder),
                ("forearm",lower,hinge,wrist-elbow,end-hinge),
            ):
                turn=source.normalized().rotation_difference(target.normalized())
                posed=turn.to_matrix().to_4x4()@matrix
                posed.translation=origin
                arm.pose.bones[key+"_"+side].matrix=posed
                bpy.context.view_layer.update()
            hand=grip.copy()
            hand.translation=end
            arm.pose.bones["hand_"+side].matrix=hand
            bpy.context.view_layer.update()
        rotate(arm.pose.bones["head"],(0,-2*amount,9*amount))
    make_action(rig,"draw",baseline,[(0,0),(5,.58),(10,1),(15,1),(20,0)],aim)
    make_action(rig,"attack",baseline,[(0,0),(7,.83),(10,1),(12,.68),(19,0)],aim)


def fortress_goblin(name, workspace):
    rig = open_master(workspace/"build/local-spiders-goblin-v1/masters/goblin.blend")
    body = bpy.data.objects["GoblinBody"]
    details, equipment = Mesh(), Mesh()
    if name=="fortress-archer":
        costume, bow = fit_goblin("goblin-archer",rig,body,PALETTE)
        bpy.data.objects.remove(bpy.data.objects["Knife"],do_unlink=True)
        aim_archer(rig)
        activate(rig,bpy.data.actions["idle"],0)
        details.loft([(1.051,.154,.106,.005,-.024),(1.14,.168,.14,-.006,-.042),
                      (1.238,.139,.138,-.011,-.069),(1.294,.096,.092,-.027,-.061),
                      (1.325,.039,.044,-.047,-.026)],
                     "head","deep_olive","moss",10,twist=.13)
        details.panel([(-.145,1.143),(-.086,1.24),(-.027,1.27),(.071,1.238),
                       (.137,1.13),(.066,1.149),(-.002,1.168),(-.068,1.156)],
                      -.168,.028,"head","moss","deep_olive")
        details.panel([(-.152,1.121),(-.089,1.151),(-.074,1.098),(-.14,1.019)],
                      -.13,.035,"head","deep_olive","charcoal")
        details.panel([(.090,1.147),(.154,1.118),(.142,1.028),(.082,1.092)],
                      -.136,.035,"head","moss","deep_olive")
        details.loft([(.834,.205,.125,0,.041),(.946,.20,.136,0,.053),
                      (1.013,.106,.107,0,.025)],"spine4","deep_olive","moss",9,twist=.15)
        meshes = [body,costume,bow,details.finish("Hood",rig,PALETTE)]
    elif name=="fortress-guard":
        recolour(body)
        for old in ("Knife","Buckler"):
            bpy.data.objects.remove(bpy.data.objects[old],do_unlink=True)
        details.loft([(1.031,.176,.14,0,-.046),(1.121,.18,.146,-.007,-.063),
                      (1.201,.162,.134,-.008,-.055),(1.257,.084,.086,-.017,-.052)],
                     "head","iron","iron_edge",10,twist=.11)
        details.panel([(-.04,1.211),(.049,1.235),(.034,1.426),(-.018,1.392),(-.058,1.265)],
                      -.103,.092,"head","steel_dark","iron_edge")
        for sign in (-1,1):
            details.panel([(sign*.094,1.105),(sign*.158,1.139),(sign*.167,1.012),
                           (sign*.119,.985)],-.153,.032,"head","iron","steel_dark")
        # Circular planks with a shallow iron boss, visible from the overhead camera.
        axis=(.09,-.89,.32)
        origin=(.125,-.222,.656)
        equipment.loft([(0,.273,.273,0,0),(.043,.278,.274,0,0),(.067,.262,.268,0,0)],
                       "hand_L","iron","steel",14,axis,origin,.035)
        equipment.loft([(.065,.242,.249,0,0),(.075,.247,.250,0,0)],"hand_L",
                       "wood","wood_light",14,axis,origin,.024)
        equipment.loft([(.075,.084,.081,0,0),(.114,.069,.066,0,0),(.148,.032,.034,0,0)],
                       "hand_L","iron","iron_edge",9,axis,origin,.07)
        for i in range(7):
            a=i*math.tau/7
            equipment.stone((origin[0]+.253*math.cos(a),-.291,origin[2]+.251*math.sin(a)),
                            (.016,.013,.015),"hand_L","iron_edge","steel",5)
        grip=rig.matrix_world@rig.pose.bones["hand_R"].head
        end=tuple(grip+Vector((-.105,-.098,-.30)))
        equipment.segment(grip,end,[(0,.029),(.65,.039),(1,.041)],
                          "hand_R","wood_dark","leather_light")
        equipment.stone(end,(.067,.053,.095),"hand_R","iron","iron_edge",7)
        goblin_clips(rig,"goblin-guard")
        meshes=[body,details.finish("Crest",rig,PALETTE),equipment.finish("RoleKit",rig,PALETTE)]
    else:
        for obj in (body,bpy.data.objects["Knife"],bpy.data.objects["Buckler"]):
            recolour(obj)
        for side,sign in (("L",1),("R",-1)):
            for band in range(2):
                z=.112+.058*band
                details.loft([(z,.078,.093,.145*sign,.036-.011*band),
                              (z+.043,.081,.087,.148*sign,.026-.011*band)],
                             "lowerleg_"+side,"leather","leather_light",8,twist=.11)
        details.panel([(-.132,.591),(.122,.584),(.151,.408),(.064,.438),
                       (.040,.369),(-.106,.413)],-.056,.025,
                      "spine2","cloth_dark","cloth_light")
        meshes=[body,details.finish("Wraps",rig,PALETTE)]
    meshes.extend(obj for obj in rig.children if obj.type=="MESH" and obj not in meshes)
    return rig,meshes


def export(name, rig, meshes, output):
    clips=fit_floor(rig,meshes)
    activate(rig,bpy.data.actions["idle"],0)
    bpy.context.scene.render.fps=24
    for obj in list(bpy.context.scene.objects):
        if obj.type in ("CAMERA","LIGHT"):
            bpy.data.objects.remove(obj,do_unlink=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(output/"masters"/(name+".blend")))
    bpy.ops.object.select_all(action="DESELECT")
    for obj in ([rig.parent] if rig.parent else [])+[rig,*meshes]:
        obj.select_set(True)
    bpy.context.view_layer.objects.active=rig
    target=ART/(name+".glb")
    bpy.ops.export_scene.gltf(filepath=str(target),export_format="GLB",use_selection=True,
        export_materials="NONE",export_animations=True,export_animation_mode="ACTIONS",
        export_frame_range=False,export_anim_slide_to_zero=True,export_force_sampling=True,
        export_frame_step=1,export_current_frame=False,export_rest_position_armature=True,
        export_all_influences=True,export_influence_nb=8,export_cameras=False,export_lights=False)
    counts={}
    for mesh in meshes:
        mesh.data.calc_loop_triangles()
        counts[mesh.name]=len(mesh.data.loop_triangles)
    height=clips["idle"]["high"][2]
    actor=LOCAL if name=="goblin-king" else ROSTER
    (ART/(name+".tscn")).write_text(
        '[gd_scene load_steps=4 format=3]\n'
        f'[ext_resource type="Script" path="{actor}actor.gd" id="1"]\n'
        f'[ext_resource type="Material" path="{ROSTER}palette.tres" id="2"]\n'
        f'[ext_resource type="PackedScene" path="{LOCAL}{name}.glb" id="3"]\n'
        '[node name="Actor" type="Node3D"]\nscript=ExtResource("1")\npalette_material=ExtResource("2")\n'
        f'metadata/visual_height={height}\n'
        '[node name="Model" parent="." instance=ExtResource("3")]\n',encoding="utf-8")
    print("FORTRESS",name,sum(counts.values()),height,flush=True)
    return {"id":name,"label":LABELS[name],"triangles":sum(counts.values()),"surfaces":counts,
            "bones":len(rig.data.bones),"height":height,"clips":clips,"front":"+Z",
            "sha256":hashlib.sha256(target.read_bytes()).hexdigest()}


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--workspace",type=Path,required=True)
    args=parser.parse_args(sys.argv[sys.argv.index("--")+1:])
    output=args.workspace/"build/local-fortress-goblins-3d-v1"
    (output/"masters").mkdir(parents=True,exist_ok=True)
    assets=[]
    for name in LABELS:
        rig,meshes=create_king(PALETTE) if name=="goblin-king" else fortress_goblin(name,args.workspace)
        assets.append(export(name,rig,meshes,output))
    (ART/"catalog.json").write_text(json.dumps({"assets":assets},indent=2)+"\n",encoding="utf-8")


if __name__=="__main__":
    main()
