"""Original overhead board figures based on the existing starting portraits."""
import bpy
from mathutils import Vector

from mesh_parts import Mesh

HEROES = {
    "mara": (1.64, .91, "cloth", "cloth_light", "Mara"),
    "corin": (1.80, 1.18, "leather", "leather_light", "Corin"),
    "alwen": (1.67, .98, "wool", "wool_light", "Sister Alwen"),
    "recruit": (1.71, 1.00, "moss", "moss_light", "Recruit"),
}


def rig_figure(width, tall):
    armature = bpy.data.armatures.new("Board figure joints")
    rig = bpy.data.objects.new("Armature", armature)
    bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")

    def joint(name, head, tail, parent=None):
        bone = armature.edit_bones.new(name)
        bone.head = (head[0]*width, head[1], head[2]*tall)
        bone.tail = (tail[0]*width, tail[1], tail[2]*tall)
        if parent:
            bone.parent = armature.edit_bones[parent]

    joint("root", (0, 0, .80), (0, 0, .92))
    joint("spine", (0, 0, .88), (0, 0, 1.31), "root")
    joint("head", (0, -.03, 1.44), (0, -.03, 1.67), "spine")
    for side, sign in (("L", 1), ("R", -1)):
        shoulder = (.21*sign, 0, 1.35)
        elbow = (.31*sign, -.035, 1.10)
        grip = (.29*sign, -.24, .99)
        hip = (.105*sign, .04, .87)
        knee = (.14*sign, -.06*sign, .48)
        ankle = (.16*sign, -.005-.07*sign, .108)
        joint("upperarm_"+side, shoulder, elbow, "spine")
        joint("forearm_"+side, elbow, grip, "upperarm_"+side)
        joint("hand_"+side, grip, (.29*sign, -.31, .97), "forearm_"+side)
        joint("thigh_"+side, hip, knee, "root")
        joint("shin_"+side, knee, ankle, "thigh_"+side)
        joint("foot_"+side, ankle, (.16*sign, ankle[1]-.12, .055), "shin_"+side)
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.context.view_layer.update()
    return rig


def make_hero(name, palette, animate):
    height, width, coat, highlight, _ = HEROES[name]
    tall = height / 1.72
    rig = rig_figure(width, tall)
    head, body, equipment = Mesh(), Mesh(), Mesh()

    def position(x, y, z):
        return (x*width, y, z*tall)

    def loft(mesh, rings, bone, base, light, sides=9, twist=.035):
        mesh.loft([(z*tall, x*width, y, xo*width, yo) for z, x, y, xo, yo in rings],
                  bone, base, light, sides, twist=twist)

    def stone(mesh, x, y, z, sx, sy, sz, bone, base, light, sides=8):
        mesh.stone(position(x,y,z), position(sx,sy,sz), bone, base, light, sides)

    def line(mesh, start, end, radii, bone, base, light, sides=7):
        mesh.segment(position(*start), position(*end), radii, bone, base, light, sides)

    def panel(mesh, outline, y, depth, bone, base, edge):
        mesh.panel([(x*width, z*tall) for x,z in outline], y, depth, bone, base, edge)

    loft(body, [(.78,.17,.12,0,.02),(.92,.19,.15,0,.015),(1.12,.22,.16,0,0),
                (1.31,.27,.175,0,.012),(1.40,.228,.155,0,.01),(1.45,.083,.078,0,-.025)],
         "spine", coat, highlight)
    # A broad sewn shoulder yoke stays readable from directly above.
    loft(body, [(1.30,.269,.179,0,.013),(1.386,.251,.166,0,.01),
                (1.43,.158,.121,0,0),(1.453,.086,.081,0,-.02)],
         "spine", highlight, coat, 9, .045)
    loft(body, [(.75,.16,.105,0,.02),(.88,.17,.12,0,.025),(.95,.15,.115,0,.018)],
         "root", "linen_dark", "pelt")
    loft(body, [(.88,.19,.153,0,.015),(.932,.195,.154,0,.015)],
         "spine", "leather", "leather_light", 9)
    panel(body, [(-.05,.882),(.055,.884),(.058,.928),(-.05,.93)], -.144, .021,
          "spine", "brass_dark", "brass")
    loft(head, [(1.405,.056,.057,0,-.018),(1.49,.061,.066,0,-.023)],
         "head", "skin_shadow", "skin_warm")
    jaw = .077 if name == "mara" else .086
    loft(head, [(1.478,jaw*.73,.070,0,-.035),(1.515,jaw,.09,0,-.041),
                (1.59,.103,.102,0,-.025),(1.669,.105,.101,0,-.01),
                (1.716,.079,.078,0,-.003),(1.73,.044,.048,0,-.002)],
         "head", "skin_warm", "skin_high", 10)
    stone(head, 0, -.126, 1.58, .028,.037,.033,"head","skin_warm","skin_high",6)
    for sign in (-1, 1):
        panel(head, [(sign*.023,1.607),(sign*.066,1.613),(sign*.070,1.599),
                     (sign*.029,1.591)], -.118, .015, "head", "hair", "skin_shadow")
        stone(head, sign*.103,-.025,1.566,.022,.034,.045,"head","skin_shadow","skin_warm",6)
    panel(head,[(-.042,1.527),(.035,1.530),(.044,1.516),(-.035,1.514)],
          -.121,.010,"head","skin_shadow","skin_warm")
    for side, sign in (("L",1),("R",-1)):
        def limb(start, end, radii, bone, base, light):
            line(body, (start[0]*sign,*start[1:]), (end[0]*sign,*end[1:]), radii,
                 bone+"_"+side, base, light)

        knee_y, boot_y = -.06*sign, -.005-.07*sign
        limb((.105,.04,.87),(.14,knee_y,.46),[(0,.101),(.43,.097),(1,.068)],
             "thigh","linen_dark","pelt")
        limb((.14,knee_y,.50),(.16,boot_y,.105),[(0,.065),(.4,.068),(1,.052)],
             "shin","pelt_dark","leather")
        stone(body,.16*sign,boot_y-.050,.070,.067,.126,.064,"foot_"+side,
              "wood_dark","leather",8)
        limb((.206,0,1.35),(.315,-.037,1.085),[(0,.103),(.47,.088),(1,.066)],
             "upperarm",coat if name != "corin" else "linen",highlight)
        limb((.312,-.04,1.113),(.29,-.24,.99),[(0,.070),(.58,.061),(1,.048)],
             "forearm","linen_dark" if name == "alwen" else "leather","linen")
        stone(body,.29*sign,-.24,.988,.046,.055,.053,"hand_"+side,"skin_warm","skin_high",7)
    if name == "mara":
        stone(head,-.014,.029,1.671,.124,.116,.091,"head","hair","hair_high")
        for x, end in [(-.091,1.386),(.084,1.464)]:
            line(head,(x,.053,1.668),(x*.70,.075,end),[(0,.059),(.65,.048),(1,.021)],
                 "head","hair","hair_high")
        line(head,(-.071,-.043,1.711),(.082,-.095,1.631),[(0,.052),(.65,.038),(1,.014)],
             "head","hair_high","hair")
        panel(body,[(-.174,1.36),(-.107,1.39),(.156,.935),(.09,.923)],-.172,.028,
              "spine","leather","leather_light")
        stone(body,.15,.09,.93,.075,.075,.096,"spine","sack","leather_light")
        panel(equipment,[(-.318,.96),(-.254,.974),(-.251,1.128),(-.293,1.27),
                         (-.33,1.133)],-.252,.029,"hand_R","iron_edge","iron")
    elif name == "corin":
        panel(head,[(-.087,1.562),(-.074,1.522),(-.051,1.49),(.037,1.495),
                    (.079,1.542),(.086,1.57),(.04,1.532),(-.037,1.53)],
              -.114,.025,"head","hair","hair_high")
        panel(head,[(.034,1.659),(.051,1.684),(.056,1.624),(.045,1.608)],
              -.105,.014,"head","scar","skin_shadow")
        for x in (-.145,-.095,-.045,.01,.065,.12,.171):
            line(body,(x,-.166,1.348-abs(x)*.17),(x*.87,-.151,.961),
                 [(0,.015),(.5,.016),(1,.009)],"spine","leather_light","cloth")
        stone(body,-.217,-.01,1.35,.115,.137,.063,"upperarm_R","leather","leather_light",7)
        panel(equipment,[(-.329,.948),(-.253,.942),(-.249,1.18),(-.265,1.55),
                         (-.299,1.60),(-.327,1.54)],-.255,.027,"hand_R","steel","iron")
        panel(equipment,[(-.377,1.034),(-.198,1.047),(-.197,1.091),(-.368,1.082)],
              -.267,.047,"hand_R","iron_edge","iron")
    elif name == "alwen":
        stone(head,0,.012,1.65,.135,.129,.103,"head","linen","cream",10)
        stone(head,-.009,.057,1.524,.127,.098,.087,"head","linen_dark","linen")
        for x in (-.086,.089):
            line(head,(x,-.069,1.693),(x*.87,-.076,1.49),[(0,.029),(.7,.024),(1,.011)],
                 "head","linen","cream")
        loft(body,[(1.21,.243,.144,0,.013),(1.31,.249,.152,0,.015),
                   (1.37,.215,.147,0,.013),(1.437,.096,.105,0,-.001)],
             "spine","wool","wool_light",10)
        panel(body,[(-.16,1.29),(.035,1.208),(.168,1.33),(.05,.952),(-.04,.96)],
              -.176,.032,"spine","wool","linen_dark")
        stone(body,.083,-.182,1.198,.029,.015,.037,"spine","brass_dark","brass_edge",6)
        line(equipment,(-.31,-.248,.35),(-.293,-.23,1.59),
             [(0,.026),(.5,.032),(.84,.027),(1,.044)],"hand_R","wood","wood_light")
        line(equipment,(-.291,-.23,1.53),(-.34,-.219,1.68),[(0,.041),(.65,.025),(1,.014)],
             "hand_R","wood_dark","wood_light")
        stone(equipment,-.29,-.233,1.531,.048,.037,.075,"hand_R","brass_dark","cream",6)
    else:
        loft(head,[(1.50,.109,.107,0,.01),(1.635,.12,.119,0,.003),
                   (1.74,.10,.10,0,.012),(1.79,.052,.058,0,.025)],
             "head","deep_olive","moss",9)
        stone(body,.002,.135,1.135,.154,.11,.202,"spine","leather","sack",8)
        stone(body,.003,.155,1.359,.164,.078,.046,"spine","sack","linen")
        for x in (-.113,.113):
            panel(body,[(x-.025,1.37),(x+.023,1.38),(x+.018,.919),(x-.016,.922)],
                  -.175,.024,"spine","leather","leather_light")
        line(equipment,(-.32,-.26,.79),(-.29,-.241,1.37),[(0,.033),(.64,.050),(1,.064)],
             "hand_R","wood","wood_light")
    meshes = [part.finish(label,rig,palette) for part,label in
              ((body,"Clothing"),(head,"Head"),(equipment,"Kit"))]
    animate(rig, name)
    return rig, meshes
