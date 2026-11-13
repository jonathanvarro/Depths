"""Author and export #251 combat-board model candidates in Blender 5.2."""
import argparse
import hashlib
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Quaternion, Vector

sys.dont_write_bytecode = True
sys.path.insert(0,str(Path(__file__).resolve().parent))
from enemies import GOBLINS, fit_broodmother, fit_goblin, fit_great_rat
from mesh_parts import EXTRA, palette_png
from party import HEROES, make_hero

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT/"art/enemies/combat-roster-3d-v1"
PRIOR = ROOT/"art/enemies/field-creatures-3d-v1"
PALETTE = json.loads((PRIOR/"catalog.json").read_text(encoding="utf-8"))["palette"] | EXTRA
IDS = ("great-rat",*GOBLINS,"broodmother",*HEROES)
LABELS = {
    "great-rat":"Great rat", "goblin-archer":"Goblin archer", "goblin-guard":"Goblin guard",
    "goblin-drummer":"Goblin drummer", "goblin-trapper":"Goblin trapper",
    "goblin-queen":"Goblin Queen", "broodmother":"Broodmother",
} | {name:entry[-1] for name,entry in HEROES.items()}


def activate(rig, action, frame):
    rig.animation_data.action = action
    rig.animation_data.action_slot = action.slots[0]
    # Some inherited Actions have no object rotation channel. Blender would
    # otherwise keep the transform left by the last Action we sampled.
    rig.rotation_mode = "QUATERNION"
    rig.rotation_quaternion = (1,0,0,0)
    rig.location = (0,0,0)
    rig.scale = (1,1,1)
    bpy.context.scene.frame_set(frame)
    bpy.context.view_layer.update()


def rotate(bone, degrees):
    basis = bone.bone.matrix_local.to_quaternion()
    for axis, angle in zip(((1,0,0),(0,1,0),(0,0,1)), degrees, strict=True):
        if angle:
            bone.rotation_quaternion = (
                bone.rotation_quaternion @ Quaternion(basis.inverted() @ Vector(axis), math.radians(angle))
            )


def make_action(rig, name, baseline, keys, motion):
    old = bpy.data.actions.get(name)
    if old:
        bpy.data.actions.remove(old)
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    rig.animation_data.action = action
    for frame, value in keys:
        for bone in rig.pose.bones:
            bone.rotation_mode = "QUATERNION"
            bone.matrix_basis = baseline[bone.name]
        rig.location = (0,0,0)
        rig.rotation_mode = "QUATERNION"
        rig.rotation_quaternion = (1,0,0,0)
        motion(rig,value)
        for bone in rig.pose.bones:
            for prop in ("location","rotation_quaternion","scale"):
                bone.keyframe_insert(prop,frame=frame,group=bone.name)
        for prop in ("location","rotation_quaternion"):
            rig.keyframe_insert(prop,frame=frame)


def make_party_clips(rig, name):
    rig.animation_data_create()
    baseline = {bone.name:bone.matrix_basis.copy() for bone in rig.pose.bones}

    def idle(arm, amount):
        rotate(arm.pose.bones["spine"],(-2*amount,0,1.5*amount))
        rotate(arm.pose.bones["head"],(0,0,-3*amount))
        for side, sign in (("L",1),("R",-1)):
            rotate(arm.pose.bones["upperarm_"+side],(2*amount,sign*amount,0))

    def attack(arm, amount):
        primary = {"corin":(-56,12,-26), "mara":(-38,-9,-28),
                   "alwen":(-32,-20,-21), "recruit":(-48,18,-20)}[name]
        rotate(arm.pose.bones["spine"],(-12*amount,3*amount,-17*amount))
        rotate(arm.pose.bones["upperarm_R"],tuple(a*amount for a in primary))
        rotate(arm.pose.bones["forearm_R"],(-26*amount,3*amount,6*amount))
        rotate(arm.pose.bones["upperarm_L"],(-24*amount,-5*amount,10*amount))
        rotate(arm.pose.bones["head"],(6*amount,-4*amount,11*amount))

    def hurt(arm, amount):
        rotate(arm.pose.bones["spine"],(23*amount,-7*amount,12*amount))
        rotate(arm.pose.bones["head"],(14*amount,13*amount,-11*amount))
        rotate(arm.pose.bones["upperarm_L"],(-15*amount,30*amount,4*amount))
        rotate(arm.pose.bones["upperarm_R"],(10*amount,-22*amount,0))

    def fall(arm, amount):
        root = arm.pose.bones["root"]
        rotate(root,(81*amount,14*amount,-19*amount))
        rotate(arm.pose.bones["spine"],(8*amount,-8*amount,-13*amount))
        rotate(arm.pose.bones["upperarm_R"],(0,-31*amount,-15*amount))
        rotate(arm.pose.bones["upperarm_L"],(-10*amount,43*amount,0))
        rotate(arm.pose.bones["thigh_L"],(19*amount,0,0))
        rotate(arm.pose.bones["shin_R"],(-18*amount,0,0))
        arm.location = (0,.11*amount,-.50*amount)

    def walk(arm, amount):
        for side, sign in (("L",1),("R",-1)):
            rotate(arm.pose.bones["thigh_"+side],(27*amount*sign,0,0))
            rotate(arm.pose.bones["shin_"+side],(min(0,24*amount*sign),0,0))
            rotate(arm.pose.bones["upperarm_"+side],(-24*amount*sign,0,0))
        rotate(arm.pose.bones["spine"],(0,0,6*amount))

    def guard(arm, amount):
        rotate(arm.pose.bones["spine"],(-7*amount,0,9*amount))
        rotate(arm.pose.bones["upperarm_L"],(-43*amount,8*amount,-23*amount))
        rotate(arm.pose.bones["upperarm_R"],(-30*amount,-12*amount,11*amount))

    def cast(arm, amount):
        guard(arm,amount)
        rotate(arm.pose.bones["forearm_L"],(-30*amount,7*amount,-20*amount))
        rotate(arm.pose.bones["hand_R"],(4*amount,-12*amount,25*amount))
        rotate(arm.pose.bones["head"],(9*amount,0,-15*amount))

    clips = [
        ("idle",[(0,0),(12,1),(24,0),(36,-1),(48,0)],idle),
        ("attack",[(0,0),(4,-.30),(9,1),(13,.61),(20,0)],attack),
        ("hurt",[(0,0),(4,1),(8,.53),(13,0)],hurt),
        ("fall",[(0,0),(6,.18),(12,.58),(18,.93),(24,1)],fall),
        ("walk",[(0,0),(6,1),(12,0),(18,-1),(24,0)],walk),
        ("defend",[(0,0),(6,1),(15,1),(20,0)],guard),
    ]
    if name=="alwen":
        clips.append(("cast",[(0,0),(6,.40),(12,1),(17,.87),(24,0)],cast))
    for pose, keys, motion in clips:
        make_action(rig,pose,baseline,keys,motion)


def goblin_clips(rig, name):
    baseline = {bone.name:bone.matrix_basis.copy() for bone in rig.pose.bones}

    def pose(arm, amount):
        b = arm.pose.bones
        move = {
            "goblin-archer": {"upperarm_L":(-62,-9,5),"forearm_L":(18,-3,-5),
                             "upperarm_R":(-58,-35,-8),"forearm_R":(-37,23,-13),
                             "spine3":(0,-6,17),"head":(4,0,-13)},
            "goblin-guard": {"spine3":(-22,4,11),"upperarm_L":(-45,5,-12),
                            "forearm_L":(-13,9,5),"upperarm_R":(-29,3,4)},
            "goblin-drummer": {"spine3":(-8,5,0),"upperarm_L":(-25,9,-16),
                              "upperarm_R":(-37,-8,14),"forearm_L":(-42,0,8),
                              "forearm_R":(-36,0,-8),"head":(-10,1,-8)},
            "goblin-trapper": {"spine3":(-17,-4,-11),"upperarm_L":(-42,10,20),
                              "forearm_L":(-19,11,9),"upperarm_R":(14,-11,-4)},
            "goblin-queen": {"spine3":(-16,0,-18),"upperarm_R":(-92,-24,-39),
                            "forearm_R":(-19,13,3),"upperarm_L":(-21,33,4),
                            "head":(13,0,13)},
        }
        for bone, angles in move[name].items():
            rotate(b[bone],tuple(v*amount for v in angles))

    special = {"goblin-archer":"draw","goblin-guard":"brace","goblin-drummer":"drum",
               "goblin-trapper":"snare","goblin-queen":"enraged"}[name]
    keys = [(0,0),(5,.68),(9,1),(13,1),(19,0)]
    if name=="goblin-drummer":
        keys = [(0,0),(4,.90),(7,.23),(11,1),(15,.26),(19,.85),(24,0)]
    if name=="goblin-queen":
        keys = [(0,0),(5,-.33),(11,1),(15,.88),(21,0)]
    make_action(rig,special,baseline,keys,pose)
    if name in ("goblin-archer","goblin-drummer"):
        hits = [(0,0),(5,.70),(10,1),(12,.34),(19,0)] if name=="goblin-archer" else keys
        make_action(rig,"attack",baseline,hits,pose)
    elif name == "goblin-queen":
        def chop(arm, amount):
            pose(arm,amount)
            rotate(arm.pose.bones["spine4"],(-8*amount,0,21*amount))
            rotate(arm.pose.bones["hand_R"],(18*amount,24*amount,0))
        make_action(rig,"attack",baseline,[(0,0),(6,-.35),(9,.80),(12,1),(16,.45),(23,0)],chop)
        def topple(arm, amount):
            roll = Quaternion((0,1,0),math.radians(-72)*amount)
            turn = Quaternion((0,0,1),math.radians(27)*amount)
            arm.rotation_quaternion = turn @ roll
            arm.location = Vector((1.4,0,-4.5))*amount
            rotate(arm.pose.bones["spine3"],(9*amount,-12*amount,0))
            rotate(arm.pose.bones["upperarm_R"],(11*amount,-9*amount,-22*amount))
            rotate(arm.pose.bones["forearm_R"],(-28*amount,0,0))
            rotate(arm.pose.bones["upperleg_L"],(-18*amount,0,12*amount))
            rotate(arm.pose.bones["lowerleg_L"],(27*amount,0,0))
        make_action(rig,"fall",baseline,[(0,0),(5,.12),(11,.53),(18,.88),(25,1)],topple)


def spider_call(rig):
    baseline = {bone.name:bone.matrix_basis.copy() for bone in rig.pose.bones}
    def rear(arm, amount):
        rotate(arm.pose.bones["thorax"],(14*amount,0,0))
        rotate(arm.pose.bones["abdomen"],(-13*amount,0,0))
        for side, sign in (("L",1),("R",-1)):
            foot = arm.pose.bones["leg_A"+side]
            rest = foot.bone.matrix_local.to_3x3().inverted()
            foot.location += rest @ Vector((.37*sign, -.41, 2.21))*amount
        arm.rotation_quaternion = Quaternion((1,0,0), math.radians(6)*amount)
    make_action(rig,"call",baseline,[(0,0),(5,.46),(9,1),(13,.83),(18,.20),(23,0)],rear)

    def crumple(arm, amount):
        rotate(arm.pose.bones["thorax"],(-20*amount,0,0))
        rotate(arm.pose.bones["abdomen"],(10*amount,0,0))
        arm.rotation_quaternion = Quaternion((0,1,0), math.radians(9)*amount)
        bpy.context.view_layer.update()
        base = arm.pose.bones["base"]
        matrix = base.matrix.copy()
        matrix.translation += Vector((.26,-.65,-2.24))*amount
        base.matrix = matrix
        bpy.context.view_layer.update()
        for pair in "ABCD":
            for side in "LR":
                foot = arm.pose.bones["leg_"+pair+side]
                matrix = foot.matrix.copy()
                position = matrix.translation
                matrix.translation = (position.x*(1-.52*amount), position.y*(1-.25*amount),
                                      position.z+.32*amount)
                foot.matrix = matrix
                bpy.context.view_layer.update()
    make_action(rig,"fall",baseline,[(0,0),(5,.25),(11,.71),(19,1)],crumple)


def settle_fall(rig, meshes):
    """Fit the authored curled animal pose to a stable side at the endpoint."""
    action = bpy.data.actions["fall"]
    length = round(action.frame_range[1])
    activate(rig,action,length)
    original = rig.rotation_quaternion.copy()
    best = (float("inf"),Quaternion())
    for pitch in range(-60,61,15):
        for roll in range(-60,61,15):
            tilt = Quaternion((1,0,0),math.radians(pitch)) @ Quaternion((0,1,0),math.radians(roll))
            rig.rotation_quaternion = tilt @ original
            bpy.context.view_layer.update()
            points = points_for(meshes)
            spans = [max(p[i] for p in points)-min(p[i] for p in points) for i in range(3)]
            score = spans[2] + max(0,max(spans[:2])-1.95)*2 + (abs(pitch)+abs(roll))*.0008
            if score < best[0]:
                best = (score,tilt)
    rotations = []
    for frame in range(length+1):
        activate(rig,action,frame)
        amount = max(0,(frame/length-.44)/.56)
        rotations.append(Quaternion().slerp(best[1],amount) @ rig.rotation_quaternion)
    rig.rotation_mode = "QUATERNION"
    for frame,rotation in enumerate(rotations):
        rig.rotation_quaternion = rotation
        rig.keyframe_insert("rotation_quaternion",frame=frame)


def bake_constraints(rig):
    """Retain evaluated motion without relying on the glTF exporter's IK bake."""
    if not any(bone.constraints for bone in rig.pose.bones):
        return
    captured = {}
    for action in bpy.data.actions:
        samples = []
        for frame in range(round(action.frame_range[1])+1):
            activate(rig,action,frame)
            evaluated = rig.evaluated_get(bpy.context.evaluated_depsgraph_get())
            matrices = {bone.name:bone.matrix.copy() for bone in evaluated.pose.bones}
            samples.append((matrices,evaluated.matrix_basis.copy()))
        captured[action.name] = samples
    for bone in rig.pose.bones:
        for constraint in list(bone.constraints):
            bone.constraints.remove(constraint)
        bone.rotation_mode = "QUATERNION"
    for action in list(bpy.data.actions):
        bpy.data.actions.remove(action)
    for name,samples in captured.items():
        action = bpy.data.actions.new(name)
        action.use_fake_user = True
        rig.animation_data.action = action
        for frame,(matrices,transform) in enumerate(samples):
            rig.rotation_mode = "QUATERNION"
            rig.matrix_basis = transform
            for bone in rig.pose.bones:
                parent = bone.parent
                settings = {"parent_matrix":matrices[parent.name],
                            "parent_matrix_local":parent.bone.matrix_local} if parent else {}
                bone.matrix_basis = bone.bone.convert_local_to_pose(
                    matrices[bone.name],bone.bone.matrix_local,invert=True,**settings)
                for property_name in ("location","rotation_quaternion","scale"):
                    bone.keyframe_insert(property_name,frame=frame,group=bone.name)
            for property_name in ("location","rotation_quaternion","scale"):
                rig.keyframe_insert(property_name,frame=frame)


def points_for(meshes):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    return [obj.matrix_world @ v.co for obj in meshes for v in obj.evaluated_get(depsgraph).data.vertices]


def fit_floor(rig, meshes):
    """Fit skin and equipment to the fixed scene floor. Preserve stance origins."""
    bpy.context.view_layer.update()
    wrapper_space = rig.parent.matrix_world.to_3x3().inverted() if rig.parent else None
    clips = {}
    for action in bpy.data.actions:
        length = round(action.frame_range[1])
        transforms = []
        lows, highs = [], []
        for frame in range(length+1):
            activate(rig,action,frame)
            points = points_for(meshes)
            low = Vector(tuple(min(p[i] for p in points) for i in range(3)))
            high = Vector(tuple(max(p[i] for p in points) for i in range(3)))
            shift = Vector((0,0,max(0,.008-low.z)))
            if action.name == "fall":
                for axis in (0,1):
                    room_low, room_high = -.98-low[axis], .98-high[axis]
                    shift[axis] = max(room_low,min(room_high,0)) if room_low<=room_high else (room_low+room_high)*.5
            lows.append(low + shift)
            highs.append(high + shift)
            transforms.append((rig.location + (wrapper_space @ shift if wrapper_space else shift),
                               rig.rotation_quaternion.copy(),rig.scale.copy()))
        for frame,(location,rotation,scale) in enumerate(transforms):
            rig.location,rig.rotation_quaternion,rig.scale = location,rotation,scale
            for property_name in ("location","rotation_quaternion","scale"):
                rig.keyframe_insert(property_name,frame=frame)
        clips[action.name] = {
            "frames":length, "fps":24,
            "low":[round(min(p[i] for p in lows),4) for i in range(3)],
            "high":[round(max(p[i] for p in highs),4) for i in range(3)],
            "final_height":round(highs[-1].z,4),
            "samples":[{
                "frame":frame,
                "low":[round(lows[frame].x,5),round(lows[frame].z,5),round(-highs[frame].y,5)],
                "high":[round(highs[frame].x,5),round(highs[frame].z,5),round(-lows[frame].y,5)],
            } for frame in (0,round(length*.25),round(length*.5),round(length*.75),length)],
        }
    return clips


def open_master(path):
    bpy.ops.wm.open_mainfile(filepath=str(path),load_ui=False,use_scripts=False)
    rig = next(obj for obj in bpy.context.scene.objects if obj.type=="ARMATURE")
    activate(rig,bpy.data.actions["idle"],0)
    return rig


def build(name, workspace, out):
    base = workspace/"build/local-spiders-goblin-v1/masters"
    if name in GOBLINS:
        rig = open_master(base/"goblin.blend")
        body = bpy.data.objects["GoblinBody"]
        meshes = [body,*fit_goblin(name,rig,body,PALETTE)]
        if name == "goblin-queen":
            rig.parent.scale *= 1.20
        goblin_clips(rig,name)
        meshes.extend(obj for obj in rig.children if obj.type=="MESH" and obj not in meshes)
    elif name == "broodmother":
        rig = open_master(base/"webspinner.blend")
        body = bpy.data.objects["Spider"]
        rig.parent.scale = (.101,.107,.146)
        bpy.context.view_layer.update()
        meshes = [body,fit_broodmother(rig,body,PALETTE)]
        spider_call(rig)
    elif name == "great-rat":
        rat_base = workspace/"build/local-rat-landmarks-v1"
        rig = open_master(rat_base/"masters/rat-adapted.blend")
        body = bpy.data.objects["Rat"]
        meshes = [body,fit_great_rat(rig,body,PALETTE,rat_base/"art/enemies/rat-3d-v1/rat.png")]
        rig.parent.scale = (.644,.474,.639)
    else:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        rig, meshes = make_hero(name,PALETTE,make_party_clips)

    bake_constraints(rig)
    for mesh in meshes:
        mesh.data.validate(clean_customdata=False)
    if name in ("great-rat","broodmother"):
        settle_fall(rig,meshes)
    clips = fit_floor(rig,meshes)
    activate(rig,bpy.data.actions["idle"],0)
    bpy.context.scene.render.fps = 24
    for obj in list(bpy.context.scene.objects):
        if obj.type in ("CAMERA","LIGHT"):
            bpy.data.objects.remove(obj,do_unlink=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(out/"masters"/(name+".blend")))
    bpy.ops.object.select_all(action="DESELECT")
    for obj in ([rig.parent] if rig.parent else [])+[rig,*meshes]:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = rig
    target = ART/(name+".glb")
    bpy.ops.export_scene.gltf(
        filepath=str(target),export_format="GLB",use_selection=True,export_materials="NONE",
        export_animations=True,export_animation_mode="ACTIONS",export_frame_range=False,
        export_anim_slide_to_zero=True,export_force_sampling=True,export_frame_step=1,
        export_optimize_animation_size=True,export_current_frame=False,
        export_rest_position_armature=True,export_skins=True,export_all_influences=True,
        export_influence_nb=8,export_cameras=False,export_lights=False)
    counts = {}
    for mesh in meshes:
        mesh.data.calc_loop_triangles()
        counts[mesh.name] = len(mesh.data.loop_triangles)
    height = clips["idle"]["high"][2]
    print("ROSTER ASSET",name,sum(counts.values()),height,flush=True)
    return {
        "id":name,"label":LABELS[name],"party":name in HEROES,"triangles":sum(counts.values()),
        "surfaces":counts,"bones":len(rig.data.bones),"height":height,"clips":clips,"front":"+Z",
        "sha256":hashlib.sha256(target.read_bytes()).hexdigest(),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--workspace",type=Path,required=True)
    parser.add_argument("--party-only",action="store_true")
    args = parser.parse_args(sys.argv[sys.argv.index("--")+1:])
    out = args.workspace/("build/local-party-board-v2" if args.party_only else "build/local-combat-roster-v1")
    (out/"masters").mkdir(parents=True,exist_ok=True)
    catalog = ART/"catalog.json"
    if not args.party_only:
        palette_png(ART/"palette.png",PALETTE)
    assets = [build(name,args.workspace,out) for name in (HEROES if args.party_only else IDS)]
    entries = assets
    if args.party_only:
        updates = {entry["id"]:entry for entry in assets}
        entries = [updates.get(entry["id"],entry) for entry in json.loads(catalog.read_text(encoding="utf-8"))["assets"]]
    catalog.write_text(json.dumps({"assets":entries,"palette":PALETTE},indent=2)+"\n",encoding="utf-8",newline="\n")
    for asset in assets:
        name = asset["id"]
        material = "party-palette" if asset["party"] else "palette"
        (ART/(name+".tscn")).write_text(
            '[gd_scene load_steps=4 format=3]\n'
            '[ext_resource type="Script" path="res://art/enemies/combat-roster-3d-v1/actor.gd" id="1"]\n'
            f'[ext_resource type="Material" path="res://art/enemies/combat-roster-3d-v1/{material}.tres" id="2"]\n'
            f'[ext_resource type="PackedScene" path="res://art/enemies/combat-roster-3d-v1/{name}.glb" id="3"]\n'
            '[node name="Actor" type="Node3D"]\nscript=ExtResource("1")\npalette_material=ExtResource("2")\n'
            f'metadata/visual_height={asset["height"]}\n'
            '[node name="Model" parent="." instance=ExtResource("3")]\n',encoding="utf-8",newline="\n")


if __name__=="__main__":
    main()
