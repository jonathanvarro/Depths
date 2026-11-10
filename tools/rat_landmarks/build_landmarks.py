"""Authored low-poly event landmarks, reusing the established mine mesh helpers."""
import argparse,importlib.util,json,math,sys
from pathlib import Path
import bpy
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser(); parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
spec=importlib.util.spec_from_file_location('mine_geometry',ROOT/'tools/mine_props/build_models.py')
g=importlib.util.module_from_spec(spec); spec.loader.exec_module(g)
g.ART=ROOT/'art/props/shrine-events-3d-v1'; g.ART.mkdir(parents=True,exist_ok=True)
g.MASTERS=args.workspace/'build/local-rat-landmarks-v1/masters/landmarks'; g.MASTERS.mkdir(parents=True,exist_ok=True)
for name,colour in {'stain':'302927','stone_black':'272b28','water':'3e4c3e','water_light':'596350',
                    'rope':'77705a','canvas':'72634c','ivory':'c4b78f'}.items():
    g.COLOURS[name]=colour
    m=bpy.data.materials.new(name); m.diffuse_color=(*(int(colour[i:i+2],16)/255 for i in (0,2,4)),1)
    g.MATERIALS[name]=m
box,beam,lump,stone,mesh=g.box,g.beam,g.lump,g.stone,g.mesh_object

def tube(name,points,radius,material,sides=6):
    vs=[]; ps=[Vector(p) for p in points]
    for i,p in enumerate(ps):
        tangent=(ps[min(i+1,len(ps)-1)]-ps[max(i-1,0)]).normalized()
        u=tangent.cross(Vector((0,0,1)))
        if u.length<.01: u=tangent.cross(Vector((1,0,0)))
        u.normalize(); v=tangent.cross(u).normalized()
        for j in range(sides): vs.append(p+radius*(u*math.cos(j*math.tau/sides)+v*math.sin(j*math.tau/sides)))
    faces=[tuple(reversed(range(sides))),tuple((len(ps)-1)*sides+j for j in range(sides))]
    for i in range(len(ps)-1):
        for j in range(sides):
            k=(j+1)%sides; faces.append((i*sides+j,i*sides+k,(i+1)*sides+k,(i+1)*sides+j))
    return mesh(name,vs,faces,material)

def ring(at,radius,thickness,material,segments=20):
    ps=[(at[0]+radius*math.cos(i*math.tau/segments),at[1]+radius*math.sin(i*math.tau/segments),at[2]) for i in range(segments+1)]
    return tube('Irregular ring',ps,thickness,material,4)

def shrine_base():
    g.shrine_base()
    # Dark smears remain in both states; a resolved event does not necessarily bless it.
    for i in range(4):
        beam('Dried defilement',(-.25+i*.13,-.238,.98+i*.034),(-.22+i*.12,-.240,.76+i*.025),.045,.006,'stain',i)

def shrine_tokens(spent):
    if not spent:
        obj=lump('Warm black stone',(0,-.36,.77),(.16,.10,.13),'stone_black',42)
        obj.rotation_euler.y=.20
        for i in range(2): lump('Candle knocked aside',(-.30+i*.57,-.32,.68),(.055,.035,.018),'wax',i)
    else:
        for i in range(4): lump('Disturbed black fragments',(-.23+i*.15,-.36+(i%2)*.05,.68),(.036,.025,.021),'stone_black',i)
        lump('Moved candle stump',(.25,-.39,.69),(.03,.03,.028),'wax',1)

def well_base():
    # Two uneven courses with an open central shaft. Stones follow the ring.
    for row in range(2):
        for i in range(13):
            a=(i+row*.5)*math.tau/13
            at=(math.cos(a)*.57,math.sin(a)*.57,.13+row*.215)
            stone(at,(.28,.22,.235),'stone_light' if i%5==0 else 'stone',i+row*17)
            bpy.context.object.rotation_euler.z=a+math.pi/2
    # Inset dark bowl hides the underlying room floor without a new hole/collision.
    rings=[]
    for r,z in [(.45,.25),(.40,.105),(0,.095)]:
        for i in range(20): rings.append((r*math.cos(i*math.tau/20),r*math.sin(i*math.tau/20),z))
    fs=[]
    for row in range(2):
        for i in range(20):
            j=(i+1)%20; fs.append((row*20+i,row*20+j,(row+1)*20+j,(row+1)*20+i))
    mesh('Dark well lining',rings,fs,'stone_dark')
    # Split staves form a real hollow, leaning bucket.
    for i in range(9):
        a=i*math.tau/10
        beam('Rotted bucket stave',(.74+.09*math.cos(a),-.20+.09*math.sin(a),.025),
             (.76+.12*math.cos(a),-.20+.12*math.sin(a),.29-(.045 if i==4 else 0)),.062,.025,'wood',i)
    for z in [.065,.23]: ring((.75,-.20,z),.104,.008,'rust',10)
    tube('Frayed rope',[(.46,.23,.44),(.44,.25,.31),(.43,.28,.19),(.45,.27,.12)],.012,'rope')
    for i in range(3): tube('Loose rope end',[(.45,.27,.12),(.46+i*.012,.28,.09),(.48+i*.02,.30,.085)],.004,'rope',4)

def well_surface(spent):
    # Opaque surface, visual only; no transparency sorting, flow or extra light.
    ps=[(0,0,.145)]
    for i in range(24):
        a=i*math.tau/24; ps.append((.413*math.cos(a),.413*math.sin(a),.145))
    mesh('Still fouled water',ps,[(0,i+1,(i+1)%24+1) for i in range(24)],'water')
    for i in range(4 if spent else 2):
        a=i*2.3
        lump('Algae separated' if spent else 'Surface scum',(.21*math.cos(a),.22*math.sin(a),.148),(.07,.04,.002),'water_light',i)
    if spent:
        for r in [.115,.23,.33]: ring((-.04,-.03,.151),r,.005,'water_light',24)
        beam('Displaced rim splinter',(.43,-.20,.45),(.59,-.31,.45),.025,.015,'wood_light',13)

def crown(at):
    x,y,z=at
    # A rough royal stamp on the crate, modeled without a borrowed insignia.
    mesh('Royal three-point stamp',[(x-.08,y,z),(x+.08,y,z),(x+.10,y,z+.09),
         (x+.04,y,z+.055),(x,y,z+.12),(x-.04,y,z+.055),(x-.10,y,z+.09)],[(0,1,2,3,4,5,6)],'copper')

def cache_base():
    for i in range(7):
        at=(((i*37)%11-5)*.11,((i*23)%9-4)*.12,.09)
        lump('Fallen rubble',at,(.22,.18,.13),'stone_dark' if i%2 else 'stone',i)
    for x in [-.43,.43]:
        for z in [.13,.27]: beam('Crate side rail',(x,-.29,z),(x,.32,z),.10,.07,'wood',int(z*100))
    for i in range(5): beam('Crate bottom',(-.36+i*.18,-.31,.07),(-.36+i*.18,.32,.07),.16,.05,'wood_dark',i)
    for i in range(4): beam('Back crate plank',(-.36+i*.24,.33,.12),(-.36+i*.24,.33,.38),.21,.05,'wood',i)
    for i in range(4): beam('Front crate plank',(-.36+i*.24,-.33,.12),(-.36+i*.24,-.33,.38),.21,.05,'wood_light',i)
    crown((.0,-.371,.19))
    for x in [-.30,.30]:
        box('Rusted front band',(x,-.377,.24),(.045,.018,.32),'rust')
        for z in [.11,.37]: lump('Band nail',(x,-.39,z),(.012,.008,.012),'iron_edge',int(z*100))

def cache_top(spent):
    if not spent:
        for i in range(5): beam('Buried lid plank',(-.42,-.25+i*.13,.405),(.42,-.25+i*.13,.40),.12,.055,'wood',i)
        for i,at in enumerate([(-.42,.11,.52),(-.23,.29,.60),(.12,.30,.55),(-.53,.29,.32)]):
            lump('Overburden',at,(.27,.23,.22),'stone' if i%2 else 'stone_light',i+8)
    else:
        for i in range(3): beam('Broken lid lifted aside',(.47,-.27+i*.14,.04),(.74,.32+i*.08,.12),.11,.035,'wood_light',i)
        for i,at in enumerate([(-.58,.24,.19),(-.43,.43,.18),(.09,.52,.17)]):
            lump('Shifted overburden',at,(.22,.18,.17),'stone',i+8)
        for i in range(3): lump('Empty crate dust',(-.17+i*.18,.0,.10),(.07,.09,.01),'ash',i)

assets=[]
for name,build in [('shrine-base',shrine_base),('shrine-fresh',lambda:shrine_tokens(False)),('shrine-spent',lambda:shrine_tokens(True)),
                   ('well-base',well_base),('well-fresh',lambda:well_surface(False)),('well-spent',lambda:well_surface(True)),
                   ('cache-base',cache_base),('cache-fresh',lambda:cache_top(False)),('cache-spent',lambda:cache_top(True))]:
    assets.append(g.export(name,build,material_groups={}))
catalog={'issue':252,'palette':g.COLOURS,'assets':assets,'front':'+Z','cell_metres':2,
    'recipes':{'defiled-shrine':['shrine-base','shrine-fresh','shrine-spent'],
               'fouled-well':['well-base','well-fresh','well-spent'],
               'buried-cache':['cache-base','cache-fresh','cache-spent']},
    'mounts':{'defiled-shrine':'wall, floor-height origin; stone back at local Z=0',
              'fouled-well':'floor centre','buried-cache':'floor centre'}}
(g.ART/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n')
print('LANDMARK_MODELS',[(a['id'],a['triangles']) for a in assets])
