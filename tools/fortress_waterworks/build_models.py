"""Build #246 fortress and machinery pieces with preserved metric mounts."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import random
import sys

import bpy
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[2]
sys.dont_write_bytecode=True
sys.path.insert(0,str(ROOT/'tools/mine_props'))
import build_models as geometry

parser=argparse.ArgumentParser()
parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
ART=ROOT/'art/props/fortress-waterworks-3d-v1'
SOURCE=ROOT/'art/third-party/kaykit-fortress-v1'
geometry.ART=ART
geometry.MASTERS=args.workspace/'build/local-fortress-waterworks-v1/masters'
ART.mkdir(parents=True,exist_ok=True)
geometry.MASTERS.mkdir(parents=True,exist_ok=True)
(geometry.MASTERS/'.gdignore').write_text('',encoding='utf-8')
for name,colour in {'rope':'97805b','rope_dark':'6e5d44','banner':'743e35',
                    'banner_faded':'945d4b','slate':'535f60','slate_light':'728080',
                    'silt':'54634e','blackwater':'172a2a'}.items():
    geometry.COLOURS[name]=colour
    material=bpy.data.materials.new(name)
    material.diffuse_color=(*(int(colour[i:i+2],16)/255 for i in (0,2,4)),1)
    geometry.MATERIALS[name]=material
box=geometry.box
beam=geometry.beam
lump=geometry.lump
stone=geometry.stone
mesh=geometry.mesh_object

def tube(name,start,end,radius,material='iron',sides=6):
    """Low-sided straight cylinder, including both end faces."""
    a,b=Vector(start),Vector(end)
    rotation=Vector((0,0,1)).rotation_difference((b-a).normalized())
    verts=[]
    for at in [a,b]:
        verts.extend(at+rotation@Vector((radius*math.cos(i*math.tau/sides),radius*math.sin(i*math.tau/sides),0)) for i in range(sides))
    faces=[tuple(reversed(range(sides))),tuple(range(sides,2*sides))]
    faces.extend((i,(i+1)%sides,(i+1)%sides+sides,i+sides) for i in range(sides))
    return mesh(name,verts,faces,material)

def ring(name,at,radii,thickness,material='iron',segments=10,plane='XZ'):
    """A solid closed low-poly ring. Alternating planes interlock real links."""
    verts=[]
    for i in range(segments):
        angle=i*math.tau/segments
        for j in range(4):
            cross=j*math.tau/4
            u=(radii[0]+thickness*math.cos(cross))*math.cos(angle)
            v=(radii[1]+thickness*math.cos(cross))*math.sin(angle)
            depth=thickness*math.sin(cross)
            p=(u,depth,v) if plane=='XZ' else ((depth,u,v) if plane=='YZ' else (u,v,depth))
            verts.append(Vector(at)+Vector(p))
    faces=[]
    for i in range(segments):
        for j in range(4): faces.append((i*4+j,((i+1)%segments)*4+j,((i+1)%segments)*4+(j+1)%4,i*4+(j+1)%4))
    return mesh(name,verts,[tuple(reversed(face)) for face in faces],material)

def chain(x,y,bottom,top,spacing=.095):
    count=max(2,round((top-bottom)/spacing))
    for i in range(count+1):
        ring('Interlocked chain',(x,y,bottom+(top-bottom)*i/count),(.029,.055),.009,
             'rust' if i%5==0 else 'iron_edge',8,'XZ' if i%2==0 else 'YZ')

def lash(at,radius=.085):
    for i in range(2): ring('Uneven rope lashing',Vector(at)+Vector((0,0,i*.022)),(radius,radius*.85),.013,'rope',8,'XY')

def stake(name,at,height,width,seed):
    rng=random.Random(seed)
    x,y,z=at
    broken=height<.6
    cross=[(-.38,-.5),(.31,-.5),(.5,-.30),(.46,.32),(.29,.5),(-.31,.46),(-.5,.28),(-.48,-.30)]
    verts=[]
    lean=rng.uniform(-.04,.04)
    for row,h in enumerate([0,height*.47,height-(.045 if broken else .18)]):
        for a,b in cross:
            verts.append((x+a*width+lean*row*.5+rng.uniform(-.009,.009),
                          y+b*width*.72+rng.uniform(-.006,.006),z+h+(rng.uniform(-.045,.025) if broken and row==2 else 0)))
    faces=[tuple(reversed(range(8)))]
    for row in range(2):
        for i in range(8): faces.append((row*8+i,row*8+(i+1)%8,(row+1)*8+(i+1)%8,(row+1)*8+i))
    if broken:
        faces.append(tuple(range(16,24)))
    else:
        verts.append((x+lean-.024,y+.014,z+height))
        for i in range(8): faces.append((16+i,16+(i+1)%8,24))
    obj=mesh(name,verts,faces,'wood_light' if seed%3 else 'wood')
    obj.data.materials.append(geometry.MATERIALS['rope_dark'])
    if broken: obj.data.polygons[-1].material_index=1

def palisade(broken):
    for i in range(7):
        x=(i-3)*.23
        height=[1.05,1.26,1.15,1.34,1.21,1.12,1.28][i]
        if broken and i in [2,3,4]: height=[.40,.27,.51][i-2]
        stake('Splintered palisade',(x,.015*math.sin(i*3),0),height,.20,i+10)
        if i in [0,3,6]: lash((x,-.018,.38))
    for z in [.30,.73]:
        if broken and z>.4:
            beam('Snapped crossbar',(-.82,.10,z),(-.31,.10,z+.04),.085,.09,'wood_dark',4)
            beam('Snapped crossbar',(.35,.10,z-.09),(.82,.10,z),.085,.09,'wood_dark',5)
        else: beam('Crooked crossbar',(-.82,.10,z),(.82,.10,z+.035),.085,.09,'wood_dark',4)
    if broken:
        for i in range(3): beam('Fallen splinter',(-.30+i*.21,-.13,.04),(.10+i*.18,-.44,.07),.085,.06,'wood_light',i)

def rag(name,corners,material):
    # Thick enough to be visible from both directions without double-sided shading.
    verts=[Vector(v) for v in corners]+[Vector(v)+Vector((0,.009,0)) for v in corners]
    n=len(corners)
    faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]
    faces.extend((i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n))
    return mesh(name,verts,faces,material)

def watch_post():
    for i,(x,y) in enumerate([(-.37,-.28),(.35,-.27),(-.33,.27),(.37,.28)]):
        beam('Splayed post',(x*1.1,y*1.15,0),(x,y,1.63+(i%2)*.04),.10,.10,'wood',i)
        lash((x,y,.80),.073)
    for i in range(5): beam('Uneven floorboard',(-.42,(i-2)*.13,.79),(.44,(i-2)*.13,.80),.13,.055,'wood_light',i)
    beam('Diagonal brace',(-.40,-.29,.09),(.36,-.27,.77),.06,.06,'wood_dark',5)
    beam('Side brace',(.37,-.30,.09),(.37,.28,.76),.06,.06,'wood_dark',6)
    for x in [-.33,.33]: beam('Ladder rail',(x*.50,-.44,.03),(x*.50,-.27,.83),.055,.055,'wood_light',4)
    for i in range(5): beam('Ladder rung',(-.17,-.44+i*.034,.11+i*.145),(.17,-.44+i*.034,.11+i*.145),.045,.045,'wood',i)
    beam('Front low rail',(-.37,-.29,1.08),(.37,-.29,1.10),.07,.07,'wood_dark',6)
    for x in [-.37,.37]: beam('Side rail',(x,-.29,1.12),(x,.28,1.14),.055,.055,'wood',6)
    rag('Sagging patched canopy',[(-.44,-.38,1.71),(0,-.35,1.60),(.46,-.35,1.74),(.43,.37,1.70),
        (.05,.39,1.59),(-.45,.36,1.68)],'cloth_dark')
    rag('Torn canopy edge',[(-.44,-.38,1.71),(.46,-.35,1.74),(.33,-.36,1.49),(.18,-.36,1.59),
        (.04,-.36,1.45),(-.14,-.37,1.57),(-.39,-.38,1.52)],'cloth')

def walkway():
    # Ceiling origin. Bottom is -0.53m, leaving 1.87m over a 2.4m room.
    for i in range(9):
        x=(i-4)*.19
        beam('Warped overhead board',(x,-.27,-.48),(x,.27,-.47),.18,.045,'wood_light' if i%3 else 'wood',i)
    for y in [-.24,.24]: beam('Long bearer',(-.90,y,-.50),(.90,y,-.49),.06,.07,'wood_dark',7)
    for x in [-.78,.78]:
        for y in [-.24,.24]:
            tube('Suspension rope',(x,y,-.46),(x+.03,y,0),.017,'rope',5)
            lash((x,y,-.45),.038)

def bracket():
    box('Wall plate',(0,.025,-.12),(.19,.05,.31),'iron')
    beam('Bent projecting hook',(0,-.01,-.03),(0,-.29,-.03),.045,.05,'rust',7)
    beam('Hook brace',(0,-.015,-.24),(0,-.25,-.04),.035,.035,'iron_edge',2)
    ring('Hanging eye',(0,-.28,-.09),(.035,.04),.012,'iron_edge',8)
    for z in [-.23,-.035]: lump('Wall rivet',(0,-.012,z),(.016,.013,.016),'iron_edge',1)

def cage():
    # Ceiling origin and no living occupant. It belongs in an edge alcove.
    chain(0,0,-.31,-.065,.09)
    for z in [-.43,-1.04]: ring('Battered cage hoop',(0,0,z),(.25,.23),.025,'iron_edge',12,'XY')
    for i in range(10):
        a=i*math.tau/10
        x,y=.25*math.cos(a),.23*math.sin(a)
        tube('Cage bar',(x,y,-1.04),(x,y,-.43),.014,'iron' if i%3 else 'rust',5)
        tube('Cage roof rib',(x,y,-.43),(0,0,-.30),.014,'iron' if i%3 else 'rust',5)
    tube('Top hanger',(0,0,-.30),(0,0,-.37),.028,'iron_edge')
    for i in range(5): beam('Cage floor plank',(-.20,(i-2)*.08,-1.07),(.20,(i-2)*.08,-1.07),.075,.025,'wood_dark',i)
    box('Crude lock',(.04,-.245,-.76),(.075,.035,.09),'rust')

def platform():
    for i in range(6): beam('Throne dais board',(-.65,(i-2.5)*.18,.17),(.65,(i-2.5)*.18,.17),.175,.07,'wood' if i%3 else 'wood_light',i)
    for x in [-.53,.53]: beam('Dais sleeper',(x,-.54,.06),(x,.54,.06),.15,.12,'wood_dark',3)
    for i in range(3): stone(((i-1)*.31,-.66,.046),(.30,.21,.09),'stone_dark',i)

def throne():
    bpy.ops.import_scene.gltf(filepath=str(SOURCE/'chair.glb'),import_pack_images=True)
    imported=list(bpy.context.selected_objects)
    objects=[o for o in imported if o.type=='MESH']
    def orient(point): return Vector((-point.y,point.x,point.z))
    points=[orient(o.matrix_world@v.co) for o in objects for v in o.data.vertices]
    low=Vector(tuple(min(p[i] for p in points) for i in range(3)))
    high=Vector(tuple(max(p[i] for p in points) for i in range(3)))
    centre=Vector(((low.x+high.x)/2,(low.y+high.y)/2,low.z))
    for obj in objects:
        coords=[orient(obj.matrix_world@v.co) for v in obj.data.vertices]
        obj.parent=None
        obj.matrix_world.identity()
        obj.data.materials.clear()
        obj.data.materials.append(geometry.MATERIALS['wood'])
        obj.data.materials.append(geometry.MATERIALS['wood_light'])
        for face in obj.data.polygons: face.material_index=1 if face.index%9==0 else 0
        for vertex,point in zip(obj.data.vertices,coords):
            p=point-centre
            vertex.co=Vector((p.x/(high.x-low.x)*.64+.006*math.sin(p.z*9),
                              p.y/(high.y-low.y)*.57,p.z/(high.z-low.z)*.86+.205))
        obj.name='Scavenged CC0 chair'
    for obj in imported:
        if obj.type!='MESH': bpy.data.objects.remove(obj,do_unlink=True)
    for i in range(5): stake('Ragged throne back',((i-2)*.13,.23,.75),.48+[.08,.19,.34,.23,.12][i],.125,i+44)
    for x in [-.37,.37]:
        beam('Scavenged armrest',(x,-.26,.67),(x,.19,.70),.11,.07,'wood_light',8)
        box('Rusty repair plate',(x,-.09,.698),(.125,.15,.012),'rust',(.02,0,.05))
        for y in [-.13,-.05]: lump('Armrest rivet',(x,y,.712),(.012,.012,.009),'iron_edge',8)
    rag('Faded rag over seat',[(-.27,-.32,.67),(.29,-.32,.66),(.28,-.34,.34),(.17,-.33,.41),
        (.02,-.33,.27),(-.12,-.33,.42),(-.26,-.32,.38)],'banner')
    box('Worn red seat',(0,-.015,.675),(.52,.46,.045),'banner_faded',(.01,.02,0))

def frame(flow):
    centre=0 if flow else .27
    span=.72 if flow else .57
    for side in [-1,1]:
        for i in range(6):
            stone((centre+side*span,.03,.18+i*.35),(.23,.32,.34),'slate' if i%2 else 'slate_light',i+side*9)
        box('Gate guide',(centre+side*(span-.15),-.19,1.16),(.055,.075,2.21),'iron')
    for i in range(4): stone((centre+(i-1.5)*span*.49,.035,1.41),(span*.49-.01,.34,.26),'slate',i+32)
    for i in range(4): stone((centre+(i-1.5)*span*.48,-.04,.075),(span*.48-.01,.47,.13),'slate',i+12)
    # Opaque outflow panel conceals the actual wall. It never creates a passage.
    box('Dark outflow throat',(centre,-.055,.67),(span*1.65,.015,1.13),'blackwater')
    box('Silt on threshold',(centre,-.19,.147),(span*1.62,.15,.017),'silt')
    tube('Upper hoist spindle',(centre-span+.05,-.17,2.14),(centre+span-.05,-.17,2.14),.042,'iron_edge',8)
    if flow:
        for x in [-.49,.49]:
            chain(x,-.20,.28,2.08,.11)
            ring('Hoist roller',(x,-.17,2.14),(.095,.095),.018,'rust',10,'YZ')
    else:
        beam('Wheel axle brace',(-.56,.01,.55),(-.56,-.22,1.10),.075,.075,'iron',8)
        tube('Wheel axle',(-.56,.07,1.10),(-.56,-.26,1.10),.049,'iron_edge',8)
        tube('Threaded screw',(.27,-.16,1.39),(.27,-.16,2.18),.032,'iron_edge',8)
        for i in range(9): ring('Screw thread',(.27,-.16,1.46+i*.074),(.048,.048),.009,'rust',8,'XY')

def shutter(flow):
    width=1.10 if flow else .84
    box('Heavy gate plate',(0,0,.55),(width,.075,1.10),'iron')
    for i in range(3):
        z=.13+i*.41
        box('Riveted cross strap',(0,-.049,z),(width+.025,.025,.07),'iron_edge')
        for x in [-width*.40,width*.40]: lump('Rivet',(x,-.067,z),(.019,.010,.019),'rust',i)
    for i in range(4):
        x=(i-1.5)*width*.23
        box('Vertical worn seam',(x,-.043,.55),(.012,.008,.98),'rust')

def wheel():
    ring('Dented six-spoke wheel',(0,0,0),(.39,.39),.034,'iron_edge',16)
    ring('Inner rust seam',(0,-.018,0),(.356,.356),.009,'rust',16)
    for i in range(6):
        a=i*math.tau/6
        tube('Forged spoke',(.06*math.cos(a),0,.06*math.sin(a)),(.365*math.cos(a),0,.365*math.sin(a)),.025,'iron',6)
    tube('Wheel hub',(0,-.065,0),(0,.065,0),.083,'rust',8)
    tube('Crank peg',(.24,-.02,.23),(.24,-.15,.23),.032,'wood_dark',6)

def drum():
    tube('Hoist drum',(-.19,0,0),(.19,0,0),.10,'iron',10)
    for x in [-.19,.19]: ring('Drum flange',(x,0,0),(.13,.13),.023,'iron_edge',12,'YZ')
    for i in range(5): ring('Wound chain groove',((i-2)*.055,0,0),(.104,.104),.011,'rust',10,'YZ')

def pipe():
    # Wall-centred short bent pipe, real hollow mouth facing +Z in Godot.
    rings=[((0,.015,.28),.135),((0,-.11,.27),.135),((0,-.22,.20),.135),((0,-.31,.09),.135)]
    verts=[]
    for index,(at,radius) in enumerate(rings):
        tangent=Vector(rings[min(index+1,3)][0])-Vector(rings[max(index-1,0)][0])
        q=Vector((0,0,1)).rotation_difference(tangent.normalized())
        for i in range(10):
            p=Vector(at)+q@Vector((radius*math.cos(i*math.tau/10),radius*math.sin(i*math.tau/10),0))
            if index==3: p.z+=.023*math.sin(i*3.2)
            verts.append(p)
    for index,(at,radius) in enumerate(rings):
        tangent=Vector(rings[min(index+1,3)][0])-Vector(rings[max(index-1,0)][0])
        q=Vector((0,0,1)).rotation_difference(tangent.normalized())
        for i in range(10):
            p=Vector(at)+q@Vector(((radius-.023)*math.cos(i*math.tau/10),(radius-.023)*math.sin(i*math.tau/10),0))
            if index==3: p.z+=.023*math.sin(i*3.2)
            verts.append(p)
    faces=[]
    for base in [0,40]:
        for row in range(3):
            for i in range(10):
                j=(i+1)%10
                face=(base+row*10+i,base+row*10+j,base+(row+1)*10+j,base+(row+1)*10+i)
                faces.append(tuple(reversed(face)) if base else face)
    for row in [0,3]:
        for i in range(10):
            j=(i+1)%10
            face=(row*10+i,row*10+40+i,row*10+40+j,row*10+j)
            faces.append(tuple(reversed(face)) if row==0 else face)
    obj=mesh('Hollow torn pipe',verts,faces,'iron')
    obj.data.materials.append(geometry.MATERIALS['rust'])
    for face in obj.data.polygons:
        if face.index%9==0 or face.index>=70: face.material_index=1
    ring('Wall flange',(0,-.025,.28),(.19,.19),.035,'iron_edge',12)
    for i in range(4):
        a=i*math.tau/4
        lump('Flange bolt',(.172*math.cos(a),-.062,.28+.172*math.sin(a)),(.018,.012,.018),'rust',i)

def gutter():
    # A shallow open U-channel. Water remains a separate controller-owned asset.
    for z in [-.42,.41]:
        box('Gutter wall bracket',(0,.005,z),(.23,.04,.075),'rust')
    box('Gutter back',(0,-.025,0),(.21,.03,.98),'iron')
    for x in [-.11,.11]: box('Gutter side',(x,-.105,0),(.025,.19,.98),'iron_edge')
    box('Silt stripe',(0,-.045,-.15),(.09,.009,.62),'silt')
    box('Lower bent lip',(.01,-.15,-.47),(.22,.20,.035),'rust',(-.12,0,.05))

BUILDERS={
    'palisade-intact':lambda:palisade(False),'palisade-broken':lambda:palisade(True),
    'watch-post':watch_post,'overhead-walkway':walkway,'hanging-cage':cage,'hanging-bracket':bracket,
    'throne-platform':platform,'throne-seat':throne,
    'sluice-frame':lambda:frame(False),'sluice-shutter':lambda:shutter(False),'sluice-wheel':wheel,
    'flow-frame':lambda:frame(True),'flow-shutter':lambda:shutter(True),'flow-drum':drum,
    'broken-pipe':pipe,'wall-gutter':gutter,
}
assets=[geometry.export(name,build,material_groups={}) for name,build in BUILDERS.items()]
recipes=[
    {'id':'palisade','batch':'fortress','mount':'floor','parts':{'Fresh':'palisade-intact','Spent':'palisade-broken'},'states':True},
    {'id':'watch-post','batch':'fortress','mount':'floor','parts':{'Model':'watch-post'}},
    {'id':'overhead-walkway','batch':'fortress','mount':'ceiling','parts':{'Model':'overhead-walkway'}},
    {'id':'hanging-cage','batch':'fortress','mount':'ceiling','parts':{'Model':'hanging-cage'}},
    {'id':'hanging-bracket','batch':'fortress','mount':'wall','parts':{'Model':'hanging-bracket'}},
    {'id':'throne','batch':'fortress','mount':'floor','parts':{'Platform':'throne-platform','Seat':'throne-seat'}},
    {'id':'sluice','batch':'waterworks','mount':'floor-wall','parts':{'Frame':'sluice-frame','Lift/Model':'sluice-shutter','Wheel/Model':'sluice-wheel'},
     'states':True,'lift':1.04,'lift_origin':[.27,.15,.22],'wheel_origin':[-.56,1.10,.26],'spin_axis':[0,0,1]},
    {'id':'flow-gate','batch':'waterworks','mount':'floor-wall','parts':{'Frame':'flow-frame','Lift/Model':'flow-shutter','Wheel/Model':'flow-drum'},
     'states':True,'lift':1.04,'lift_origin':[0,.15,.22],'wheel_origin':[0,2.14,.17],'spin_axis':[1,0,0]},
    {'id':'broken-pipe','batch':'waterworks','mount':'wall','parts':{'Model':'broken-pipe'}},
    {'id':'wall-gutter','batch':'waterworks','mount':'wall','parts':{'Model':'wall-gutter'}},
]
lookup={a['id']:a for a in assets}
for recipe in recipes:
    lows=[]
    highs=[]
    for node,name in recipe['parts'].items():
        entry=lookup[name]
        lo=[entry['min'][0],entry['min'][2],-entry['max'][1]]
        hi=[entry['max'][0],entry['max'][2],-entry['min'][1]]
        offset=recipe.get('lift_origin',[0,0,0]) if node.startswith('Lift/') else (recipe.get('wheel_origin',[0,0,0]) if node.startswith('Wheel/') else [0,0,0])
        lows.append([lo[i]+offset[i] for i in range(3)])
        highs.append([hi[i]+offset[i]+(recipe.get('lift',0) if node.startswith('Lift/') and i==1 else 0) for i in range(3)])
    recipe['bounds_min']=[min(p[i] for p in lows) for i in range(3)]
    recipe['bounds_max']=[max(p[i] for p in highs) for i in range(3)]
    # At most the visible state, excluding the hidden palisade sibling.
    recipe['triangles']=sum(lookup[name]['triangles'] for name in recipe['parts'].values())
    if recipe['id']=='palisade': recipe['triangles']=max(lookup[name]['triangles'] for name in recipe['parts'].values())
sources=[]
for name in ['chair.glb','LICENSE.txt']:
    sources.append({'file':str((SOURCE/name).relative_to(ROOT)).replace('\\','/'),
                    'sha256':hashlib.sha256((SOURCE/name).read_bytes()).hexdigest(),
                    'licence':str((SOURCE/'LICENSE.txt').relative_to(ROOT)).replace('\\','/')})
(ART/'catalog.json').write_text(json.dumps({'issue':246,'assets':assets,'recipes':recipes,
    'palette':geometry.COLOURS,'sources':sources,'cell_metres':2,'wall_metres':2.4,'wall_facing':'+Z',
    'builder_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
    'helpers_sha256':hashlib.sha256(Path(geometry.__file__).read_bytes()).hexdigest()},indent=2)+'\n',encoding='utf-8')
print('FORTRESS_WATERWORKS',[(r['id'],r['triangles']) for r in recipes])
