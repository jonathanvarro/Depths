"""#308 original Cavern/Rest pieces on the retained worked-prop geometry tools.

Blender background, -- --workspace E:/GitHub/Depths. No live game assignments.
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

ROOT=Path(__file__).resolve().parents[2]
sys.dont_write_bytecode=True
spec=importlib.util.spec_from_file_location('cavern_worked_helpers',ROOT/'tools/mine_polish/build_models.py')
P=importlib.util.module_from_spec(spec);spec.loader.exec_module(P);G=P.G
parser=argparse.ArgumentParser();parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
ART=ROOT/'art/props/cavern-rest-v1';WORK=args.workspace/'build/local-cavern-rest-v1'
ART.mkdir(parents=True,exist_ok=True);P.MASTERS=WORK/'masters';P.MASTERS.mkdir(parents=True,exist_ok=True)
(WORK/'.gdignore').write_text('')
for key,colour in {'stone_rift':'535e63','stone_rift_light':'778080','stone_rift_dark':'303d42',
 'stone_dust':'706a5c','stone_earth':'4c4638','ore_iron':'6e6b5d','cloth_hide':'635342','cloth_hide_dark':'3d382e',
 'cloth_canvas':'8e8064','cloth_scout':'485f59','cloth_paper':'b5aa87','cloth_ink':'47473b',
 'wood_grey':'645642','wood_cut':'8f7654','bone':'a99c7d'}.items():
    G.COLOURS[key]=colour;mat=G.MATERIALS.get(key) or bpy.data.materials.new(key)
    mat.diffuse_color=(*(int(colour[i:i+2],16)/255 for i in (0,2,4)),1);G.MATERIALS[key]=mat
old_group=P.group_for
def group_for(name):return 'Stone' if name=='bone' else old_group(name)
P.group_for=group_for


def tube(name,points,radii,material='wood_grey',sides=7):
    pts=[Vector(p) for p in points];vertices=[]
    for i,(point,r) in enumerate(zip(pts,radii)):
        axis=(pts[min(i+1,len(pts)-1)]-pts[max(0,i-1)]).normalized()
        a=axis.cross(Vector((0,1,0)) if abs(axis.y)<.9 else Vector((1,0,0))).normalized();b=axis.cross(a)
        for j in range(sides):
            angle=j*math.tau/sides;vertices.append(point+r*(math.cos(angle)*a+math.sin(angle)*b))
    faces=[tuple(reversed(range(sides))),tuple(range((len(pts)-1)*sides,len(pts)*sides))]
    for i in range(len(pts)-1):
        for j in range(sides):faces.append((i*sides+j,i*sides+(j+1)%sides,(i+1)*sides+(j+1)%sides,(i+1)*sides+j))
    return G.mesh_object(name,vertices,faces,material)


def rock(name,at,size,seed=0,material='stone_rift'):
    return P.lump(name,at,size,material,seed)


def column(height=5.8,roof=False):
    sides=11;rings=13;vertices=[]
    for j in range(rings):
        t=j/(rings-1);z=-height*t if roof else height*t
        radius=(.43*(1-t)**.65+.008) if roof else (.52*(1-t)**.65+.008+.10*math.sin(t*7)**2*(1-t))
        for i in range(sides):
            a=i*math.tau/sides;flute=1+.12*math.sin(i*3.1+t*4)+.07*math.cos(i*6+t*5)
            vertices.append((radius*flute*math.cos(a)+.045*math.sin(t*7),radius*flute*math.sin(a),z))
    faces=[tuple(reversed(range(sides))),tuple(range((rings-1)*sides,rings*sides))]
    for j in range(rings-1):
        for i in range(sides):faces.append((j*sides+i,j*sides+(i+1)%sides,(j+1)*sides+(i+1)%sides,(j+1)*sides+i))
    G.mesh_object('Long fractured mineral ribs',vertices,faces,'stone_rift')
    if not roof:
        for i in range(5):
            a=i*math.tau/5;rock('Column talus',(math.cos(a)*.32,math.sin(a)*.32,.08),(.22,.20,.16),i)


def wall_rib(width=1.8,height=2.16,bottom=-1.08):
    nx,nz=23,25;vertices=[]
    for j in range(nz):
        t=j/(nz-1)
        for i in range(nx):
            u=i/(nx-1);x=(u-.5)*width
            depth=.035+.15*math.sin(u*math.pi)**.5*(.6+.30*math.cos(u*26+t*6)+.16*math.sin(u*57-t*8))
            depth+=.05*math.sin(t*12+u*7)**4
            if height>3:depth=depth*2.3+.14*math.sin(t*15+u*4)**6
            vertices.append((x,-depth,bottom+t*height))
    faces=[]
    for j in range(nz-1):
        for i in range(nx-1):a=j*nx+i;faces.append((a,a+1,a+nx+1,a+nx))
    G.mesh_object('Continuous fluted fractured cliff face',vertices,faces,'stone_rift')


def talus():
    for i in range(11):
        x=-.62+(i%4)*.36;y=-.12+(i//4)*.21
        rock('Dry fallen angular rock',(x,y,.08+(i//4)*.05),(.22,.18,.15),i,'stone_rift_light' if i%4==0 else 'stone_rift')


def ledge():
    # A complete level 2m tile with a deep visual skirt, no sloping route.
    G.mesh_object('Flat continuous ledge landing',[(-1,-1,0),(1,-1,0),(1,1,0),(-1,1,0)],[(0,1,2,3)],'stone_rift')
    vertices=[];nx,nz=12,7
    for j in range(nz):
        z=-1.8+j*.30
        for i in range(nx):
            y=-1+i*2/(nx-1);x=1.0 if j==nz-1 else .88+.05*math.sin(y*5+z*3)+.06*math.cos(y*9-z*4)
            vertices.append((x,y,z))
    faces=[]
    for j in range(nz-1):
        for i in range(nx-1):a=j*nx+i;faces.append((a,a+1,a+nx+1,a+nx))
    G.mesh_object('Continuous fractured ledge drop',vertices,faces,'stone_rift_dark')


def daub():
    # Raised clay/mineral glyph, no transparent wall poster or implied text.
    for a,b in [((-.24,-.02,-.15),(.0,-.03,.23)),((.0,-.03,.23),(.23,-.02,-.15)),
                ((-.22,-.03,.04),(.22,-.03,.04)),((-.10,-.03,-.24),(-.05,-.03,-.02))]:
        tube('Smeared ochre goblin mark',[a,b],[.018,.012],'rust',5)


def bowl(name,at=(0,0,0),radius=.18):
    vertices=[];n=12
    for r,z in [(radius*.5,0),(radius,.12),(radius*.87,.12),(radius*.4,.025)]:
        for i in range(n):
            a=i*math.tau/n;vertices.append(Vector(at)+Vector((r*math.cos(a),r*math.sin(a),z)))
    faces=[]
    for j in range(3):
        for i in range(n):faces.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
    faces.append(tuple(range(3*n,4*n)))
    return G.mesh_object(name,vertices,faces,'iron')


def litter():
    bowl('Dented discarded bowl',(-.18,.03,.01),.12)
    for i in range(5):
        a=-.36+i*.16
        P.beam('Split camp offcut',(a,-.13,.023),(a+.12,.21,.026),.035,.02,'wood_grey',i)
    G.mesh_object('Ragged discarded hide',[(.03,-.21,.012),(.31,-.19,.015),(.41,.02,.02),(.22,.14,.012),(.08,.04,.017)],[(0,1,2,3,4)],'cloth_hide')
    for i in range(3):tube('Gnawed anonymous bone',[(.15+i*.06,.16,.025),(.2+i*.06,.25,.03)],[.009,.012],'bone',5)


def totem():
    P.beam('Split totem shaft',(0,0,0),(0,0,1.42),.15,.15,'wood_grey',30)
    for z,w in [(1.08,.38),(.79,.24)]:P.beam('Totem cross rail',(-w,0,z),(w,0,z+.03),.065,.07,'wood',31)
    # Crude chisel marks and bone pegs, no humanoid body/extra enemy.
    for x in [-.045,.045]:
        P.box('Deep eye notch',(x,-.086,1.22),(.027,.005,.04),'wood_dark',(0,0,x*2))
    P.box('Split mouth gouge',(0,-.087,1.10),(.09,.005,.018),'wood_dark')
    for side in [-1,1]:
        tube('Totem bone tooth',[(side*.22,-.02,.98),(side*.27,-.02,.88)],[.02,.005],'bone',6)
    for z in [.10,.65,1.02]:P.ring('Totem rope binding',(0,0,z),.105,'leather',(0,0,0),.008)


def rack():
    for x in [-.48,.48]:P.beam('Drying rack leg',(x,0,0),(x,.04,1.36),.055,.065,'wood_grey',int(x*100))
    P.beam('Drying rack crossbar',(-.56,.04,1.31),(.56,.04,1.31),.06,.06,'wood',36)
    for i in range(5):
        x=-.35+i*.17;low=.40+(i%3)*.12
        verts=[(x-.055,.02,1.28),(x+.05,.02,1.28),(x+.04,-.018,.8),(x+.01,.015,low),(x-.035,.01,low+.05)]
        G.mesh_object('Dried hanging strip',verts,[(0,1,2,3,4)],'cloth_hide_dark')
        tube('Suspended strip cord',[(x,0,1.33),(x,0,1.25)],[.006,.006],'leather',5)


def trophy():
    for x in [-.4,.4]:P.beam('Trophy prop support',(x,0,0),(x,0,1.25),.07,.07,'wood_grey',40)
    P.beam('Trophy crossbar',(-.48,0,1.22),(.48,0,1.22),.08,.08,'wood',41)
    for i in range(3):
        x=-.27+i*.27
        tube('Trophy tie',[(x,-.01,1.23),(x,-.02,.88)],[.009,.009],'leather',5)
        tube('Hanging long bone',[(x-.09,-.03,.84),(x+.09,-.03,.79)],[.025,.020],'bone',6)
        for sign in [-1,1]:rock('Bone joint',(x+sign*.09,-.03,.80),(.035,.03,.026),i,'bone')


def iron_seam(spent=False):
    # Metric vertical wall panel, bottom at ground, outward face Blender -Y.
    for i in range(8):
        z=.12+i*.21;x=.13*math.sin(i*1.3)
        rock('Iron-bearing fracture',(x,-.025,z),(.20,.07,.16),i,'stone_rift_dark')
        if not spent or i%3==0:rock('Exposed iron face',(x,-.09,z+.025),(.09,.045,.075),i+12,'ore_iron')
    for i in range(7):rock('Picked seam spoil',(-.3+i*.1,-.20,.025),(.06,.05,.035),i,'stone_dust')
    if spent:
        for i in range(4):tube('Worked tool scar',[(-.11,-.10,.35+i*.28),(.08,-.11,.49+i*.28)],[.005,.003],'stone_rift_light',4)


def screen(opened=False):
    for x in [-.92,.92]:P.beam('Hide curtain jamb',(x,0,0),(x,0,2.22),.11,.12,'wood_grey',45)
    P.beam('Hide curtain lintel',(-.98,0,2.18),(.98,0,2.18),.11,.12,'wood',46)
    if not opened:
        nx,nz=10,9;vertices=[]
        for j in range(nz):
            for i in range(nx):
                x=-.84+i*1.68/(nx-1);z=.12+j*1.98/(nz-1)
                vertices.append((x,-.055-.025*math.sin(i*2+j*.4),z-(.04*(i%2) if j==0 else 0)))
        faces=[]
        for j in range(nz-1):
            for i in range(nx-1):a=j*nx+i;faces.append((a,a+1,a+nx+1,a+nx))
        G.mesh_object('Rough stitched opaque hide curtain',vertices,faces,'cloth_hide')
        for x in [-.35,.21]:tube('Hide stitch seam',[(x,-.10,.18),(x+.03,-.10,1.1),(x,-.10,2.08)],[.005]*3,'leather',5)
    else:
        for side in [-1,1]:
            G.mesh_object('Gathered open hide',[(side*.9,-.12,.12),(side*.72,-.13,.39),(side*.76,-.13,2.09),(side*.90,-.11,2.11)],[(0,1,2,3)],'cloth_hide')


def throat(safe=False):
    for side in [-1,1]:
        for i in range(5):rock('Narrow portal rock jamb',(side*.91,.10,.22+i*.42),(.13,.20,.28),i)
    for i in range(7):
        x=-.77+i*.255;rock('Shallow arch header',(x,.1,2.05+.20*(1-(x/.9)**2)),(.22,.21,.16),i+20)
    if safe:
        for sign in [-1,1]:
            P.beam('Welcome path rail',(sign*.9,-.7,.64),(sign*.9,.14,.64),.035,.045,'wood_grey',62)
        G.mesh_object('Scouts dry cloth pennant',[(.72,-.13,1.80),(.91,-.13,1.80),(.90,-.13,1.31),(.81,-.13,1.39),(.72,-.13,1.34)],[(0,1,2,3,4)],'cloth_scout')


def bedroll():
    # Grounded rectangle and folded blanket; a genuinely supported pillow.
    P.box('Straw sleeping mat',(0,0,.035),(.66,1.65,.07),'cloth_canvas')
    for j in range(5):
        y=-.66+j*.27
        P.box('Blanket folds',(0,y,.09),(.61,.31,.035),'cloth_scout',(0,.015*math.sin(j),0))
    rock('Supported pillow',(0,.62,.13),(.26,.20,.09),73,'cloth_canvas')
    for x in [-.23,.23]:tube('Mat lashing',[(x,-.82,.015),(x,-.82,.09),(x,-.68,.11)],[.008]*3,'leather',5)


def tent():
    # Low dry canvas shelter with a separate inner cot and real dirt pegs.
    vertices=[(0,0,.007)]+[(1.12*math.cos(i*math.tau/20),1.25*math.sin(i*math.tau/20),.005) for i in range(20)]
    G.mesh_object('Earth pad for ground pegs',vertices,[(0,i+1,(i+1)%20+1) for i in range(20)],'stone_earth')
    for y in [-1.0,1.0]:P.beam('Tent upright',(0,y,.0),(0,y,1.55),.055,.055,'wood',81)
    P.beam('Tent ridge',(0,-1.08,1.55),(0,1.08,1.55),.06,.06,'wood_grey',82)
    for side in [-1,1]:
        vertices=[]
        for j in range(9):
            y=-1+j*.25
            for k in range(6):
                t=k/5;x=side*.83*t;z=1.52*(1-t)+.045-.045*math.sin(t*math.pi)*math.sin(j*.7)**2
                vertices.append((x,y,z))
        faces=[]
        for j in range(8):
            for k in range(5):a=j*6+k;faces.append((a,a+1,a+7,a+6))
        G.mesh_object('Sagging dry canvas shelter',vertices,faces,'cloth_canvas')
        for y in [-.86,.86]:
            tube('Taut tent guy rope',[(side*.69,y,.28),(side*.98,y-.12,.04)],[.008,.008],'leather',6)
            P.beam('Peg in earth',(side*.98,y-.12,-.03),(side*.96,y-.12,.13),.025,.03,'wood',86)
    G.mesh_object('Closed rear canvas',[(-.82,1,.04),(.82,1,.04),(0,1,1.54)],[(0,1,2)],'cloth_canvas')
    for side in [-1,1]:
        G.mesh_object('Tied entrance flap',[(0,-1.015,1.53),(side*.79,-1.01,.06),(side*.60,-1.08,.10),(side*.34,-1.05,.61)],[(0,1,2,3)],'cloth_scout')
    P.box('Dry tent groundsheet',(0,0,.009),(1.62,1.95,.018),'cloth_hide_dark')
    before=set(bpy.context.scene.objects);bedroll()
    for obj in set(bpy.context.scene.objects)-before:obj.scale*=.78;obj.location*=.78;obj.location.z+=.02


def table():
    for x in [-.40,.40]:
        for y in [-.27,.27]:P.beam('Map table leg',(x,y,.0),(x,y,.70),.06,.06,'wood_grey',94)
    for i in range(5):P.beam('Table top plank',(-.48,-.29+i*.145,.72),(.48,-.29+i*.145,.72),.14,.045,'wood_grey',95+i)
    G.mesh_object('Planning paper',[(-.33,-.23,.75),(.26,-.22,.751),(.29,.18,.752),(-.32,.20,.75)],[(0,1,2,3)],'cloth_paper')
    for pts in [[(-.23,-.16,.754),(-.06,-.09,.755),(.06,.06,.755),(.22,.12,.754)],
                [(-.12,.13,.755),(-.06,-.09,.755),(.21,-.16,.755)]]:
        tube('Unlabelled map ink route',pts,[.003]*len(pts),'cloth_ink',4)
    for x,y in [(-.29,-.19),(.24,.15)]:rock('Paper corner stone',(x,y,.767),(.024,.024,.014),101,'stone_dust')
    P.beam('Charcoal beside paper',(.34,-.14,.76),(.36,.08,.76),.009,.01,'wood_dark',107)


def crate():
    for side in [-1,1]:
        for i in range(4):P.box('Supply chest stave',(side*.43,0,.08+i*.105),(.045,.60,.10),'wood_grey')
    for y in [-.28,.28]:
        for i in range(4):P.box('Supply chest front board',(0,y,.08+i*.105),(.86,.045,.10),'wood')
    for i in range(6):P.box('Closed crate lid',(-.36+i*.145,0,.47),(.14,.61,.035),'wood_grey')
    for x in [-.28,.28]:P.box('Crate iron band',(x,0,.49),(.035,.63,.016),'iron')


def bench():
    for x in [-.44,.44]:
        P.beam('Bench leg',(x,0,.0),(x,0,.36),.09,.24,'wood_grey',111)
    for y in [-.09,.09]:P.beam('Bench seat',(-.57,y,.39),(.57,y,.39),.17,.05,'wood_grey',112)


builders=[('column-tall',lambda:column()),('roof-pendant',lambda:column(1.8,True)),('wall-rib',wall_rib),('cliff-face',lambda:wall_rib(3,14,-6)),
 ('talus-edge',talus),('ledge-tile',ledge),('goblin-daub',daub),('goblin-litter',litter),('goblin-totem',totem),
 ('drying-rack',rack),('hanging-trophies',trophy),('iron-seam-fresh',lambda:iron_seam(False)),('iron-seam-worked',lambda:iron_seam(True)),
 ('hide-curtain-closed',lambda:screen(False)),('hide-curtain-open',lambda:screen(True)),
 ('cavern-throat',lambda:throat(False)),('rest-threshold',lambda:throat(True)),
 ('bedroll',bedroll),('scout-tent',tent),('map-table',table),('supply-crate',crate),('bench',bench)]
assets=[]
for ident,build in builders:
    row=P.export(ident,build,ART)
    lo,hi=row.pop('min'),row.pop('max');row['min']=[lo[0],lo[2],-hi[1]];row['max']=[hi[0],hi[2],-lo[1]]
    assert row['triangles']<5000,(ident,row['triangles']);assets.append(row)
catalog={'issue':308,'assets':assets,'source':'Original geometry on retained mine/worked-prop helpers. No new downloaded or private source.',
 'masters':'build/local-cavern-rest-v1/masters','forward':'+Z out of wall / -Z passage',
 'live_bindings_changed':False,'elevation_prototype':False,
 'helper_inputs':['tools/mine_props/build_models.py','tools/mine_polish/build_models.py'],
 'builder_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
(ART/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8')
print('CAVERN_REST_MODELS',[(a['id'],a['triangles']) for a in assets])
