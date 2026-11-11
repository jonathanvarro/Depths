"""A purpose-built hunch rig and planted-staff motion study for the Goblin King."""
import math
import bpy
from mathutils import Matrix, Quaternion, Vector

from mesh_parts import Mesh
from build_roster import activate, make_action, points_for, rotate


def settle_collapse(rig, meshes):
    """Settle the body and release the staff independently onto the tile."""
    body_meshes=meshes[:2]
    action=bpy.data.actions["fall"]
    activate(rig,action,32)
    best=None
    for pitch in range(-105,-69,7):
        for roll in range(-28,29,14):
            for yaw in range(-30,31,15):
                turn=Quaternion((0,0,1),math.radians(yaw))
                side=Quaternion((0,1,0),math.radians(roll))
                tilt=Quaternion((1,0,0),math.radians(pitch))
                rotation=turn@side@tilt
                rig.rotation_quaternion=rotation
                bpy.context.view_layer.update()
                points=points_for(body_meshes)
                spans=[max(p[i] for p in points)-min(p[i] for p in points) for i in range(3)]
                score=spans[2]+2*max(0,max(spans[:2])-1.82)+.001*abs(yaw)
                if best is None or score<best[0]:
                    best=(score,rotation.copy())
    activate(rig,bpy.data.actions["idle"],0)
    staff=rig.pose.bones["staff"]
    staff_neutral=staff.matrix.copy()
    drop=Vector((0,0,1)).rotation_difference(Vector((.02,.999,.03)).normalized())
    target_rotation=drop@staff_neutral.to_quaternion()
    keys=[]
    for frame in range(33):
        activate(rig,action,frame)
        amount=min(1,max(0,(frame-13)/14))
        amount=amount*amount*(3-2*amount)
        rig.rotation_quaternion=rig.rotation_quaternion.slerp(best[1],amount)
        bpy.context.view_layer.update()
        current=rig.matrix_world@staff.matrix
        if amount>0:
            body_low=min(p.z for p in points_for(body_meshes))
            target=Vector((.34,-.96,body_low+.15))
            rotation=current.to_quaternion().slerp(target_rotation,amount)
            matrix=Matrix.LocRotScale(current.translation.lerp(target,amount),rotation,Vector((1,1,1)))
            staff.matrix=rig.matrix_world.inverted()@matrix
        keys.append((frame,rig.rotation_quaternion.copy(),staff.matrix_basis.copy()))
    for frame,rotation,pose in keys:
        rig.rotation_quaternion=rotation
        rig.keyframe_insert("rotation_quaternion",frame=frame)
        staff.matrix_basis=pose
        for prop in ("location","rotation_quaternion","scale"):
            staff.keyframe_insert(prop,frame=frame,group="staff")
    # The detached staff swings across the tile just before it lands. Turn
    # only as much as needed so its horns and the far hand clear that edge.
    rotations=[]
    yaw_options=(0,*[v for step in range(2,31,2) for v in (-step,step)])
    for frame in range(33):
        activate(rig,action,frame)
        points=points_for(meshes)
        def clearance(angle):
            c,s=math.cos(math.radians(angle)),math.sin(math.radians(angle))
            x=[c*p.x-s*p.y for p in points]
            y=[s*p.x+c*p.y for p in points]
            return max(max(x)-min(x),max(y)-min(y))
        angle=min(yaw_options,key=lambda a:max(0,clearance(a)-1.98)*10+abs(a)*.002)
        rotations.append(Quaternion((0,0,1),math.radians(angle))@rig.rotation_quaternion)
    for frame,rotation in enumerate(rotations):
        rig.rotation_quaternion=rotation
        rig.keyframe_insert("rotation_quaternion",frame=frame)


def create_king(palette):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    data = bpy.data.armatures.new("King weight-bearing rig")
    rig = bpy.data.objects.new("Armature", data)
    bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")

    def joint(name, head, tail, parent=None):
        bone = data.edit_bones.new(name)
        bone.head, bone.tail = head, tail
        if parent:
            bone.parent = data.edit_bones[parent]

    joint("root",(0,0,0),(0,0,.2))
    joint("pelvis",(0,.17,.63),(0,.16,.87),"root")
    joint("spine",(0,.15,.76),(0,.085,1.29),"pelvis")
    joint("head",(.06,-.23,1.10),(.075,-.30,1.45),"spine")
    joint("shoulder_R",(-.35,-.02,1.18),(-.51,-.17,.64),"spine")
    joint("forearm_R",(-.51,-.17,.64),(-.48,-.43,.22),"shoulder_R")
    joint("hand_R",(-.48,-.43,.22),(-.51,-.52,.10),"forearm_R")
    joint("shoulder_L",(.36,-.02,1.17),(.57,-.045,1.03),"root")
    joint("forearm_L",(.57,-.045,1.03),(.69,-.245,1.25),"shoulder_L")
    joint("hand_L",(.69,-.245,1.25),(.74,-.25,1.26),"forearm_L")
    for side,sign in (("L",1),("R",-1)):
        joint("thigh_"+side,(.25*sign,.17,.68),(.37*sign,-.04,.39),"root")
        joint("foot_"+side,(.37*sign,-.04,.39),(.36*sign,-.17,.09),"thigh_"+side)
    joint("staff",(.74,-.25,.01),(.74,-.25,1.26),"root")
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.context.view_layer.update()

    body, face, staff = Mesh(), Mesh(), Mesh()
    skin, mid, shade = "skin_high","skin_warm","skin_shadow"
    body.loft([(.48,.26,.19,0,.17),(.67,.42,.29,-.022,.15),
               (.95,.46,.30,-.031,.11),(1.19,.43,.29,-.022,.10),
               (1.39,.34,.24,-.042,.133),(1.49,.14,.15,-.066,.126)],
              "spine","skin", "skin_light",12,twist=.11)
    body.stone((.037,-.06,.77),(.34,.295,.37),"spine","skin","skin_light",10)
    body.stone((-.17,.078,1.30),(.32,.25,.24),"spine","skin","skin_light",9)
    body.loft([(.34,.38,.24,0,.135),(.46,.46,.32,-.024,.152),
               (.63,.44,.32,0,.157),(.72,.37,.26,0,.155)],
              "pelvis","maroon_dark","maroon",11,twist=.17)
    body.panel([(-.34,.64),(-.053,.61),(-.105,.32),(-.24,.45),(-.35,.34)],
               -.166,.043,"pelvis","maroon","maroon_dark")
    body.panel([(-.038,.62),(.31,.65),(.38,.35),(.25,.42),(.19,.27),(.04,.37)],
               -.174,.040,"pelvis","maroon_light","maroon_dark")
    body.loft([(.627,.431,.324,0,.148),(.68,.409,.303,0,.146)],
              "pelvis","leather","leather_light",12,twist=.09)
    for side,sign in (("L",1),("R",-1)):
        body.stone((.31*sign,.14,.43),(.191,.25,.28),"thigh_"+side,"skin_dark","skin",9)
        body.stone((.365*sign,.009,.22),(.136,.178,.182),"foot_"+side,"skin","skin_light",8)
        body.stone((.367*sign,-.104,.087),(.141,.204,.076),"foot_"+side,"skin_dark","skin",8)
        for i in range(3):
            body.stone((sign*.366+(i-1)*.058,-.252+abs(i-1)*.023,.056),
                       (.041,.077,.045),"foot_"+side,"skin","skin_light",6)
    for bone,start,end,radii in [
        ("shoulder_R",(-.30,.015,1.27),(-.53,-.13,.62),[(0,.18),(.26,.245),(.65,.207),(1,.136)]),
        ("forearm_R",(-.53,-.13,.67),(-.487,-.43,.25),[(0,.146),(.46,.16),(1,.118)]),
        ("shoulder_L",(.30,.04,1.18),(.57,-.050,1.02),[(0,.18),(.52,.196),(1,.121)]),
        ("forearm_L",(.57,-.050,1.01),(.69,-.245,1.25),[(0,.126),(.60,.129),(1,.099)]),
    ]:
        body.segment(start,end,radii,bone,"skin","skin_light",10)
    body.segment((-.49,-.389,.33),(-.492,-.45,.22),[(0,.133),(.50,.132),(1,.122)],
                 "forearm_R","leather","leather_light",8)
    body.stone((-.49,-.472,.148),(.139,.138,.127),"hand_R","skin_dark","skin_light",9)
    for i in range(4):
        body.stone((-.60+i*.062,-.548-abs(1.5-i)*.011,.073),
                   (.047,.105,.063),"hand_R","skin","skin_light",6)
    body.stone((.704,-.26,1.25),(.133,.116,.118),"hand_L","skin","skin_light",8)
    for i in range(4):
        body.segment((.787,-.32,1.15+.049*i),(.72,-.355,1.168+.047*i),
                     [(0,.038),(1,.035)],"hand_L","skin","skin_light",6)

    face.loft([(.989,.11,.115,.05,-.245),(1.07,.171,.147,.055,-.287),
               (1.19,.188,.147,.048,-.269),(1.31,.17,.142,.043,-.253),
               (1.405,.124,.111,.04,-.225),(1.44,.072,.075,.04,-.215)],
              "head","skin","skin_light",12,twist=.08)
    face.stone((.045,-.402,1.151),(.131,.075,.126),"head","skin","skin_light",9)
    face.stone((.065,-.418,1.247),(.061,.083,.068),"head","skin","skin_light",8)
    face.panel([(-.050,1.151),(.017,1.139),(.147,1.169),(.127,1.135),
                (.025,1.118),(-.045,1.13)],-.464,.025,"head","mouth","skin_dark")
    for x in (-.038,.137):
        face.stone((x,-.462,1.166),(.020,.021,.028),"head","bone_dark","bone",6)
    for side,sign in (("L",1),("R",-1)):
        x = .045 + .086*sign
        face.stone((x,-.391,1.281),(.068,.033,.049),"head","skin_dark","skin",8)
        face.stone((x,-.418,1.274),(.024,.018,.016),"head","ochre","brass_edge",6)
        face.segment((.045+sign*.128,-.204,1.246),(.045+sign*.383,-.16,1.343-.023*sign),
                     [(0,.081),(.38,.066),(.80,.029),(1,.004)],"head","skin","skin_light",7)
        face.segment((.045+sign*.144,-.177,1.36),(.045+sign*.213,-.086,1.089),
                     [(0,.037),(.6,.027),(1,.006)],"head","ash","worn",6)
    face.loft([(1.354,.167,.126,.041,-.231),(1.397,.165,.125,.041,-.227),
               (1.416,.143,.121,.041,-.227)],"head","iron","brass_dark",10,twist=.12)
    for angle,height in ((.55,.125),(3.63,.162),(5.07,.103)):
        x,y=.041+.154*math.cos(angle),-.225+.121*math.sin(angle)
        face.segment((x,y,1.388),(x+.046*math.cos(angle),y+.038*math.sin(angle),1.407+height),
                     [(0,.032),(.48,.023),(1,.003)],"head","iron","iron_edge",5)

    shaft = [( .715,-.242,.01),(.727,-.244,.63),(.747,-.249,1.21),(.724,-.232,1.55),(.706,-.22,1.75)]
    for start,end in zip(shaft,shaft[1:]):
        staff.segment(start,end,[(0,.046),(.50,.052),(1,.049)],"staff","wood_dark","wood_light",8)
    for z in (1.132,1.176,1.223,1.448):
        staff.loft([(z,.059,.055,.739,-.244),(z+.036,.060,.056,.737,-.241)],
                   "staff","leather","sack",8,twist=.08)
    staff.stone((.697,-.249,1.676),(.127,.105,.135),"staff","bone_dark","bone",8)
    staff.segment((.699,-.298,1.675),(.697,-.427,1.541),[(0,.094),(.56,.067),(1,.040)],
                  "staff","bone_dark","bone",8)
    for sign in (-1,1):
        staff.stone((.696+sign*.072,-.333,1.667),(.043,.035,.046),"staff","wood_dark","pelt_dark",7)
        horn=[(.696+sign*.086,-.249,1.746),(.696+sign*.158,-.236,1.788),
              (.696+sign*.198,-.195,1.858),(.696+sign*.169,-.17,1.918-.035*sign)]
        for start,end in zip(horn,horn[1:]):
            staff.segment(start,end,[(0,.038),(1,.018)],"staff","wood_dark","bone_dark",6)
    meshes = [part.finish(label,rig,palette) for part,label in
              ((body,"Body"),(face,"HeadAndCirclet"),(staff,"Staff"))]

    rig.animation_data_create()
    baseline={bone.name:bone.matrix_basis.copy() for bone in rig.pose.bones}

    def idle(arm, amount):
        rotate(arm.pose.bones["spine"],(-1.6*amount,0,0))
        rotate(arm.pose.bones["head"],(1.8*amount,0,-2*amount))

    def plant(arm, amount):
        # The support arm and staff stay planted while the torso shifts onto them.
        rotate(arm.pose.bones["spine"],(-5*amount,8*amount,-7*amount))
        rotate(arm.pose.bones["head"],(12*amount,-3*amount,7*amount))
        rotate(arm.pose.bones["shoulder_R"],(-7*amount,4*amount,0))
        rotate(arm.pose.bones["forearm_R"],(-6*amount,0,2*amount))

    def strike(arm, amount):
        # Negative is the weight shift and windup. The positive beat is a
        # downward blow with the free hand while the staff carries his weight.
        windup=max(0,-amount)
        impact=max(0,amount)
        bones=arm.pose.bones
        rotate(bones["spine"],(7*windup-7*impact,-7*windup+4*impact,
                               9*windup-6*impact))
        rotate(bones["head"],(-10*windup+15*impact,0,-7*impact))
        rotate(bones["shoulder_R"],(27*windup-9*impact,
                                   16*windup-5*impact,-8*windup+5*impact))
        rotate(bones["forearm_R"],(23*windup-9*impact,4*windup,3*impact))
        rotate(bones["hand_R"],(8*windup-14*impact,-7*windup,0))

    def stagger(arm, amount):
        bones=arm.pose.bones
        rotate(bones["spine"],(15*amount,-17*amount,12*amount))
        rotate(bones["head"],(12*amount,9*amount,-17*amount))
        rotate(bones["shoulder_R"],(-17*amount,19*amount,-6*amount))
        rotate(bones["forearm_R"],(-9*amount,0,5*amount))

    def fall(arm, amount):
        bones=arm.pose.bones
        turn=Quaternion((0,0,1),math.radians(-41)*amount)
        lean=Quaternion((1,0,0),math.radians(-86)*amount)
        arm.rotation_quaternion=turn@lean
        arm.location=(-.18*amount,-.52*amount,-.30*amount)
        rotate(bones["spine"],(-9*amount,5*amount,-6*amount))
        rotate(bones["head"],(8*amount,-9*amount,3*amount))
        rotate(bones["shoulder_R"],(-21*amount,8*amount,9*amount))
        rotate(bones["forearm_R"],(-14*amount,7*amount,-8*amount))
        rotate(bones["shoulder_L"],(7*amount,-35*amount,-3*amount))
        rotate(bones["forearm_L"],(19*amount,-10*amount,4*amount))
        rotate(bones["thigh_L"],(-18*amount,-8*amount,11*amount))
        rotate(bones["foot_L"],(27*amount,0,3*amount))
        # After release, keep the staff inside the same tile with a slight roll.
        rotate(bones["staff"],(-10*amount,1*amount,-10*amount))
        basis=bones["staff"].bone.matrix_local.to_3x3().inverted()
        bones["staff"].location+=basis@Vector((-.18,-.27,.12))*amount

    make_action(rig,"idle",baseline,[(0,0),(12,.8),(24,0),(36,-.8),(48,0)],idle)
    make_action(rig,"plant",baseline,[(0,0),(7,.38),(15,1),(22,1),(32,0)],plant)
    make_action(rig,"attack",baseline,[(0,0),(7,-.52),(13,-1),(18,1),
                (22,.76),(28,.24),(34,0)],strike)
    make_action(rig,"hurt",baseline,[(0,0),(4,1),(8,.54),(15,0)],stagger)
    make_action(rig,"fall",baseline,[(0,0),(7,.10),(15,.47),(22,.89),
                (27,1),(32,1)],fall)
    settle_collapse(rig,meshes)
    return rig,meshes
