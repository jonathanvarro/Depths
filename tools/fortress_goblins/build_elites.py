"""Build the Gate Captain and Goblin Brute from the local CC0 goblin master."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Euler, Vector

ROOT = Path(__file__).resolve().parents[2]
sys.dont_write_bytecode = True
sys.path.insert(0, str(ROOT / "tools/combat_roster"))
from build_roster import PALETTE, activate, fit_floor, make_action, open_master, rotate, settle_fall
from mesh_parts import Mesh, prior_colours, set_uv

ART = ROOT / "art/enemies/goblin-elites-3d-v1"
ASSET_PATH = "res://art/enemies/goblin-elites-3d-v1/"
ROSTER_PATH = "res://art/enemies/combat-roster-3d-v1/"


def grip(rig, side):
    return rig.matrix_world @ rig.pose.bones[f"hand_{side}"].head


def make_captain(rig, armour, kit):
    armour.loft([(1.07,.17,.136,0,-.063),(1.19,.158,.136,-.008,-.063),
                 (1.26,.127,.105,-.01,-.058),(1.29,.048,.056,-.018,-.048)],
                "head","steel_dark","iron_edge",10,twist=.09)
    armour.panel([(-.096,1.139),(-.05,1.24),(-.07,1.39),(-.017,1.354),
                  (.032,1.397),(.06,1.24),(.117,1.137),(.062,1.148),(-.041,1.156)],
                 -.145,.077,"head","steel","steel_dark")
    for side in (-1,1):
        armour.panel([(side*.108,1.14),(side*.148,1.147),(side*.163,1.015),
                      (side*.126,.998)],-.163,.066,"head","iron","steel")
    # Stacked plates on the horn side leave an open cleaver arm.
    for i in range(3):
        armour.stone((.213+i*.022,.018+i*.01,.933-i*.06),(.128,.147,.074),
                     "upperarm_L","steel_dark","steel",8)
    armour.loft([(.72,.169,.135,0,.134),(.86,.219,.141,0,.119),(.96,.178,.121,0,.084)],
                "spine3","steel_dark","iron_edge",9,twist=.12)
    armour.panel([(-.154,.696),(.13,.693),(.156,.478),(.059,.425),(-.015,.471),
                  (-.115,.392),(-.178,.479)],-.018,.045,"spine2","maroon","maroon_dark")
    armour.stone((-.09,.01,.834),(.048,.028,.049),"spine3","brass","brass_edge",6)

    right = grip(rig,"R")
    kit.segment(right+Vector((.072,.016,.103)),right+Vector((-.14,-.036,-.167)),
                [(0,.024),(.6,.025),(1,.029)],"hand_R","wood_dark","leather_light",7)
    x,y,z = right
    kit.panel([(x-.104,z-.083),(x-.179,z-.056),(x-.360,z-.25),
               (x-.393,z-.427),(x-.319,z-.46),(x-.214,z-.398),(x-.25,z-.312)],
              y-.055,.052,"hand_R","steel_dark","steel")
    kit.panel([(x-.179,z-.066),(x-.36,z-.25),(x-.393,z-.427),(x-.319,z-.46),
               (x-.339,z-.393),(x-.329,z-.276)],y-.06,.01,"hand_R","steel","iron_edge")

    left = grip(rig,"L")
    # In hand space the mouthpiece ends inward and the brass bell rises out.
    bends = [Vector((-.093,-.007,.038)),Vector((0,0,-.013)),Vector((.093,-.027,-.025)),
             Vector((.178,-.066,.015)),Vector((.229,-.104,.107))]
    horn_rings(kit,[left+offset for offset in bends])
    return bends[0]


def horn_rings(kit, path):
    sizes = [.018,.030,.039,.053,.076]
    sides = 9
    vertices = []
    for i, point in enumerate(path):
        axis = (path[min(i+1,4)]-path[max(i-1,0)]).normalized()
        across = axis.cross(Vector((0,1,0))).normalized()
        normal = axis.cross(across)
        for j in range(sides):
            theta = math.tau*j/sides
            vertices.append(point+sizes[i]*(across*math.cos(theta)+normal*math.sin(theta)))
    lip = len(vertices)-sides
    axis = (path[-1]-path[-2]).normalized()
    vertices.extend(path[-1]+(v-path[-1])*.75-axis*.016 for v in vertices[lip:lip+sides])
    faces = [tuple(reversed(range(sides)))]
    colours = ["brass_dark"]
    for ring, colour in enumerate(["brass_dark","bone_dark","brass","brass_edge","steel_dark"]):
        for j in range(sides):
            k = (j+1)%sides
            start = ring*sides
            faces.append((start+j,start+k,start+sides+k,start+sides+j))
            colours.append(colour)
    faces.append(tuple(range(lip+sides,lip+2*sides)))
    colours.append("charcoal")
    kit.add(vertices,faces,colours,"hand_L")


def make_brute(rig, armour, kit):
    for side, sign in (("L",1),("R",-1)):
        armour.stone((sign*.184,.021,.867),(.115,.124,.151),
                     "upperarm_"+side,"skin","skin_light",9)
        armour.stone((sign*.125,-.072,.732),(.066,.079,.088),
                     "forearm_"+side,"leather","leather_light",8)
    armour.loft([(.64,.200,.122,0,.112),(.76,.213,.144,0,.119),(.84,.205,.131,0,.118)],
                "spine2","leather","wood_dark",10,twist=.095)
    armour.panel([(-.18,.733),(-.047,.771),(.163,.696),(.198,.494),(.12,.507),
                  (.085,.396),(-.079,.48),(-.14,.422)],-.01,.045,"spine2","carapace","wood_dark")
    armour.stone((-.225,.034,.923),(.101,.124,.078),"upperarm_R","iron","carapace_light",8)
    armour.segment((-.224,-.03,.929),(.136,-.029,.689),[(0,.035),(1,.03)],
                   "spine3","wood_dark","carapace_light",5)
    right = grip(rig,"R")
    start = right + Vector((-.143,0,0))
    head = right + Vector((.49,0,0))
    kit.segment(start,head,[(0,.035),(.21,.03),(.61,.035),(1,.039)],
                "hand_R","wood","leather_light",8)
    # Low square maul, pale chipped bands around its stone core.
    kit.loft([(-.128,.106,.091,0,0),(-.084,.135,.108,.002,0),
              (.091,.126,.103,-.015,.005),(.137,.105,.086,-.012,.007)],
             "hand_R","iron","steel",4,(0,-1,.34),head,.11)
    for height in (-.09,.072):
        kit.loft([(height,.131,.115,0,0),(height+.035,.135,.117,0,0)],
                 "hand_R","steel","iron_edge",4,(0,-1,.34),head,.07)


def position_arm(rig, side, target, turn, baseline_hand):
    # Fixed upper/lower arm lengths, with the elbow bending away from the chest.
    bone = rig.pose.bones
    upper, lower, hand = (bone[f"{key}_{side}"] for key in ("upperarm","forearm","hand"))
    space = rig.matrix_world.inverted()
    shoulder, elbow, wrist = upper.head.copy(), lower.head.copy(), hand.head.copy()
    reach = space @ Vector(target) - shoulder
    along = reach.normalized()
    a, b = (elbow-shoulder).length, (wrist-elbow).length
    distance = min(max(reach.length,abs(a-b)+.001),(a+b)*.995)
    pole = space @ Vector((.43 if side=="L" else -.43,-.04,.81)) - shoulder
    bend = (pole-along*pole.dot(along)).normalized()
    offset = (a*a-b*b+distance*distance)/(2*distance)
    hinge = shoulder+along*offset+bend*math.sqrt(max(0,a*a-offset*offset))
    hand_target = shoulder+along*distance
    for part, base, origin, start, end in (
        (upper,upper.matrix.copy(),shoulder,elbow-shoulder,hinge-shoulder),
        (lower,lower.matrix.copy(),hinge,wrist-elbow,hand_target-hinge),
    ):
        matrix = start.normalized().rotation_difference(end.normalized()).to_matrix().to_4x4() @ base
        matrix.translation = origin
        part.matrix = matrix
        bpy.context.view_layer.update()
    local = space.to_quaternion() @ turn @ rig.matrix_world.to_quaternion()
    hand_matrix = local.to_matrix().to_4x4() @ baseline_hand
    hand_matrix.translation = hand_target
    hand.matrix = hand_matrix
    bpy.context.view_layer.update()


def author_clips(rig, captain, mouthpiece):
    baseline = {bone.name: bone.matrix_basis.copy() for bone in rig.pose.bones}
    hands = {s: rig.pose.bones[f"hand_{s}"].matrix.copy() for s in "LR"}
    neutral = {side: grip(rig,side) for side in "LR"}
    turn = lambda x,y,z: Euler(tuple(math.radians(d) for d in (x,y,z))).to_quaternion()
    neutral_maul = ((-.09,-.24,.63),(0,0,-8),0)
    high_maul = ((-.15,-.17,1.122),(0,-51,-21),-14)
    hit_maul = ((-.14,-.385,.70),(0,12,-25),18)
    low_maul = ((-.12,-.25,.46),(0,9,-11),25)

    def brute(arm, parameters):
        point, angles, lean = parameters
        rotate(arm.pose.bones["spine3"],(lean,0,-lean*.24))
        bpy.context.view_layer.update()
        orientation = turn(*angles)
        right = Vector(point)
        position_arm(arm,"R",right,orientation,hands["R"])
        position_arm(arm,"L",right+orientation@Vector((.175,0,0)),orientation,hands["L"])

    def captain_pose(arm, parameters):
        swing, rally, breathe = parameters
        bone = arm.pose.bones
        rotate(bone["spine3"],(-12*swing+2*breathe,0,-16*swing))
        rotate(bone["head"],(3*breathe,0,8*rally))
        bpy.context.view_layer.update()
        if swing < 0:
            wrist = neutral["R"].lerp(Vector((-.287,-.13,1.02)),-swing)
            blade = turn(0,145*swing,4*swing)
        else:
            wrist = neutral["R"].lerp(Vector((-.175,-.365,.76)),swing)
            blade = turn(-22*swing,-55*swing,36*swing)
        position_arm(arm,"R",wrist,blade,hands["R"])
        horn = turn(-5*rally,-23*rally,-34*rally)
        mouth = arm.matrix_world @ bone["head"].head + Vector((.032,-.214,-.037))
        wrist = neutral["L"].lerp(mouth - horn@mouthpiece,rally)
        position_arm(arm,"L",wrist,horn,hands["L"])

    if captain:
        definitions = [
            ("idle", [(0,(0,0,0)),(18,(0,0,1)),(36,(0,0,0))]),
            ("wind-up", [(0,(-1,0,0)),(12,(-1,0,1)),(24,(-1,0,0))]),
            ("rally", [(0,(0,.72,0)),(12,(0,.84,1)),(24,(0,.72,0))]),
            ("horn", [(0,(0,.72,0)),(4,(0,1,0)),(10,(0,1,1)),(17,(0,0,0))]),
            ("attack", [(0,(0,0,0)),(3,(-.56,0,0)),(7,(1,0,0)),(11,(.75,0,0)),(17,(0,0,0))]),
            ("heavy", [(0,(-1,0,0)),(3,(-1,0,.5)),(7,(1,0,0)),(11,(.9,0,0)),(18,(0,0,0))]),
        ]
        for name, keys in definitions:
            make_action(rig,name,baseline,keys,captain_pose)
    else:
        breath = (neutral_maul[0],neutral_maul[1],2.5)
        loaded = (high_maul[0],high_maul[1],-16)
        rest = (low_maul[0],low_maul[1],21)
        swept = ((-.08,-.345,.66),(0,7,-33),11)
        definitions = [
            ("idle", [(0,neutral_maul),(18,breath),(36,neutral_maul)]),
            ("wind-up", [(0,high_maul),(12,loaded),(24,high_maul)]),
            ("recover", [(0,low_maul),(12,rest),(24,low_maul)]),
            ("attack", [(0,neutral_maul),(3,high_maul),(7,swept),(11,hit_maul),(17,neutral_maul)]),
            ("heavy", [(0,high_maul),(3,loaded),(7,hit_maul),(12,low_maul),(18,low_maul)]),
        ]
        for name, keys in definitions:
            make_action(rig,name,baseline,keys,brute)

    def recoil(arm, amount):
        if captain:
            captain_pose(arm,(0,0,0))
        else:
            brute(arm,neutral_maul)
        rotate(arm.pose.bones["spine3"],(17*amount,3*amount,-11*amount))
        rotate(arm.pose.bones["head"],(10*amount,8*amount,12*amount))

    def collapse(arm, amount):
        recoil(arm,amount*.6)
        arm.rotation_quaternion = turn(19*amount,-79*amount,17*amount)
        arm.location = arm.parent.matrix_world.to_3x3().inverted() @ Vector((-.09*amount,.14*amount,-.85*amount))
        rotate(arm.pose.bones["upperleg_L"],(-16*amount,0,-10*amount))
        rotate(arm.pose.bones["lowerleg_L"],(28*amount,0,0))

    make_action(rig,"hurt",baseline,[(0,0),(4,1),(8,.58),(12,0)],recoil)
    make_action(rig,"fall",baseline,[(0,0),(5,.18),(12,.63),(21,.97),(26,1)],collapse)


def build(model_id, master, output):
    rig = open_master(master)
    body = bpy.data.objects["GoblinBody"]
    for name in ("Knife","Buckler"):
        bpy.data.objects.remove(bpy.data.objects[name],do_unlink=True)
    captain = model_id == "gate-captain"
    cloth = {"cloth":"maroon_dark","cloth_dark":"leather","cloth_light":"maroon"} if captain else {
         "cloth":"wood_dark","cloth_dark":"leather","cloth_light":"carapace"}
    set_uv(body.data,PALETTE,[cloth.get(c,c) for c in prior_colours(body.data,PALETTE)])
    armour,kit = Mesh(),Mesh()
    mouthpiece = make_captain(rig,armour,kit) if captain else make_brute(rig,armour,kit)
    meshes = [body,armour.finish("Armour",rig,PALETTE),kit.finish("RoleKit",rig,PALETTE)]
    if not captain:
        scale = rig.parent.scale.copy()
        rig.parent.scale = (scale.x*1.26,scale.y*1.14,scale.z*1.12)
        bpy.context.view_layer.update()
    author_clips(rig,captain,mouthpiece)
    for mesh in meshes:
        mesh.data.validate(clean_customdata=False)
    settle_fall(rig,meshes)
    clips = fit_floor(rig,meshes)
    activate(rig,bpy.data.actions["idle"],0)
    bpy.context.scene.render.fps = 24
    bpy.ops.wm.save_as_mainfile(filepath=str(output/"masters"/(model_id+".blend")))
    bpy.ops.object.select_all(action="DESELECT")
    for obj in [rig.parent,rig,*meshes]:
        obj.select_set(True)
    target = ART/(model_id+".glb")
    bpy.ops.export_scene.gltf(
        filepath=str(target),export_format="GLB",use_selection=True,export_materials="NONE",
        export_animations=True,export_animation_mode="ACTIONS",export_frame_range=False,
        export_anim_slide_to_zero=True,export_force_sampling=True,export_frame_step=1,
        export_current_frame=False,export_rest_position_armature=True,
        export_all_influences=True,export_influence_nb=8,export_cameras=False,export_lights=False)
    counts = {}
    for mesh in meshes:
        mesh.data.calc_loop_triangles()
        counts[mesh.name] = len(mesh.data.loop_triangles)
    held = ["wind-up","rally" if captain else "recover"]
    height = clips["idle"]["high"][2]
    board_clearance = "" if captain else "metadata/board_tag_clearance = 0.68\n"
    (ART/(model_id+".tscn")).write_text(
        '[gd_scene load_steps=4 format=3]\n'
        f'[ext_resource type="Script" path="{ROSTER_PATH}actor.gd" id="1"]\n'
        f'[ext_resource type="Material" path="{ROSTER_PATH}palette.tres" id="2"]\n'
        f'[ext_resource type="PackedScene" path="{ASSET_PATH}{model_id}.glb" id="3"]\n\n'
        '[node name="Actor" type="Node3D"]\nscript = ExtResource("1")\npalette_material = ExtResource("2")\n'
        f'held_poses = PackedStringArray({", ".join(json.dumps(p) for p in held)})\n'
        f'metadata/visual_height = {height}\n{board_clearance}\n'
        '[node name="Model" parent="." instance=ExtResource("3")]\n',encoding="utf-8",newline="\n")
    return {"id":model_id,"triangles":sum(counts.values()),"surfaces":counts,
            "bones":len(rig.data.bones),"front":"+Z","height":height,"clips":clips,
            "sha256":hashlib.sha256(target.read_bytes()).hexdigest()}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--workspace",type=Path,required=True)
    options = parser.parse_args(sys.argv[sys.argv.index("--")+1:])
    output = options.workspace/"build/local-goblin-elites-v1"
    (output/"masters").mkdir(parents=True,exist_ok=True)
    ART.mkdir(parents=True,exist_ok=True)
    master = options.workspace/"build/local-spiders-goblin-v1/masters/goblin.blend"
    assets = [build(model,master,output) for model in ("gate-captain","goblin-brute")]
    (ART/"catalog.json").write_text(json.dumps({"assets":assets},indent=2)+"\n",
                                     encoding="utf-8",newline="\n")
