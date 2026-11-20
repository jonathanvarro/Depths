"""Original low-poly models for the remaining encounters through Floor 4."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Quaternion, Vector

ROOT = Path(__file__).resolve().parents[2]
sys.dont_write_bytecode = True
sys.path.insert(0, str(ROOT/"tools/combat_roster"))
from build_roster import PALETTE, activate, fit_floor, make_action, rotate
from mesh_parts import Mesh

OUT = ROOT/"art/enemies/early-creatures-3d-v1"
SHARED = "res://art/enemies/combat-roster-3d-v1/"
IDS = ("cave-bat","rock-beetle","hollow-miner","gas-bloat","lamp-eater","breach-hound")


def armature(joints):
    data = bpy.data.armatures.new("Creature joints")
    rig = bpy.data.objects.new("Rig",data)
    bpy.context.collection.objects.link(rig)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    for name, point, parent in joints:
        bone = data.edit_bones.new(name)
        bone.head = point
        bone.tail = (point[0],point[1],point[2]+.12)
        if parent:
            bone.parent = data.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    rig.animation_data_create()
    return rig


def bat(mesh, joints):
    mesh.stone((0,.08,1.03),(.125,.22,.14),"root","pelt_dark","pelt",9)
    mesh.stone((0,-.102,1.067),(.115,.10,.103),"root","pelt","pelt_high",8)
    for sign, side in ((-1,"r"),(1,"l")):
        pivot = (.075*sign,.03,1.06)
        knuckle = (.31*sign,-.08,1.07)
        joints.extend([("wing_"+side,pivot,"root"),("tip_"+side,knuckle,"wing_"+side)])
        mesh.segment((.051*sign,-.116,1.108),(.081*sign,-.104,1.26),
                     [(0,.041),(1,.004)],"root","pelt","skin_shadow",5)
        mesh.stone((.055*sign,-.185,1.078),(.018,.017,.016),"root","brass_dark","brass",5)
        inner = [(pivot[0],.025,1.061),knuckle,(.28*sign,.21,1.025),(.073*sign,.196,1.015)]
        outer = [knuckle,(.77*sign,.05,1.035),(.57*sign,.18,1.027),
                 (.402*sign,.183,1.028),(.37*sign,.295,1.016),(.28*sign,.21,1.025)]
        for name, fan in (("wing_"+side,inner),("tip_"+side,outer)):
            # Duplicate faces give the thin membranes two visible sides.
            n=len(fan)
            mesh.add(fan+[(x,y,z-.011) for x,y,z in fan],
                     [tuple(range(n)),tuple(reversed(range(n,2*n)))],"maroon_dark",name)
            for start, tip in ((fan[0],fan[1]),(fan[0],fan[-2])):
                mesh.segment(start,tip,[(0,.018),(1,.007)],name,"pelt_high","skin_shadow",5)
        mesh.segment((.072*sign,.133,1.045),(.093*sign,.19,.924),
                     [(0,.026),(1,.013)],"root","pelt_dark","pelt",5)


def beetle(mesh, joints):
    joints.extend((("shell",(0,.11,.29),"root"),("head",(0,-.205,.21),"root")))
    mesh.stone((0,.062,.218),(.29,.363,.19),"root","charcoal","leather",10)
    for sign, side in ((-1,"r"),(1,"l")):
        joints.append(("wing_"+side,(sign*.024,.13,.31),"shell"))
        mesh.stone((sign*.137,.094,.343),(.167,.358,.169),
                   "wing_"+side,"carapace","carapace_light",9)
        for i in range(3):
            y=.21-i*.19
            name=f"leg_{side}{i}"
            root=(sign*.197,y,.225)
            joints.append((name,root,"root"))
            elbow=(sign*(.38-.032*i),y-.066,.16)
            foot=(sign*(.43-.021*i),y+.02,.025)
            mesh.segment(root,elbow,[(0,.061),(1,.047)],name,"iron","carapace",6)
            mesh.segment(elbow,foot,[(0,.042),(1,.014)],name,"leather","wood_dark",6)
        mesh.segment((sign*.082,-.286,.216),(sign*.172,-.459,.188),
                     [(0,.051),(1,.012)],"head","wood_dark","bone_dark",6)
    mesh.stone((0,-.272,.232),(.165,.159,.131),"head","leather","iron",8)


def miner(mesh, joints):
    joints.extend((("torso",(0,.05,.67),"root"),("head",(0,-.087,1.14),"torso")))
    mesh.loft([(.50,.183,.131,0,.047),(.78,.203,.123,0,.049),
               (1.02,.246,.124,-.012,.054),(1.106,.129,.096,-.033,.03)],
              "torso","charcoal","wool",9,twist=.10)
    mesh.stone((-.033,-.094,1.20),(.119,.119,.151),"head","wool_light","skin_shadow",8)
    for x in (-.073,.012):
        mesh.stone((x,-.195,1.19),(.034,.024,.029),"head","charcoal","pelt_dark",6)
    mesh.stone((-.03,-.203,1.132),(.046,.023,.025),"head","pelt_dark","skin_shadow",6)
    mesh.loft([(1.231,.142,.128,-.037,-.092),(1.326,.128,.12,-.045,-.087),
              (1.351,.083,.085,-.049,-.087)],"head","leather","sack",8,twist=.09)
    mesh.stone((-.047,-.201,1.271),(.044,.039,.043),"head","brass_dark","cream",7)
    mesh.panel([(-.19,.94),(-.145,.99),(.145,.652),(.118,.61)],-.106,.032,
               "torso","wood","leather")
    for sign, side in ((-1,"r"),(1,"l")):
        shoulder=(sign*.19,.053,1.015)
        elbow=(sign*.265,-.112,.82)
        wrist=(sign*.27,-.25,.658)
        joints.extend(((f"arm_{side}",shoulder,"torso"),(f"leg_{side}",(sign*.105,.049,.55),"root")))
        for a,b,r in ((shoulder,elbow,.08),(elbow,wrist,.055)):
            mesh.segment(a,b,[(0,r),(1,r*.73)],f"arm_{side}","wool","wool_light")
        mesh.stone(wrist,(.066,.082,.051),f"arm_{side}","wool_light","skin_shadow",7)
        mesh.segment((sign*.113,.046,.568),(sign*.147,-.037,.105),[(0,.092),(1,.068)],
                     f"leg_{side}","wood_dark","leather",7)
        mesh.stone((sign*.144,-.083,.076),(.074,.141,.073),f"leg_{side}","charcoal","wool",7)


def bloat(mesh, joints):
    joints.extend((("sac",(0,.01,.61),"root"),("jaw",(0,-.239,.43),"root")))
    mesh.loft([(.37,.15,.145,0,.028),(.54,.33,.275,0,.043),(.79,.354,.294,-.017,.042),
              (.962,.274,.229,-.052,.025),(1.047,.16,.143,-.061,.024)],
             "sac","moss","moss_light",12,twist=.105)
    for i in range(9):
        a=i*math.tau/9
        point=(.274*math.cos(a),.066+.235*math.sin(a),.83+.1*math.sin(i*3))
        size = .063 + .018 * (i % 3)
        mesh.stone(point,(size,size*.94,.084+.018*(i%4)),"sac","deep_olive","bone_dark",6)
    mesh.stone((0,-.241,.479),(.165,.136,.118),"jaw","maroon_dark","skin_shadow",8)
    for sign, side in ((-1,"r"),(1,"l")):
        pivot=(sign*.158,.024,.50)
        joints.append(("arm_"+side,pivot,"root"))
        mesh.segment(pivot,(sign*.38,.043,.302),[(0,.076),(.6,.056),(1,.017)],
                     "arm_"+side,"skin_shadow","pelt_high",7)
        mesh.segment((sign*.141,.105,.475),(sign*.136,.23,.18),[(0,.083),(1,.019)],
                     "root","deep_olive","bone_dark",6)


def eater(mesh, joints):
    joints.extend((("torso",(0,.093,.45),"root"),("head",(0,-.095,.70),"torso"),
                   ("jaw",(0,-.245,.62),"head")))
    mesh.loft([(.31,.165,.14,0,.076),(.47,.207,.195,.017,.106),(.65,.245,.193,.027,.119),
               (.778,.13,.118,0,.032)],"torso","charcoal","pelt_dark",10,twist=.09)
    for i in range(4):
        x = (i-1.5)*.072
        mesh.segment((x,.213,.648+.013*(i%2)),(x*1.72,.294+.032*(i%2),.418),
                     [(0,.039),(.6,.036),(1,.009)],"torso","pelt_dark","wool",5)
    mesh.stone((0,-.169,.738),(.185,.158,.136),"head","pelt_dark","wool",9)
    mesh.stone((0,-.289,.659),(.14,.092,.045),"head","charcoal","leather",9)
    mesh.stone((0,-.277,.608),(.132,.115,.071),"jaw","pelt","pelt_high",9)
    for i in range(7):
        x=(i-3)*.035
        y=-.357+.092*(abs(x)/.12)**2
        mesh.segment((x,y,.653),(x,y-.015,.605),[(0,.017),(1,.004)],
                     "head","bone_dark","cream",5)
    for sign, side in ((-1,"r"),(1,"l")):
        pivot=(sign*.144,.047,.635)
        joints.append(("arm_"+side,pivot,"torso"))
        point=(sign*.288,-.23,.088)
        mesh.segment(pivot,(sign*.302,-.041,.352),[(0,.076),(1,.065)],
                     "arm_"+side,"wool","pelt",7)
        mesh.segment((sign*.302,-.041,.352),point,[(0,.064),(1,.053)],
                     "arm_"+side,"pelt_dark","pelt_high",7)
        for offset in (-.034,0,.034):
            mesh.segment((point[0]+offset,point[1],point[2]),(point[0]+offset,point[1]-.071,.019),
                         [(0,.018),(1,.005)],"arm_"+side,"bone_dark","bone",5)
        mesh.stone((sign*.157,.181,.202),(.095,.122,.202),"root","charcoal","pelt",8)


def hound(mesh, joints):
    joints.extend((("head",(0,-.325,.554),"root"),("tail",(0,.414,.503),"root")))
    mesh.stone((0,.115,.504),(.179,.392,.211),"root","pelt_dark","pelt",10)
    mesh.stone((0,-.181,.565),(.21,.168,.229),"root","pelt","pelt_high",9)
    mesh.stone((0,-.393,.548),(.124,.147,.128),"head","wood_dark","pelt",8)
    mesh.stone((0,-.527,.503),(.097,.142,.073),"head","charcoal","pelt_dark",8)
    mesh.segment((0,.375,.517),(.076,.712,.493),[(0,.065),(.6,.037),(1,.005)],
                 "tail","pelt_dark","pelt_high",7)
    for sign, side in ((-1,"r"),(1,"l")):
        mesh.segment((sign*.093,-.388,.572),(sign*.146,-.301,.738),
                     [(0,.063),(1,.004)],"head","pelt_high","wood_dark",6)
        mesh.stone((sign*.073,-.506,.580),(.019,.014,.013),"head","brass_dark","brass_edge",6)
        mesh.segment((sign*.072,-.584,.498),(sign*.071,-.583,.436),
                     [(0,.022),(1,.003)],"head","bone_dark","cream",5)
        for i,y in enumerate((-.22,.333)):
            name=f"leg_{side}{i}"
            joint=(sign*.13,y,.50)
            joints.append((name,joint,"root"))
            elbow=(sign*.184,y+(.087 if i else -.029),.28)
            paw=(sign*.176,y-.053,.038)
            mesh.segment(joint,elbow,[(0,.087),(1,.059)],name,"pelt","pelt_high",7)
            mesh.segment(elbow,paw,[(0,.055),(1,.039)],name,"pelt_dark","pelt",7)
            mesh.stone(paw,(.063,.096,.035),name,"charcoal","pelt",7)
    for i in range(5):
        mesh.stone((0,-.16+i*.117,.715-i*.018),(.061,.077,.082),
                   "root","pelt","skin_shadow",6)


def motion(rig, kind, pose, amount):
    bones=rig.pose.bones
    def bend(name, x=0, y=0, z=0):
        rotate(bones[name],(x*amount,y*amount,z*amount))
    if pose == "fall":
        if kind == "cave-bat":
            rig.location.z = -.93*amount
            bend("wing_l",0,30,-23)
            bend("wing_r",0,-36,23)
        elif kind == "gas-bloat":
            rig.location.z = -.17*amount
            bones["sac"].scale = (1-.44*amount,1-.39*amount,1-.51*amount)
        else:
            roll = -179 if kind == "rock-beetle" else -78
            rig.rotation_quaternion = Quaternion((0,1,0),math.radians(roll*amount))
            rig.location.z = -.30*amount
        return
    if pose == "hurt":
        bend("root",-13,4,-11)
        return
    if kind == "cave-bat":
        grounded = pose in ("landed","bite")
        rig.location.z = -.89 if grounded else (-.87*amount if pose=="swoop" else .047*amount)
        rig.location.y = -.24*amount if pose == "swoop" else (-.10*amount if pose=="bite" else 0)
        for side,flip in (("l",1),("r",-1)):
            if grounded:
                rotate(bones["wing_"+side], (0,-6*flip,55*flip))
                rotate(bones["tip_"+side], (0,8*flip,49*flip))
            else:
                bend("wing_"+side,0,(24 if pose=="swoop" else 33)*flip)
                bend("tip_"+side,0,-12*flip)
        if pose in ("attack","swoop","bite","landed"):
            bend("root",-21)
    elif kind == "rock-beetle":
        bend("head",-47 if pose=="curled" else 17)
        for bone in bones:
            if bone.name.startswith("leg_"):
                side = 1 if "_l" in bone.name else -1
                bend(bone.name,0,-24*side if pose=="curled" else 7*side,
                     28*side if pose=="curled" else 4*side)
                if pose == "curled":
                    bone.scale = (1-.46*amount,)*3
        if pose == "curled":
            head = bones["head"]
            head.location = head.bone.matrix_local.to_3x3().inverted() @ Vector((0,.17,-.065))*amount
            rig.location.z = -.06*amount
        elif pose == "attack":
            rig.location.y = -.18*amount
    elif kind == "hollow-miner":
        bend("torso",20 if pose in ("grab","attack") else 3,0,7)
        bend("head",-13,0,-10)
        bend("arm_l",-72 if pose=="grab" else 9,0,-8)
        bend("arm_r",-77 if pose in ("grab","attack") else -8,0,8)
    elif kind == "gas-bloat":
        swell = .22 if pose=="swell" else .034
        bones["sac"].scale = (1+swell*amount,1+swell*amount,1+swell*amount)
        rig.location.z = .042*amount
        bend("arm_l",22,7,0)
        bend("arm_r",22,-7,0)
        bend("jaw",19 if pose=="attack" else 4)
    elif kind == "lamp-eater":
        bend("torso",21 if pose=="drain" else 8,0,2)
        bend("head",-11)
        bend("jaw",52 if pose=="drain" else 11)
        bend("arm_l",32 if pose=="drain" else 5,0,-9)
        bend("arm_r",32 if pose=="drain" else 5,0,9)
    elif kind == "breach-hound":
        bend("head",18 if pose=="lunge" else 6)
        bend("tail",0,0,23)
        if pose in ("lunge","attack"):
            rig.location.y = (-.24 if pose=="lunge" else -.15)*amount
            bend("leg_l0",37)
            bend("leg_r0",29)
            bend("leg_l1",-23)
            bend("leg_r1",-29)


def export(kind, shape, held, gesture, workspace):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mesh = Mesh()
    joints = [("root",(0,0,0),None)]
    shape(mesh,joints)
    rig = armature(joints)
    body = mesh.finish("Body",rig,PALETTE)
    body.data.validate(clean_customdata=False)
    baseline = {bone.name:bone.matrix_basis.copy() for bone in rig.pose.bones}
    clips = {
        "idle": [(0,0),(6,1),(12,0),(18,-.70),(24,0)],
        "attack": [(0,0),(4,.32),(7,1),(13,.47),(18,0)],
        "hurt": [(0,0),(3,1),(7,.39),(12,0)],
        "fall": [(0,0),(6,.19),(14,.69),(24,1)],
    }
    if held:
        clips[held] = [(0,1),(12,.91),(24,1)]
    if gesture and gesture != held:
        clips[gesture] = [(0,0),(4,.54),(7,1),(12,.70),(18,0)]
    if kind == "cave-bat":
        clips["bite"] = clips["attack"]
    for name,keys in clips.items():
        make_action(rig,name,baseline,keys,lambda arm,amount: motion(arm,kind,name,amount))
    bounds = fit_floor(rig,[body])
    for name, info in bounds.items():
        assert max(abs(value) for value in info["low"][:2]+info["high"][:2]) <= 1.04, (kind,name,info)
        assert info["low"][2] >= 0, (kind,name,info)
    activate(rig,bpy.data.actions["idle"],0)
    bpy.context.scene.render.fps = 24
    bpy.ops.wm.save_as_mainfile(filepath=str(workspace/"masters"/(kind+".blend")))
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    rig.select_set(True)
    path = OUT/(kind+".glb")
    bpy.ops.export_scene.gltf(filepath=str(path),export_format="GLB",use_selection=True,
        export_materials="NONE",export_animations=True,export_animation_mode="ACTIONS",
        export_frame_range=False,export_anim_slide_to_zero=True,export_force_sampling=True)
    body.data.calc_loop_triangles()
    height = bounds["idle"]["high"][2]
    extra = f'held_poses = PackedStringArray("{held}")\n' if held else ""
    (OUT/(kind+".tscn")).write_text(
        '[gd_scene load_steps=4 format=3]\n'
        f'[ext_resource type="Script" path="{SHARED}actor.gd" id="1"]\n'
        f'[ext_resource type="Material" path="{SHARED}palette.tres" id="2"]\n'
        f'[ext_resource type="PackedScene" path="res://art/enemies/early-creatures-3d-v1/{kind}.glb" id="3"]\n\n'
        '[node name="Actor" type="Node3D"]\nscript = ExtResource("1")\npalette_material = ExtResource("2")\n'
        f'{extra}metadata/visual_height = {height}\n\n'
        '[node name="Model" parent="." instance=ExtResource("3")]\n',encoding="utf-8")
    return {"id":kind,"front":"+Z","height":height,"triangles":len(body.data.loop_triangles),
            "bones":len(rig.data.bones),"clips":bounds,"sha256":hashlib.sha256(path.read_bytes()).hexdigest()}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--workspace",type=Path,required=True)
    options = parser.parse_args(sys.argv[sys.argv.index("--")+1:])
    review = options.workspace/"build/local-early-creatures-v1"
    (review/"masters").mkdir(parents=True,exist_ok=True)
    OUT.mkdir(parents=True,exist_ok=True)
    specs = zip(IDS,(bat,beetle,miner,bloat,eater,hound),
                ("landed","curled","grab","swell","", ""),
                ("swoop","","","","drain","lunge"),strict=True)
    assets = [export(*spec, review) for spec in specs]
    (OUT/"catalog.json").write_text(json.dumps({"assets":assets},indent=2)+"\n",encoding="utf-8")
