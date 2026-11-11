"""Build the remaining early-fight creatures from the proven source rigs."""
import math

import bpy
from mathutils import Vector

from mesh_parts import Mesh, prior_colours, set_uv

GOBLINS = ("goblin-archer", "goblin-guard", "goblin-drummer", "goblin-trapper", "goblin-queen")


def fit_goblin(name, rig, body, palette, string_mesh=None):
    x = body.data
    base = prior_colours(x, palette)
    if name == "goblin-queen":
        cloth = {"cloth": "maroon", "cloth_dark": "maroon_dark", "cloth_light": "maroon_light"}
    elif name == "goblin-drummer":
        cloth = {"cloth": "umber", "cloth_dark": "leather", "cloth_light": "brass_dark"}
    elif name == "goblin-trapper":
        cloth = {"cloth": "deep_olive", "cloth_dark": "charcoal", "cloth_light": "moss"}
    else:
        cloth = {}
    set_uv(x, palette, [cloth.get(colour, colour) for colour in base])
    for item in ("Knife", "Buckler"):
        obj = bpy.data.objects[item]
        if item == "Buckler" or name not in ("goblin-trapper", "goblin-archer"):
            bpy.data.objects.remove(obj, do_unlink=True)
        else:
            set_uv(obj.data, palette, prior_colours(obj.data, palette))

    costume, kit = Mesh(), Mesh()
    if name == "goblin-archer":
        grip = rig.matrix_world @ rig.pose.bones["hand_L"].head
        grip += Vector((.012, -.035, -.085))
        x, y, z = grip
        arc = [(x+.094,y+.028,z-.34),(x+.061,y-.019,z-.27),(x+.019,y-.043,z-.17),
               (x,y-.046,z),(x+.024,y-.035,z+.16),(x+.079,y-.013,z+.27),(x+.117,y+.034,z+.35)]
        for i,(first,last) in enumerate(zip(arc,arc[1:])):
            kit.segment(first,last,[(0,.021),(.5,.023),(1,.020)],"hand_L",
                        "wood_light" if i in (0,5) else "wood","sack",6)
        if string_mesh:
            string_mesh(kit, Vector(arc[0]), Vector(arc[-1]))
        else:
            kit.segment(arc[0],arc[-1],[(0,.008),(1,.007)],"hand_L","linen","cream",5)
        costume.segment((-.14,.20,.57),(.097,.20,1.02),[(0,.067),(.8,.055),(1,.056)],
                        "spine3","leather","leather_light")
        for i in range(4):
            x = .070 + .022*i
            costume.segment((x,.20,.91),(x+.035,.205,1.12+.02*(i%2)),[(0,.009),(1,.009)],
                            "spine3","wood_dark","sack",5)
            costume.stone((x+.031,.205,1.09+.02*(i%2)),(.025,.013,.043),
                          "spine3","linen","cream",5)
    elif name == "goblin-guard":
        shield = [(-.23,.88),(.03,.99),(.31,.89),(.29,.48),(.19,.36),
                  (.041,.28),(-.10,.35),(-.21,.51)]
        kit.panel(shield,-.30,.075,"hand_L","wood_light","iron")
        inner = [(.04+(x-.04)*.86,.68+(z-.68)*.87) for x,z in shield]
        kit.panel(inner,-.319,.022,"hand_L","wood","wood_dark")
        for x,z in ((-.177,.84),(.243,.85),(.229,.53),(-.161,.54),(.036,.35)):
            kit.stone((x,-.325,z),(.025,.018,.023),"hand_L","iron_edge","steel",6)
        kit.stone((.043,-.339,.683),(.095,.044,.085),"hand_L","iron","steel",8)
        costume.loft([(.965,.194,.138,0,-.06),(1.09,.196,.14,0,-.06),
                      (1.16,.166,.139,0,-.055),(1.23,.111,.09,0,-.04)],
                     "head","steel_dark","iron_edge",9,twist=.055)
        for x in (-.17,.17):
            costume.stone((x,.022,.914),(.085,.105,.085),"spine4","iron","iron_edge",7)
        grip = rig.matrix_world @ rig.pose.bones["hand_R"].head
        kit.segment(grip + Vector((0,-.03,-.20)),grip + Vector((-.036,-.055,.21)),
                    [(0,.025),(.5,.029),(1,.026)],"hand_R","wood_dark","leather_light")
        kit.stone(grip + Vector((-.039,-.059,.227)),(.064,.059,.077),"hand_R","iron","iron_edge",7)
    elif name == "goblin-drummer":
        costume.loft([(.48,.185,.122,0,-.155),(.57,.237,.153,0,-.155),
                      (.75,.236,.154,0,-.153),(.823,.186,.121,0,-.15)],
                     "spine2","wood","wood_light",12,twist=.04)
        for z in (.53,.771):
            costume.loft([(z,.210,.143,0,-.154),(z+.05,.232,.155,0,-.154)],
                         "spine2","leather","leather_light",12)
        costume.loft([(.803,.182,.12,0,-.154),(.836,.192,.127,0,-.154),
                      (.843,.171,.11,0,-.154)],"spine2","linen","cream",12)
        for i in range(8):
            ang = i * math.tau/8
            end = ang+.29*(-1 if i%2 else 1)
            costume.segment((.221*math.cos(ang),-.154+.149*math.sin(ang),.775),
                            (.215*math.cos(end),-.154+.147*math.sin(end),.56),
                            [(0,.009),(1,.009)],"spine2","sack","linen",5)
        for bone in ("hand_R","hand_L"):
            grip = rig.matrix_world @ rig.pose.bones[bone].head
            end = grip + Vector((.024,-.21,.20))
            kit.segment(grip,end,[(0,.017),(1,.016)],bone,"wood_dark","wood_light",6)
            kit.stone(end,(.035,.043,.039),bone,"linen","cream",6)
    elif name == "goblin-trapper":
        costume.loft([(.89,.14,.14,0,.06),(.98,.184,.173,0,.07),
                      (1.08,.158,.117,0,.086)],"spine4","deep_olive","moss")
        costume.stone((.171,.110,.66),(.118,.097,.143),"spine2","sack","leather_light")
        costume.stone((.177,.095,.81),(.058,.057,.042),"spine2","wood_dark","leather")
        # Three loops in the plane of the belt. The active coil stays hand-bound.
        for bone, centre, radius in (("spine2",(-.157,.076,.641),.093),
                                     ("hand_L",(.105,-.19,.54),.105)):
            for n in range(2):
                for i in range(9):
                    a,b = i*math.tau/9,(i+1)*math.tau/9
                    x,y,z = centre
                    rr = radius - n*.025
                    kit.segment((x+rr*math.cos(a),y-n*.016,z+rr*math.sin(a)),
                                (x+rr*math.cos(b),y-n*.016,z+rr*math.sin(b)),
                                [(0,.012),(1,.012)],bone,"sack","linen",5)
    else:
        costume.loft([(.32,.227,.16,0,.032),(.43,.258,.163,0,.045),
                      (.66,.202,.161,0,.039),(.75,.151,.135,0,.039)],
                     "spine2","maroon_dark","maroon",9,twist=.15)
        for outline, depth, colour in (
            ([(-.20,.68),(-.027,.67),(-.052,.31),(-.154,.41),(-.217,.30)],-.141,"maroon"),
            ([(-.013,.71),(.169,.68),(.222,.39),(.132,.43),(.051,.29)],-.133,"maroon_light"),
            ([(-.15,.86),(-.06,.93),(.097,.93),(.161,.87),(.099,.734),(-.104,.753)],-.104,"maroon"),
        ):
            costume.panel(outline,depth,.026,"spine2",colour,"maroon_dark")
        for x in (-.164,.171):
            costume.stone((x,.016,.91),(.093,.105,.073),"spine4","brass_dark","brass")
        costume.loft([(1.142,.151,.114,0,-.10),(1.19,.161,.118,0,-.098),
                      (1.211,.137,.104,0,-.099)],"head","brass_dark","brass",9,twist=.08)
        for i in range(7):
            angle = i*math.tau/7 + .19
            x,y = .148*math.cos(angle),-.10+.111*math.sin(angle)
            height = .109 if i in (4,5) else .056 + (i%3)*.016
            costume.segment((x,y,1.186),(x*1.33,-.1+(y+.1)*1.28,1.204+height),
                            [(0,.043),(.60,.026),(1,.005)],"head","brass","brass_edge",5)
        costume.stone((0,-.217,1.19),(.037,.022,.032),"head","maroon","red",6)
        # Uneven wedge with a wide chopping profile and a damaged cutting edge.
        kit.panel([(-.117,.48),(-.162,.70),(-.242,.684),(-.347,.517),(-.345,.468),
                   (-.372,.437),(-.355,.406),(-.372,.372),(-.333,.321),(-.242,.342),
                   (-.183,.489)],-.166,.050,"hand_R","iron","steel")
        kit.panel([(-.35,.51),(-.349,.469),(-.371,.437),(-.355,.406),(-.371,.372),
                   (-.333,.321),(-.24,.342),(-.253,.375),(-.326,.355),(-.333,.423)],
                  -.169,.014,"hand_R","steel","iron_edge")
        kit.segment((-.073,-.153,.54),(-.188,-.162,.627),[(0,.030),(1,.026)],
                    "hand_R","leather","wood_light",7)
    return [part.finish(label,rig,palette) for part,label in
            ((costume,"Costume"),(kit,"RoleKit"))]


def fit_broodmother(rig, body, palette):
    colours = prior_colours(body.data, palette)
    groups = {g.index:g.name for g in body.vertex_groups}
    for vertex in body.data.vertices:
        weight = max(vertex.groups, key=lambda group:group.weight, default=None)
        if weight and groups[weight.group] == "abdomen":
            vertex.co.x *= 1.26
            vertex.co.z += max(0,vertex.co.z-2.5)*.42
            vertex.co.y = .7+(vertex.co.y-.7)*1.19
    body.data.update()
    replacements = {"web_dark":"wood_dark","web_shell":"carapace","web_light":"carapace_light",
                    "joint":"bone_dark","shell":"umber","shell_light":"carapace_light",
                    "eye":"red"}
    set_uv(body.data,palette,[replacements.get(c,c) for c in colours])
    armour = Mesh()
    # Ridge plates sweep over the distended back and attach to the abdomen.
    for y,z,r in ((.37,.61,.219),(.22,.70,.254),(.044,.744,.273),(-.13,.689,.225)):
        for sign in (-1,1):
            armour.segment((sign*.015,y+.047,z+.029),(sign*r,y-.042,z-.15),
                            [(0,.034),(.43,.048),(.79,.032),(1,.012)],
                            "abdomen","carapace_light","bone_dark",6)
    for sign in (-1,1):
        armour.stone((sign*.17,-.17,.39),(.117,.139,.127),"thorax","bone_dark","bone",8)
        armour.segment((sign*.136,-.20,.33),(sign*.225,-.44,.14),
                        [(0,.069),(.52,.052),(1,.010)],"thorax","carapace","bone",7)
        armour.segment((sign*.23,-.40,.15),(sign*.157,-.48,.12),
                        [(0,.037),(1,.006)],"thorax","wood_dark","bone_dark",6)
    return armour.finish("Carapace",rig,palette)


def fit_great_rat(rig, body, palette, reference_png):
    img = bpy.data.images.load(str(reference_png),check_existing=False)
    data = list(img.pixels)
    width,height = img.size
    uv = body.data.uv_layers.active
    colours = []
    for face in body.data.polygons:
        mid = sum((uv.data[loop].uv.copy() for loop in face.loop_indices),Vector((0,0)))/len(face.loop_indices)
        x,y = int(mid.x*(width-1)),int(mid.y*(height-1))
        red,green,blue = data[(y*width+x)*4:(y*width+x)*4+3]
        light = (red+green+blue)/3
        if red > green*1.5 and light > .16:
            colour = "skin_shadow"
        elif light > .56:
            colour = "bone"
        elif light > .31:
            colour = "pelt_high"
        elif light > .17:
            colour = "pelt"
        else:
            colour = "pelt_dark"
        colours.append(colour)
    set_uv(body.data,palette,colours)
    for v in body.data.vertices:
        v.co.x *= 1.10
    accents = Mesh()
    for sign in (-1,1):
        accents.stone((sign*.117,-.575,.423),(.066,.05,.078),"head","pelt_high","skin_shadow",7)
        accents.stone((sign*.115,-.646,.328),(.023,.02,.023),"head","red","charcoal",6)
        accents.segment((sign*.062,-.781,.203),(sign*.059,-.813,.157),
                        [(0,.023),(1,.013)],"mouth","bone","cream",6)
    for x,y,z in ((-.06,.06,.48),(.025,-.02,.489),(.05,-.085,.46)):
        accents.stone((x,y,z),(.071,.092,.029),"spine","pelt_high","fur_gray",7)
    return accents.finish("FangsAndPelt",rig,palette)
