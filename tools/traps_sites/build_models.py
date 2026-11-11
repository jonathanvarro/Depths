"""#247 worn traps and strange sites. Geometry only, no hazard authority."""
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
ART=ROOT/'art/props/traps-sites-3d-v1'
geometry.ART=ART
geometry.MASTERS=args.workspace/'build/local-traps-sites-mist-v1/masters'
ART.mkdir(parents=True,exist_ok=True)
geometry.MASTERS.mkdir(parents=True,exist_ok=True)
(geometry.MASTERS/'.gdignore').write_text('',encoding='utf-8')
for name,colour in {'rope':'98815b','idol':'b3ad92','idol_shade':'858574',
                    'water':'354f50','ripple':'72827a','void':'11191a','silt':'5b6551'}.items():
    geometry.COLOURS[name]=colour
    material=bpy.data.materials.new(name)
    material.diffuse_color=(*(int(colour[i:i+2],16)/255 for i in (0,2,4)),1)
    geometry.MATERIALS[name]=material
box=geometry.box
beam=geometry.beam
lump=geometry.lump
stone=geometry.stone
mesh=geometry.mesh_object

def tube(name,a,b,radius,material='iron',sides=6):
    a,b=Vector(a),Vector(b)
    q=Vector((0,0,1)).rotation_difference((b-a).normalized())
    verts=[at+q@Vector((radius*math.cos(i*math.tau/sides),radius*math.sin(i*math.tau/sides),0)) for at in [a,b] for i in range(sides)]
    faces=[tuple(reversed(range(sides))),tuple(range(sides,2*sides))]
    faces.extend((i,(i+1)%sides,(i+1)%sides+sides,i+sides) for i in range(sides))
    return mesh(name,verts,faces,material)

def ring(name,at,radii,width,material='rope',plane='XY',segments=16):
    verts=[]
    for i in range(segments):
        t=i*math.tau/segments
        for j in range(4):
            p=j*math.tau/4
            u=(radii[0]+width*math.cos(p))*math.cos(t)
            v=(radii[1]+width*math.cos(p))*math.sin(t)
            d=width*math.sin(p)
            verts.append(Vector(at)+Vector((u,v,d) if plane=='XY' else (u,d,v)))
    faces=[]
    for i in range(segments):
        for j in range(4):
            f=(i*4+j,((i+1)%segments)*4+j,((i+1)%segments)*4+(j+1)%4,i*4+(j+1)%4)
            # XY and XZ have opposite orientation.
            faces.append(f if plane=='XY' else tuple(reversed(f)))
    return mesh(name,verts,faces,material)

def disc(name,radius,z,material,seed=1):
    rng=random.Random(seed)
    verts=[(0,0,z)]+[(radius*math.cos(i*math.tau/20)*rng.uniform(.95,1.05),radius*math.sin(i*math.tau/20)*.78,z) for i in range(20)]
    return mesh(name,verts,[(0,i+1,(i+1)%20+1) for i in range(20)],material)

def tripwire(state):
    for i,x in enumerate([-.70,.70]):
        beam('Hammered stake',(x,0,0),(x+.025,0,.34),.065,.06,'wood',i)
        box('Rusty wire collar',(x,-.004,.12),(.075,.075,.04),'rust')
    if state=='closed':
        tube('Taut tripwire',(-.70,0,.12),(.70,0,.12),.006,'iron_edge',4)
    else:
        for i in range(3): ring('Loose wire coil',(-.60+i*.015,-.07,.027+i*.006),(.072,.058),.004,'iron_edge')
        end=(.42,-.16,.018) if state=='empty' else (-.32,-.10,.021)
        tube('Released tripwire',(-.65,-.04,.09),end,.006,'iron_edge',4)
        if state=='empty':
            for i in range(3): stone((.18+i*.15,-.13+(i%2)*.2,.05),(.17,.14,.11),'stone',i)

def little_bell(at,tilt=0):
    before=set(bpy.context.scene.objects)
    verts=[]
    sections=[(.105,0),(.10,.024),(.062,.085),(.037,.125),(.023,.139),(.016,.123),(.039,.108),(.08,.024)]
    for radius,z in sections:
        for i in range(12): verts.append(Vector(at)+Vector((radius*math.cos(i*math.tau/12),radius*math.sin(i*math.tau/12),z)))
    faces=[]
    for row in range(len(sections)-1):
        for i in range(12): faces.append((row*12+i,row*12+(i+1)%12,(row+1)*12+(i+1)%12,(row+1)*12+i))
    for i in range(12): faces.append((i,7*12+i,7*12+(i+1)%12,(i+1)%12))
    obj=mesh('Hollow goblin bell',verts,faces,'copper')
    tube('Single bell clapper',Vector(at)+Vector((0,0,-.012)),Vector(at)+Vector((0,0,.10)),.012,'iron',6)
    ring('Bell eye',Vector(at)+Vector((0,0,.15)),(.022,.027),.007,'iron_edge','XZ',10)
    if tilt:
        from mathutils import Matrix
        pivot=Vector(at)+Vector((0,0,.14))
        for obj in set(bpy.context.scene.objects)-before:
            coords=[pivot+Matrix.Rotation(tilt,3,'Y')@(obj.matrix_world@v.co-pivot) for v in obj.data.vertices]
            obj.matrix_world.identity()
            for vertex,point in zip(obj.data.vertices,coords): vertex.co=point

def bell_alarm(state):
    for i,x in enumerate([-.62,.62]): beam('Alarm stake',(x,0,0),(x,0,.50),.06,.065,'wood_dark',i+9)
    if state=='closed':
        tube('Alarm line',(-.62,0,.27),(.62,0,.27),.006,'iron_edge',4)
        little_bell((0,0,.11))
    elif state=='open':
        little_bell((-.47,-.13,.02))
        for i in range(2): ring('Coiled alarm line',(-.45,-.07,.026+i*.009),(.12,.07),.005,'iron_edge')
    else:
        little_bell((.07,-.025,.095),.38)
        tube('Snapped alarm line',(-.62,0,.27),(-.14,-.09,.035),.006,'iron_edge',4)
        tube('Slack alarm line',(.10,0,.26),(.62,0,.32),.006,'iron_edge',4)

def snare(state):
    beam('Snare peg',(.34,.20,.005),(.31,.20,.58 if state=='empty' else .34),.05,.055,'wood_light',3)
    for i in range(2): ring('Peg binding',(.32,.20,.21+i*.025),(.038,.033),.009,'rope')
    if state=='closed':
        ring('Set noose',(-.05,-.06,.025),(.25,.20),.012)
        tube('Set line',(.18,.04,.025),(.32,.20,.22),.011,'rope',5)
    elif state=='empty':
        ring('Drawn noose',(.14,.12,.39),(.075,.105),.012,'rope','XZ')
        tube('Pulled line',(.16,.13,.48),(.31,.20,.56),.011,'rope',5)
    else:
        for i in range(3): ring('Released rope coil',(-.10+i*.016,-.03,.025+i*.014),(.14,.11),.011)

def dart(state):
    for i in range(10):
        a=i*math.tau/10
        stone((math.cos(a)*.38,math.sin(a)*.33,.042),(.18,.15,.085),'stone_dark',i)
    stone((0,0,.065 if state=='closed' else .035),(.56,.49,.10),'stone_light',18)
    if state=='open':
        beam('Disarming wedge',(-.24,-.23,.025),(-.13,-.20,.105),.06,.04,'wood_light',4)
    if state=='empty':
        for i in range(3):
            tube('Spent dart',(-.24+i*.18,-.38,.025),(-.12+i*.18,-.11,.032),.008,'wood_dark',5)
            lump('Iron dart head',(-.12+i*.18,-.11,.032),(.016,.025,.008),'iron_edge',i)

def dart_ports():
    stone((0,.015,0),(.40,.11,.19),'stone_dark',22)
    for x in [-.11,0,.11]:
        # Recessed dark holes and solid rims face the open cell.
        ring('Dart port',(x,-.058,0),(.025,.025),.010,'iron_edge','XZ',10)
        box('Dark port recess',(x,-.057,0),(.043,.008,.043),'void')

def hollow_floor(state):
    if state=='closed':
        for row in range(3):
            for col in range(3):
                stone(((col-1)*.36,(row-1)*.31,.038),(.35,.30,.065),'stone' if (row+col)%2 else 'stone_light',row*3+col)
        # Narrow open gaps and staggered heights suggest fragile slabs.
        tube('Crack',(-.4,-.08,.078),(.14,.22,.078),.008,'void',4)
    else:
        disc('Opaque pit interior',.64,.018,'void')
        for i in range(12):
            a=i*math.tau/12
            stone((.64*math.cos(a),.50*math.sin(a),.073),(.25,.22,.16),'stone_dark' if i%2 else 'stone',i)
        for i in range(3):
            stone(((i-1)*.17,.24,.048),(.20,.15,.07),'stone_dark',i+20)

def idol_figure(at,toppled=False):
    before=set(bpy.context.scene.objects)
    lump('Carved knees',Vector(at)+Vector((0,-.025,.09)),(.15,.12,.09),'idol_shade',1)
    lump('Carved torso',Vector(at)+Vector((0,0,.25)),(.10,.075,.16),'idol',4)
    lump('Featureless head',Vector(at)+Vector((0,-.01,.47)),(.071,.063,.09),'idol',8)
    for side in [-1,1]:
        beam('Folded forearm',Vector(at)+Vector((side*.085,-.055,.30)),Vector(at)+Vector((-side*.035,-.10,.21)),.05,.047,'idol_shade',3)
    if toppled:
        from mathutils import Matrix
        pivot=Vector(at)
        bpy.context.view_layer.update()
        for obj in set(bpy.context.scene.objects)-before:
            world=obj.matrix_world.copy()
            coords=[pivot+Matrix.Rotation(math.pi/2,3,'X')@(world@v.co-pivot) for v in obj.data.vertices]
            obj.matrix_world=Matrix.Identity(4)
            for vertex,point in zip(obj.data.vertices,coords): vertex.co=point+Vector((.21,-.13,.03))

def idol_niche(state):
    for side in [-1,1]:
        for i in range(3): stone((side*.29,.035,.16+i*.25),(.20,.25,.24),'stone_dark',i+7*side)
    for i in range(5):
        a=i*math.pi/4
        stone((.29*math.cos(a),.035,.65+.23*math.sin(a)),(.21,.27,.19),'stone',i+40)
    stone((0,-.02,.055),(.73,.48,.11),'stone',8)
    box('Niche shadow',(0,-.035,.47),(.45,.025,.73),'void')
    if state=='closed': idol_figure((0,-.05,.12))
    else:
        lump('Pale dust footprint',(0,-.07,.117),(.12,.09,.009),'ash',1)
        if state=='empty': idol_figure((0,-.05,.12),True)

def pool(state):
    disc('Pool surface',.55,.062,'water',6)
    for i in range(13):
        a=i*math.tau/13
        stone((.57*math.cos(a),.45*math.sin(a),.075),(.23,.19,.15),'stone_dark' if i%3 else 'stone',i+20)
    if state=='empty':
        for i in range(3): ring('Disturbed water ring',(.03,-.03,.066+i*.001),(.13+i*.10,.10+i*.08),.005,'ripple',segments=24)

families={'tripwire':tripwire,'bell-alarm':bell_alarm,'snare':snare,'dart-plate':dart,
          'hollow-floor':hollow_floor,'idol-niche':idol_niche,'still-pool':pool}
assets=[]
recipes=[]
for name,build in families.items():
    states=['closed','empty'] if name in ['hollow-floor','still-pool'] else ['closed','open','empty']
    models={}
    for state in states:
        model=name+'-'+state
        entry=geometry.export(model,lambda state=state,build=build:build(state),material_groups={'water':'Water'})
        assets.append(entry)
        models[state]=model
    lows=[[a['min'][0],a['min'][2],-a['max'][1]] for a in assets if a['id'] in models.values()]
    highs=[[a['max'][0],a['max'][2],-a['min'][1]] for a in assets if a['id'] in models.values()]
    recipes.append({'id':name,'models':models,'mount':'floor-wall' if name=='idol-niche' else 'floor',
        'batch':'sites' if name in ['idol-niche','still-pool'] else 'traps',
        'bounds_min':[min(v[i] for v in lows) for i in range(3)],
        'bounds_max':[max(v[i] for v in highs) for i in range(3)]})
assets.append(geometry.export('dart-ports',dart_ports,material_groups={}))
(ART/'catalog.json').write_text(json.dumps({'issue':247,'assets':assets,'recipes':recipes,'palette':geometry.COLOURS,
    'builder_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
    'helpers_sha256':hashlib.sha256(Path(geometry.__file__).read_bytes()).hexdigest(),
    'cell_metres':2,'wall_metres':2.4,'wall_facing':'+Z','new_character_clips':False},indent=2)+'\n',encoding='utf-8',newline='\n')
print('TRAPS_SITES',[(a['id'],a['triangles']) for a in assets])
