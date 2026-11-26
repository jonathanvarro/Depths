"""#302 C/D: metric cave dressing and solid replacements for early flat props.

Reuses the project's original worked-prop geometry. Blender background only;
editable separate-piece masters stay in the owner's ignored build directory.
"""
import argparse
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import random
import sys
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location('damp_dressing_primitives', ROOT/'tools/mine_polish/build_models.py')
P = importlib.util.module_from_spec(spec); spec.loader.exec_module(P)
G = P.G
parser = argparse.ArgumentParser()
parser.add_argument('--workspace', type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
ART = ROOT/'art/dressing/damp-dressing-v1'
MASTERS = args.workspace/'build/local-damp-dressing-v1/masters'
ART.mkdir(parents=True, exist_ok=True); MASTERS.mkdir(parents=True, exist_ok=True)
(MASTERS/'.gdignore').write_text('')
PALETTE = {'wet_rock':'687779','wet_dark':'36484a','calcite':'a8b2a6','silt':'555d51',
 'mud':'3b493f','moss':'354c3c','moss_tip':'5a6950','root_wet':'514b39','root_cut':'88836b',
 'fungus_cap':'70896e','fungus_under':'a4b198','fungus_dark':'354e43','chalk':'d8d2b6',
 'water':'293f42','pearl':'b2b6a0','iron_worn':'4e5954','rust':'6b4733',
 'cloth':'555e4e','cloth_red':'6c3733','leather':'4b3d2d','grain':'afa07a','soot':'262d29',
 'silk':'a4afa4','wood_grey':'685c45','wood_dark':'3b3e31','wood_cut':'91806a',
 'flowstone':'829184','mineral_stain':'48584e'}
for name, colour in PALETTE.items():
    G.COLOURS[name] = colour
    material = bpy.data.materials.new(name)
    material.diffuse_color = (*(int(colour[i:i+2],16)/255 for i in (0,2,4)),1)
    G.MATERIALS[name] = material


def tube(name, points, radii, material='root_wet', sides=6, open_end=False):
    points=[Vector(p) for p in points];vertices=[]
    for index,(point,radius) in enumerate(zip(points,radii)):
        direction=(points[min(index+1,len(points)-1)]-points[max(index-1,0)]).normalized()
        a=direction.cross(Vector((0,1,0)) if abs(direction.y)<.9 else Vector((1,0,0))).normalized();b=direction.cross(a)
        for i in range(sides):
            angle=i*math.tau/sides;vertices.append(point+radius*(a*math.cos(angle)+b*math.sin(angle)))
    faces=[tuple(reversed(range(sides)))]
    if not open_end:faces.append(tuple(range((len(points)-1)*sides,len(points)*sides)))
    for ring in range(len(points)-1):
        for i in range(sides):
            j=(i+1)%sides;faces.append((ring*sides+i,ring*sides+j,(ring+1)*sides+j,(ring+1)*sides+i))
    obj=G.mesh_object(name,vertices,faces,material)
    for face in obj.data.polygons:face.use_smooth=True
    return obj


def rock(name, at, size, seed=1, material='wet_rock'):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1,location=at)
    obj=bpy.context.object;obj.name=name;obj.scale=size;rng=random.Random(seed)
    for v in obj.data.vertices:v.co*=1+.05*math.sin(v.co.z*16+seed)+rng.uniform(-.035,.035)
    obj.data.materials.append(G.MATERIALS[material])
    for face in obj.data.polygons:face.use_smooth=True
    return obj


def patch(name,rx,ry,material,z=.006,at=(0,0),seed=1,bulge=0):
    """Irregular relief fan with a finite rim, no alpha poster or coplanar face."""
    rng=random.Random(seed);n=24;vertices=[(at[0],at[1],z+bulge)]
    for i in range(n):
        a=i*math.tau/n;r=rng.uniform(.86,1.0)
        vertices.append((at[0]+math.cos(a)*rx*r,at[1]+math.sin(a)*ry*r,z))
    obj=G.mesh_object(name,vertices,[(0,i+1,(i+1)%n+1) for i in range(n)],material)
    for face in obj.data.polygons:face.use_smooth=True
    return obj


def wall_sheet(name='Flowstone flutes',width=1.10,height=1.18,material='flowstone',depth=.15):
    # Back plane is Blender Y=0; negative Y faces into the room (+Z in Godot).
    vertices=[];nx,nz=19,11
    for j in range(nz):
        t=j/(nz-1);z=(t-.5)*height
        for i in range(nx):
            u=i/(nx-1)
            x=(u-.5)*width*(.73+.25*math.sin(t*math.pi)+.025*math.sin(t*19))+.025*math.sin(t*11)
            envelope=math.sin(u*math.pi)**.45*math.sin(t*math.pi)**.6
            d=.006+envelope*depth*(.55+.3*math.cos(u*math.pi*12+t*.9)+.13*math.sin(u*math.pi*28))
            vertices.append((x,-d,z+.065*math.sin(u*17)*(1-.4*t)+.024*math.sin(u*39)))
    faces=[]
    for j in range(nz-1):
        for i in range(nx-1):a=j*nx+i;faces.append((a,a+1,a+1+nx,a+nx))
    obj=G.mesh_object(name,vertices,faces,material)
    for face in obj.data.polygons:face.use_smooth=True
    return obj


def mineral_seep(crack=False):
    for i in range(7):
        x=-.27+i*.086;h=.20+.52*((i*7%11)/11)
        tube('Thin mineral stain',[(x,-.022,.44),(x+.01,-.024,.20),(x-.015,-.020,.44-h-.13)],
             [.027,.017,.001],'mineral_stain',6)
        tube('Calcite runnel',[(x, -.031,.44),(x+.016,-.048,.22),(x-.017,-.037,.44-h)],
             [.012,.010,.002],'calcite' if i%3 else 'moss',5)
    if crack:
        tube('Open dark fissure',[(-.18,-.055,.39),(.02,-.058,.14),(-.04,-.051,-.10),(.14,-.045,-.42)],
             [.009,.017,.012,.002],'soot',5)


def flowstone():
    wall_sheet(depth=.095)
    for i in range(7):
        x=-.40+i*.13;bottom=-.37-.13*math.sin(i*1.7)
        tube('Calcite fluted cascade',[(x,-.040,.48),(x+.016,-.067,.28),(x-.010,-.093,.02),
             (x+.025,-.060,bottom+.13),(x+.028,-.007,bottom)],
             [.036,.051,.045,.026,.003],'flowstone',8)


def moss(wall=True):
    rng=random.Random(77)
    # Irregular disconnected growth merging into tufts, never a rectangular substrate.
    if wall:
        for i in range(14):
            a=i*math.tau/14;r=.18+.07*math.sin(i*2.1)
            rock('Moss creeping pad',(math.cos(a)*r,-.028,math.sin(a)*r),(.11,.022,.071),i,'moss')
    for i in range(26):
        a=rng.uniform(0,math.tau);r=rng.uniform(.06,.31)
        x=math.cos(a)*r;z=math.sin(a)*r*.70
        if wall:
            tube('Wet moss tuft',[(x,-.027,z+.04),(x+.015,-.045,z),(x-.007,-.047,z-.04)],
                 [.007,.012,.002],'moss_tip',5)
        else:rock('Creeping exit mold',(x,z,.012),(.084,.063,.014),i,'moss_tip' if i%5==0 else 'moss')


def pearl_niche():
    wall_sheet('Scalloped niche back',.68,.54,'wet_dark',.09)
    for i in range(9):
        a=i*math.pi/8
        rock('Calcite niche lip',(.30*math.cos(a),-.115,-.15+.14*math.sin(a)),(.075,.08,.045),i,'calcite')
    for i,(x,z,r) in enumerate([(-.12,-.12,.036),(-.04,-.15,.046),(.06,-.13,.034),(.15,-.15,.039),(.02,-.07,.026)]):
        rock('Embedded cave pearl',(x,-.14,z),(r,r,r*.83),i,'pearl')
    rock('Calcite niche shelf',(0,-.145,-.20),(.29,.13,.030),57,'calcite')


def straws(single=False):
    rng=random.Random(59)
    for i in range(1 if single else 13):
        x=0 if single else rng.uniform(-.32,.32);y=0 if single else rng.uniform(-.18,.18);length=.63 if single else rng.uniform(.12,.53)
        tube('Hollow calcite straw',[(x,y,0),(x+.008,y,-length*.65),(x+.012,y+.007,-length)],
             [.018 if not single else .105,.012 if not single else .044,.007],'calcite',7,open_end=not single)
        if not single:
            # True annular mouth and a shallow dark throat, not a solid capped stick.
            vertices=[];n=7
            for r,z in [(.007,-length),(.004,-length),(.004,-length+.025)]:
                for j in range(n):
                    a=j*math.tau/n;vertices.append((x+.012+r*math.cos(a),y+.007+r*math.sin(a),z))
            faces=[]
            for ring in range(2):
                for j in range(n):faces.append((ring*n+j,ring*n+(j+1)%n,(ring+1)*n+(j+1)%n,(ring+1)*n+j))
            faces.append(tuple(range(n*2,n*3)))
            G.mesh_object('Calcite open mouth and throat',vertices,faces,'calcite')


def roots(kind):
    rng=random.Random(103 if kind!='curtain-b' else 104)
    ceiling=kind in ['hanging','curtain-a','curtain-b','moss-curtain']
    count=10 if ceiling else 5
    for i in range(count):
        if ceiling:
            x=-.64+i*1.28/(count-1);y=rng.uniform(-.10,.10);length=rng.uniform(.23,.45) # >=1.75m under 2.2m roof
            points=[(x,y,0),(x+.03,y-.018,-length*.4),(x-.025,y+.05,-length*.8),(x+.04,y+.06,-length)]
        else:
            a=i*math.tau/count
            if kind=='crossing':points=[(-.8,.08,.025),(-.28,.04,.065),(.26,-.04,.047),(.78,-.11,.013)]
            else:points=[(math.cos(a)*.06,math.sin(a)*.07,.15),(math.cos(a)*.22,math.sin(a)*.20,.07),(math.cos(a)*.45,math.sin(a)*.35,.01)]
        radii=[.018,.016,.010,.002] if len(points)==4 else [.04,.027,.003]
        tube('Damp fibrous root',points,radii,'moss' if kind=='moss-curtain' else 'root_wet',7)
        p=Vector(points[-2]);tube('Fine root fork',[p,p+Vector((.07,.03,-.025)),p+Vector((.12,.04,-.09 if ceiling else -.025))],
                                 [.006,.004,.001],'moss_tip' if kind=='moss-curtain' else 'root_cut',5)
        if kind=='crossing':break


def rimstone():
    for row in range(3):
        z=.028+row*.065;r=.50-row*.10
        points=[(math.cos(a)*r,math.sin(a)*r*.52+.12,z) for a in [i*math.pi/16 for i in range(17)]]
        tube('Rimstone scalloped terrace',points,[.022]*len(points),'calcite',6)
        patch('Still terrace water',r*.90,r*.32,'water',z-.01,(0,.16),row)


def rubble(count=12,wide=False):
    rng=random.Random(142)
    for i in range(count):
        x=rng.uniform(-.53,.53);y=rng.uniform(-.22,.22)
        radius=rng.uniform(.07,.18) if not wide else rng.uniform(.025,.065)
        rock('Fractured wet gravel' if wide else 'Broken limestone',(x,y,radius*.35),(radius,radius*.7,radius*.5),i)


def plank(at=(-.06,0,.04),end=(.54,.20,.04),width=.16):
    P.beam('Rotted split plank',at,end,width,.045,'wood_grey',74)
    tube('Long rotten split',[Vector(at)+Vector((0,0,.028)),(Vector(at)+Vector(end))*.5+Vector((0,0,.025)),Vector(end)+Vector((0,0,.027))],
         [.003,.008,.002],'wood_dark',4)


def bucket():
    n=12;vertices=[]
    for radius,z in [(.15,.025),(.21,.35),(.185,.35),(.126,.05)]:
        for i in range(n):a=i*math.tau/n;vertices.append((radius*math.cos(a),radius*math.sin(a),z))
    faces=[]
    for ring in range(3):
        for i in range(n):faces.append((ring*n+i,ring*n+(i+1)%n,(ring+1)*n+(i+1)%n,(ring+1)*n+i))
    faces.append(tuple(reversed(range(3*n,4*n))))
    obj=G.mesh_object('Open staved bucket',vertices,faces,'wood_grey')
    obj.data.materials.append(G.MATERIALS['wood_dark'])
    for face in obj.data.polygons:
        if face.index>=2*n:face.material_index=1
    for z,r in [(.09,.16),(.29,.197)]:P.ring('Rusted bucket hoop',(0,0,z),r,'rust',rotation=(0,0,0),wire=.012)
    tube('Bent bucket bail',[(-.20,0,.29),(-.16,0,.52),(0,0,.58),(.16,0,.51),(.20,0,.29)],[.009]*5,'iron_worn',6)


def dead_lamp(at=(0,0,0)):
    x,y,z=at
    P.box('Lamp dry oil reservoir',(x,y,z+.065),(.20,.16,.13),'iron_worn')
    P.box('Gnawed black wick',(x,y,z+.14),(.035,.027,.025),'soot')
    for dx in [-.082,.082]:
        for dy in [-.062,.062]:tube('Bent empty lamp cage',[(x+dx,y+dy,z+.11),(x+dx*1.07,y+dy,z+.26),(x+dx*.7,y+dy*.8,z+.31)],[.008,.007,.008],'rust',5)
    P.box('Rusted vented hood',(x,y,z+.32),(.21,.17,.035),'iron_worn')
    tube('Old lamp handle',[(x-.06,y,z+.34),(x-.05,y,z+.41),(x+.05,y,z+.41),(x+.06,y,z+.34)],[.008]*4,'iron_worn',6)


def debris():
    plank((-.50,-.04,.03),(.32,.20,.035))
    before=set(bpy.context.scene.objects);bucket()
    for obj in set(bpy.context.scene.objects)-before:obj.location*=.68;obj.location+=Vector((.30,-.03,0));obj.scale*=.68
    dead_lamp((-.18,-.20,.015))


def puddle(wide=False):
    patch('Shallow opaque water',.77 if wide else .38,.47 if wide else .25,'water',.007,seed=88)
    # A few tapered wet edges are three-dimensional, with no raised solid pool lid.
    for i in range(4):
        x=-.27+i*.17
        tube('Silt shoreline',[(x-.12,.23,.008),(x,.26,.010),(x+.10,.24,.008)],[.002,.005,.001],'silt',5)


def silt(prints=False,drag=False):
    patch('Damp silt relief',.61,.42,'silt',.004,seed=25,bulge=.009)
    if prints:
        for step in range(3):
            x=-.30+step*.29;y=.11 if step%2 else -.12
            patch('Old boot toe',.069,.12,'mud',.016,(x,y),step)
            patch('Old square heel',.065,.047,'mud',.016,(x,y-.16),step+7)
            for j in range(3):tube('Worn tread silt',[(x-.047,y-.05+j*.05,.017),(x+.045,y-.052+j*.05,.017)],[.003,.003],'silt',4)
    else:
        for i in range(7):
            y=-.25+i*.078
            points=[(-.5+j*.125,y+.024*math.sin(j*1.1+i),.012+(i%2)*.003) for j in range(9)]
            if drag:points=[(x,y*.33+.1*(i%2),z) for x,y,z in points]
            tube('Settled drag groove' if drag else 'Silt current ripple',points,[.003]+[.008]*7+[.002],'mud',5)


def crack(floor=False):
    if floor:
        points=[(-.56,-.22,.007),(-.2,-.08,.009),(.03,-.12,.008),(.22,.04,.007),(.55,.18,.006)]
        tube('Dark recessed fracture',points,[.003,.014,.016,.009,.002],'soot',5)
        tube('Raised broken lip',[(x,y+.012,z+.004) for x,y,z in points],[.002,.007,.009,.005,.001],'wet_dark',4)
    else:
        mineral_seep(True)
        # Lower wall rubble is a separate depth silhouette, centre aligned to legacy anchor.
        for i in range(6):rock('Rubble caught below crack',(-.33+i*.13,-.10,-.36),(.12,.08,.07),i)


def chalk(kind):
    shapes={'arrow':[[(-.3,-.08),(.29,.13)],[(.10,.24),(.29,.13),(.16,-.05)]],
            'cross':[[(-.20,-.23),(.20,.23)],[(-.20,.23),(.20,-.23)]],
            'tally':[[(-.24+i*.12,-.22),(-.21+i*.12,.22)] for i in range(4)]+[[(-.31,-.11),(.26,.12)]]}
    for line in shapes[kind]:
        pts=[(x,-.006,z) for x,z in line]
        tube('Broken chalk stroke',pts,[.010]*len(pts),'chalk',5)


def web():
    # Fine sagging upper-wall/ceiling web, genuine curves rather than a billboard.
    spokes=[]
    for i in range(7):
        end=Vector((-.62+i*.205,.015,-.02-(i%2)*.06));centre=Vector((.08,-.12,-.36))
        pts=[end,end*.5+centre*.5+Vector((0,-.02,-.02)),centre]
        tube('Silk support thread',pts,[.002,.0025,.001],'silk',4);spokes.append(end)
    for ring in [.28,.48,.70,.89]:
        pts=[Vector((.08,-.12,-.36)).lerp(p,ring)+Vector((0,-.012,-.015*math.sin(i))) for i,p in enumerate(spokes)]
        tube('Sagging silk spiral',pts,[.0015]*len(pts),'silk',4)


def nest():
    patch('Packed dark nest',.33,.24,'mud',.008,bulge=.05,seed=71)
    for i in range(22):
        a=i*math.tau/22
        tube('Shredded nest straw',[(math.cos(a)*.31,math.sin(a)*.23,.035),(math.cos(a+.2)*.21,math.sin(a+.2)*.16,.07),(math.cos(a+.5)*.30,math.sin(a+.5)*.22,.03)],
             [.003,.006,.002],'root_cut' if i%3 else 'wood_dark',5)
    for i in range(3):rock('Gnawed bone scrap',(-.12+i*.10,.03,.035),(.06,.015,.014),i,'calcite')


def scorch():
    patch('Old black fire stain',.48,.32,'soot',.005,seed=7)
    for i in range(6):plank((-.26+i*.07,-.12,.022),(-.16+i*.07,.13,.025),.025)
    for obj in bpy.context.scene.objects:
        if obj.type=='MESH' and obj.name.startswith('Rotted'):obj.data.materials.clear();obj.data.materials.append(G.MATERIALS['soot'])


def crate():
    # Broken open corner, split staves, bent hoop/nails; not an intact loot container.
    for i in range(5):P.beam('Crate floor board',(-.30+i*.13,-.24,.035),(-.30+i*.13,.24,.035),.115,.045,'wood_grey',i)
    for side in [-1,1]:
        for i in range(3):
            z=.12+i*.11
            P.beam('Collapsed crate side',(-.32,side*.25,z),(.12 if i==2 else .31,side*.25,z+.015),.09,.035,'wood_grey',i+8)
        P.beam('Crate corner binding',(-.32,side*.25,.02),(-.29,side*.25,.41),.055,.055,'wood_dark',18)
    plank((-.34,-.12,.04),(.41,.17,.18),.12)
    for x in [-.26,.25]:P.nail((x,-.275,.10),'rust',.013)
    for i in range(5):
        x=-.24+i*.11
        tube('Splintered crate seam',[(x,-.273,.075),(x+.021,-.274,.17),(x-.008,-.273,.23)],[.003,.005,.001],'wood_dark',4)
    for i in range(4):rock('Small wet rot deposit',(-.29+i*.17,.23,.06),(.07,.025,.02),i,'moss')


def barrel():
    n=10
    for i in range(n):
        if i in [7,8]:continue
        a=i*math.tau/n;b=(i+1)*math.tau/n
        vertices=[]
        for z,r in [(.025,.19),(.28,.25),(.51 if i%3 else .37,.20)]:
            vertices.extend([(r*math.cos(a),r*math.sin(a),z),(r*math.cos(b),r*math.sin(b),z)])
        G.mesh_object('Split barrel stave',vertices,[(0,1,3,2),(2,3,5,4)],'wood_grey')
    for z,r in [(.10,.215),(.39,.227)]:
        pts=[(r*math.cos(i*math.tau/n),r*math.sin(i*math.tau/n),z) for i in range(9)]
        tube('Broken barrel hoop',pts,[.010]*len(pts),'rust',5)
    plank((.13,-.22,.025),(.45,-.15,.025),.11)
    patch('Silt in barrel base',.185,.185,'mud',.028)


def banner():
    nx,ny=7,11;vertices=[]
    for j in range(ny):
        for i in range(nx):
            x=(i/(nx-1)-.5)*.43;y=(j/(ny-1)-.5)*.92
            if j==ny-1:y-=.08*(i%2)
            vertices.append((x,y,.018+.014*math.sin(i*1.8+j*.6)))
    faces=[]
    for j in range(ny-1):
        for i in range(nx-1):a=j*nx+i;faces.append((a,a+1,a+nx+1,a+nx))
    G.mesh_object('Torn fallen royal cloth',vertices,faces,'cloth_red')
    P.beam('Broken banner pole',(-.34,-.43,.043),(.30,-.43,.041),.027,.028,'wood_grey',71)
    for i in range(3):tube('Faded stitched royal rays',[(0,-.15,.04),(-.12+i*.12,.12,.041)],[.003,.003],'grain',4)


def grain():
    patch('Rotten grain stain',.47,.29,'mud',.006,seed=93)
    rng=random.Random(91)
    for i in range(38):
        x=rng.uniform(-.38,.38);y=rng.uniform(-.21,.21)
        rock('Spilled sodden seed',(x,y,.013),(.012,.023,.009),i,'grain' if i%5 else 'moss')


def mushrooms():
    for k,(x,y,h,r) in enumerate([(-.3,.04,.23,.16),(-.11,.12,.33,.19),(.17,.03,.19,.15),(.32,.10,.12,.09),(.03,-.13,.13,.10)]):
        tube('Pale branching stem',[(x,y,.005),(x+.014,y,h*.7),(x+.024,y,h)],[.02,.015,.011],'fungus_under',7)
        vertices=[];n=12
        for rf,dz in [(.73,-.025),(1,0),(.75,.06),(0,.09)]:
            for i in range(n):a=i*math.tau/n;vertices.append((x+.024+r*rf*math.cos(a),y+r*rf*math.sin(a),h+dz))
        faces=[tuple(reversed(range(n)))]
        for row in range(3):
            for i in range(n):faces.append((row*n+i,row*n+(i+1)%n,(row+1)*n+(i+1)%n,(row+1)*n+i))
        obj=G.mesh_object('Muted damp exit cap',vertices,faces,'fungus_cap')
        obj.data.materials.append(G.MATERIALS['fungus_under']);obj.data.polygons[0].material_index=1
        for i in range(6):
            a=i*math.tau/6;tube('Exposed cap gill',[(x,y,h-.024),(x+r*.66*math.cos(a),y+r*.66*math.sin(a),h-.024)],[.002,.001],'fungus_under',4)


def stash(empty=False):
    patch('Scuffed stash floor',.48,.28,'mud',.009,seed=42)
    # A real hollow puckered bag, not a ring of round stones.
    vertices=[];n=14
    for radius,z in [(.105,.02),(.185,.10),(.164,.22),(.127,.257),(.108,.246),(.12,.11)]:
        for i in range(n):
            a=i*math.tau/n;r=radius*(1+.07*math.sin(i*2.4))
            vertices.append((-.19+r*math.cos(a),r*.76*math.sin(a),z+.009*math.sin(i*2)))
    faces=[]
    for ring in range(5):
        for i in range(n):faces.append((ring*n+i,ring*n+(i+1)%n,(ring+1)*n+(i+1)%n,(ring+1)*n+i))
    obj=G.mesh_object('Puckered hollow leather pouch',vertices,faces,'leather')
    obj.data.materials.append(G.MATERIALS['soot'])
    for face in obj.data.polygons:
        face.use_smooth=True
        if face.index>=4*n:face.material_index=1
    patch('Dark pouch interior',.12,.085,'soot',.105,(-.19,0),19)
    for i in range(5):
        a=i*math.tau/5;tube('Worn pouch seam',[(-.19+.108*math.cos(a),.083*math.sin(a),.03),
            (-.19+.187*math.cos(a),.143*math.sin(a),.10),(-.19+.164*math.cos(a),.126*math.sin(a),.21)],
            [.002,.003,.002],'root_cut',4)
    tube('Discarded binding',[(.06,.16,.01),(.18,.18,.03),(.30,.10,.018),(.38,-.06,.016)],[.008]*4,'root_cut',6)
    for i in range(3):rock('Small stash stone',(-.39+i*.12,.22,.035),(.08,.055,.043),i)
    if not empty:
        for i in range(4):rock('Lumpy tied provisions',(-.25+i*.04,-.01,.25),(.038,.041,.026),i,'cloth')
        P.beam('Stolen knife grip',(.12,-.10,.03),(.27,-.04,.03),.036,.03,'leather',14)
        G.mesh_object('Stolen nicked blade',[(.27,-.065,.034),(.53,.015,.034),(.30,-.012,.034),(.27,-.065,.045)],[(0,1,2),(0,3,1),(1,3,2)],'iron_worn')


def lamp_store(used=False):
    for x in [-.50,.50]:P.beam('Lamp shelf upright',(x,0,.005),(x,.02,.96),.075,.09,'wood_dark',3)
    for z in [.15,.73]:
        for y in [-.10,.015,.13]:P.beam('Slatted lamp shelf',(-.55,y,z),(.55,y,z),.10,.045,'wood_grey',6)
    for x in [-.35,0,.35]:dead_lamp((x,0,.18))
    for x in ([-.34,.02,.30] if not used else [-.34]):
        rock('Sealed oil flask',(x,.02,.80),(.055,.055,.075),int(x*30),'iron_worn')
        P.box('Flask wax stopper',(x,.02,.89),(.039,.036,.026),'leather')
    for x in [-.4,.4]:P.nail((x,-.15,.73),'rust',.012)


def three_knocks(used=False):
    for x in [-.56,.56]:P.beam('Old mining frame',(x,.04,.02),(x,.09,1.32),.13,.14,'wood_dark',int(x*20))
    P.beam('Split lintel',(-.64,.07,1.32),(.64,.07,1.32),.14,.16,'wood_grey',21)
    # The resolved scene stays obstructed at the back: no traversable exit is promised.
    wall_sheet('Dark collapsed recess',1.02,.98,'wet_dark',.06).location=Vector((0,.20,.69))
    rng=random.Random(111)
    for i in range(16):
        x=rng.uniform(-.58,.58);y=rng.uniform(-.18,.18);z=rng.uniform(.07,.37)
        if not used:z+=max(0,.63-abs(x))*.83
        rock('Excavated fall stone' if used else 'Packed fall stone',(x,y,z),(.19,.14,.14),i)
    P.beam('Braced diagonal beam',(-.57,-.20,.08),(.52,-.14,.98 if not used else 1.11),.13,.13,'wood_grey',41)
    # Abandoned tin cup in both states is part of the written clue.
    before=set(bpy.context.scene.objects);bucket()
    for obj in set(bpy.context.scene.objects)-before:obj.scale*=.23;obj.location*=.23;obj.location+=Vector((.48,-.38,.005))


def family(name):
    if name in ['flowstone','mineral_stain']:return 7
    if name.startswith('wood') or name.startswith('root') or name=='leather':return 1
    if name.startswith(('moss','fungus')) or name=='cloth':return 2
    if name in ['chalk','pearl','silk','grain']:return 3
    if name=='water':return 4
    if name in ['iron_worn','rust']:return 5
    if name in ['silt','mud','soot','cloth_red']:return 6
    return 0


def export(ident,build,mount):
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    build();bpy.context.view_layer.update()
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
    bpy.ops.wm.save_as_mainfile(filepath=str(MASTERS/(ident+'.blend')),check_existing=False)
    groups={};all_points=[]
    for number,obj in enumerate(objects):
        for face in obj.data.polygons:
            name=obj.data.materials[face.material_index].name.split('.')[0]
            group='Surface' # One physical material, branch selected by UV2; no transparent body.
            vertices,faces,uvs,colours,flags,normals=groups.setdefault(group,([],[],[],[],[],[]))
            normal=(obj.matrix_world.to_3x3()@face.normal).normalized();dominant=max(range(3),key=lambda i:abs(normal[i]))
            first=len(vertices);rgb=[P.linear(int(G.COLOURS[name][i:i+2],16)/255) for i in (0,2,4)]
            for index in face.vertices:
                point=obj.matrix_world@obj.data.vertices[index].co
                vertices.append(point);all_points.append(point)
                source_normal=obj.data.vertices[index].normal if face.use_smooth else face.normal
                normals.append((obj.matrix_world.to_3x3().inverted().transposed()@source_normal).normalized())
                uvs.append([(point.y,point.z),(point.x,point.z),(point.x,point.y)][dominant])
                colours.append((*rgb,1));flags.append((family(name),(number*.61803398875)%1))
            faces.append(tuple(range(first,first+len(face.vertices))))
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    triangles=0
    for group,(vertices,faces,uvs,colours,flags,normals) in groups.items():
        mesh=bpy.data.meshes.new(group);mesh.from_pydata(vertices,[],faces);mesh.update()
        uv=mesh.uv_layers.new(name='Physical metres');uv2=mesh.uv_layers.new(name='Material family and piece phase')
        colour=mesh.color_attributes.new(name='Material colour',type='FLOAT_COLOR',domain='CORNER')
        for face in mesh.polygons:
            for loop in face.loop_indices:
                index=mesh.loops[loop].vertex_index;uv.data[loop].uv=uvs[index];uv2.data[loop].uv=flags[index];colour.data[loop].color=colours[index]
        for face in mesh.polygons:face.use_smooth=True
        mesh.normals_split_custom_set([normals[loop.vertex_index] for loop in mesh.loops])
        obj=bpy.data.objects.new(group,mesh);bpy.context.collection.objects.link(obj);obj.select_set(True)
        mesh.calc_loop_triangles();triangles+=len(mesh.loop_triangles)
    target=ART/(ident+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,export_materials='NONE',
        export_texcoords=True,export_vertex_color='ACTIVE',export_active_vertex_color_when_no_material=True,
        export_animations=False,export_cameras=False,export_lights=False)
    lo=[min(p[i] for p in all_points) for i in range(3)];hi=[max(p[i] for p in all_points) for i in range(3)]
    return {'id':ident,'model':'res://art/dressing/damp-dressing-v1/'+ident+'.glb','triangles':triangles,'draws':len(groups),
            'materials':len(groups),'min':[lo[0],lo[2],-hi[1]],'max':[hi[0],hi[2],-lo[1]],'mount':mount,
            'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'lights':0,'bones':0,'states':['static']}


RECIPES=[('wet-flowstone',flowstone,'wall'),('mineral-seep',mineral_seep,'wall'),
 ('dripping-crack',lambda:mineral_seep(True),'wall'),('damp-moss',moss,'wall'),('pearl-niche',pearl_niche,'wall'),
 ('soda-straws',straws,'ceiling'),('drip-stalactite',lambda:straws(True),'ceiling'),
 ('hanging-wet-roots',lambda:roots('hanging'),'ceiling'),('rimstone-edge',rimstone,'edge'),
 ('slick-boulder',lambda:rock('Water-smoothed boulder',(0,0,.24),(.41,.29,.24),72),'edge'),
 ('wet-stalagmite',lambda:tube('Blunt calcite stub',[(0,0,.0),(.015,.01,.10),(.025,.015,.27),(.02,.025,.39)],[.12,.095,.05,.025],'wet_rock',12),'edge'),
 ('drowned-debris',debris,'edge'),('puddle-small',puddle,'floor'),('puddle-wide',lambda:puddle(True),'floor'),
 ('silt-ripples',silt,'floor'),('mud-bootprints',lambda:silt(True),'floor'),('wet-gravel',lambda:rubble(19,True),'floor'),
 ('cracks-rubble',crack,'wall'),('chalk-arrow',lambda:chalk('arrow'),'wall'),('chalk-cross',lambda:chalk('cross'),'wall'),
 ('chalk-tally',lambda:chalk('tally'),'wall'),('web-strand',web,'ceiling'),('rat-nest',nest,'edge'),
 ('tracks-drag',lambda:silt(drag=True),'floor'),('floor-crack',lambda:crack(True),'floor'),('old-scorch',scorch,'floor'),
 ('moss-curtain',lambda:roots('moss-curtain'),'ceiling'),('root-curtain-a',lambda:roots('curtain-a'),'ceiling'),
 ('root-curtain-b',lambda:roots('curtain-b'),'ceiling'),('root-foot-tangle',lambda:roots('foot'),'edge'),
 ('floor-crossing-root',lambda:roots('crossing'),'floor'),('collapsed-crates',crate,'edge'),('split-barrel',barrel,'edge'),
 ('fallen-banner',banner,'floor'),('cache-rubble-planks',lambda:(rubble(7),plank()),'floor'),('cache-spilled-grain',grain,'floor'),
 ('exit-mushrooms',mushrooms,'edge'),('exit-floor-mold',lambda:moss(False),'floor'),('exit-wall-mold',moss,'wall'),
 ('goblin-stash-fresh',stash,'floor'),('goblin-stash-empty',lambda:stash(True),'floor'),
 ('lamp-store-fresh',lamp_store,'floor'),('lamp-store-used',lambda:lamp_store(True),'floor'),
 ('three-knocks-fresh',three_knocks,'floor'),('three-knocks-used',lambda:three_knocks(True),'floor')]
assets=[export(ident,recipe,mount) for ident,recipe,mount in RECIPES]
for row in assets:
    assert row['triangles']<=6500,row
    assert row['max'][0]-row['min'][0]<1.8,row
catalog={'issue':302,'brief':'C/D environment dressing and remaining early 3D conversions','units':'metres; min/max in final Godot coordinates',
 'wall_front':'+Z into room; wall mount at centre; negative Y under ceiling mount; floor origin 0',
 'assets':assets,'sources':[{'type':'Original authored geometry','builder':'tools/damp_caves/build_dressing.py',
 'helpers':['tools/mine_props/build_models.py','tools/mine_polish/build_models.py'],
 'note':'Reuses original worn-prop primitives, mesh/UV/vertex-colour export conventions. No private/downloaded models or pixels.'}],
 'builder_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
 'hookup':'No live bindings changed. Caller owns theme, actual wall/roof anchors, collision, water, poison, route and quest state.'}
(ART/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8')
print('DAMP_DRESSING',[(row['id'],row['triangles']) for row in assets])
