"""#250 transition/blocker art. Preserve the LevelBuilder floor/-Z contract."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import random
import sys
import bpy
from mathutils import Matrix, Vector

ROOT=Path(__file__).resolve().parents[2]
sys.dont_write_bytecode=True
sys.path.insert(0,str(ROOT/'tools/mine_props'))
import build_models as geometry
parser=argparse.ArgumentParser()
parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
ART=ROOT/'art/features/transitions-3d-v1'
SOURCE=ROOT/'art/third-party/kaykit-transitions-v1'
geometry.ART=ART
geometry.MASTERS=args.workspace/'build/local-transitions-regional-v1/masters'
ART.mkdir(parents=True,exist_ok=True)
geometry.MASTERS.mkdir(parents=True,exist_ok=True)
(geometry.MASTERS/'.gdignore').write_text('',encoding='utf-8')
for name,colour in {'root':'675039','root_dark':'3e3429','web':'a7afa3',
                    'ground':'606158','sky':'b3c3be','void':'11191a',
                    'roof_rock':'42473f','roof_void':'11191a',
                    'distance':'77877a','distance_dark':'526457','outside_path':'a5aa91'}.items():
    geometry.COLOURS[name]=colour
    material=bpy.data.materials.new(name)
    material.diffuse_color=(*(int(colour[i:i+2],16)/255 for i in (0,2,4)),1)
    geometry.MATERIALS[name]=material
box=geometry.box
beam=geometry.beam
lump=geometry.lump
stone=geometry.stone
mesh=geometry.mesh_object

def branch(name,points,radii,material,seed=0,sides=6,smooth=False):
    """Stable transported cross-sections, adapted from the earlier root builder."""
    rng=random.Random(seed)
    points=[Vector(p) for p in points]
    if smooth:
        curved=[]; widths=[]
        for segment in range(len(points)-1):
            a,b,c,d=points[max(0,segment-1)],points[segment],points[segment+1],points[min(len(points)-1,segment+2)]
            for sample in range(3):
                t=sample/3
                curved.append(.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t))
                widths.append(radii[segment]*(1-t)+radii[segment+1]*t)
        points=curved+[points[-1]]
        radii=widths+[radii[-1]]
    tangent=(points[1]-points[0]).normalized()
    axis=tangent.cross(Vector((1,0,0)) if abs(tangent.y)>.9 else Vector((0,1,0))).normalized()
    verts=[]
    for row,(point,radius) in enumerate(zip(points,radii)):
        tangent=(points[min(row+1,len(points)-1)]-points[max(0,row-1)]).normalized()
        axis-=tangent*axis.dot(tangent)
        if axis.length_squared<.000001: axis=tangent.cross(Vector((1,0,0)))
        axis.normalize()
        other=tangent.cross(axis)
        for i in range(sides):
            a=i*math.tau/sides
            verts.append(point+(axis*math.cos(a)+other*math.sin(a))*radius*rng.uniform(.91,1.08))
    faces=[tuple(reversed(range(sides)))]
    for row in range(len(points)-1):
        for i in range(sides): faces.append((row*sides+i,row*sides+(i+1)%sides,(row+1)*sides+(i+1)%sides,(row+1)*sides+i))
    faces.append(tuple(range((len(points)-1)*sides,len(points)*sides)))
    return mesh(name,verts,faces,material)

def floor_frame():
    for x in [-.85,.85]: box('Floor apron',(x,0,-.018),(.30,2,.036),'ground')
    for y in [-.925,.925]: box('Floor apron',(0,y,-.018),(1.40,.15,.036),'ground')

def source_stairs(wood,down):
    name='stairs-wood.glb' if wood else 'stairs-stone.glb'
    bpy.ops.import_scene.gltf(filepath=str(SOURCE/name),import_pack_images=True)
    imported=list(bpy.context.selected_objects)
    objects=[o for o in imported if o.type=='MESH']
    bpy.context.view_layer.update()
    points=[o.matrix_world@v.co for o in objects for v in o.data.vertices]
    lowz=min(p.z for p in points); highz=max(p.z for p in points)
    upper=[p for p in points if p.z>lowz+(highz-lowz)*.80]
    lower=[p for p in points if p.z<lowz+(highz-lowz)*.20]
    delta=sum(upper,Vector())/len(upper)-sum(lower,Vector())/len(lower)
    angle=math.pi/2-math.atan2(delta.y,delta.x)+(math.pi if down else 0)
    rotation=Matrix.Rotation(angle,3,'Z')
    rotated=[rotation@p for p in points]
    low=Vector(tuple(min(p[i] for p in rotated) for i in range(3)))
    high=Vector(tuple(max(p[i] for p in rotated) for i in range(3)))
    centre=(low+high)/2
    for obj in objects:
        coords=[rotation@(obj.matrix_world@v.co) for v in obj.data.vertices]
        obj.parent=None
        obj.matrix_world=Matrix.Identity(4)
        obj.data.materials.clear()
        for material in (['wood','wood_light','wood_dark'] if wood else ['stone','stone_light','stone_dark']): obj.data.materials.append(geometry.MATERIALS[material])
        for face in obj.data.polygons: face.material_index=1 if face.normal.z>.5 else (2 if face.index%5==0 else 0)
        for vertex,point in zip(obj.data.vertices,coords):
            x=(point.x-centre.x)/(high.x-low.x)*1.28
            y=(point.y-centre.y)/(high.y-low.y)*1.65
            z=(point.z-low.z)/(high.z-low.z)*(.90 if down else .72)-(.90 if down else 0)
            x+=.008*math.sin(y*9+x*7)
            if not down and z>.02: z-=.008*(1-min(1,abs(x)/.64))*math.sin(y*8)**2
            vertex.co=Vector((x,y,z))
        obj.name='Worn source stair flight'
    for obj in imported:
        if obj.type!='MESH': bpy.data.objects.remove(obj,do_unlink=True)

def stairs(wood,down):
    source_stairs(wood,down)
    if down:
        floor_frame()
        for x in [-.69,.69]: box('Recessed stairwell side',(x,0,-.46),(.025,1.70,.94),'stone_dark')
        box('Lower dark landing',(0,0,-.925),(1.40,1.70,.025),'void')
        box('Recessed end wall',(0,.85,-.46),(1.40,.025,.94),'stone_dark')
    for side in [-1,1]:
        x=side*.80
        if wood:
            for i,y in enumerate([-.75,.10,.75]):
                height=.35 if down else .35+(y+.75)/1.5*.72
                beam('Scavenged rail post',(x,y,.01),(x+.01,y,height),.065,.06,'wood_dark',i+side*7)
            beam('Crooked handrail',(x,-.78,.35),(x,.78,.35 if down else 1.10),.07,.065,'wood_light',8)
            box('Iron patch',(x,-.52,.35),(.075,.13,.018),'rust')
        else:
            for i in range(6):
                y=-.74+i*.295
                z=.13 if down else .12+i*.132
                stone((x,y,z),(.19,.29,.24),'stone_dark' if i%2 else 'stone',i+side*9)
    if not down:
        # A short visible flight disappears into the transition throat.
        for side in [-1,1]:
            if wood: beam('Upper timber jamb',(side*.78,.88,.02),(side*.78,.88,2.30),.13,.12,'wood',side+7)
            else:
                for i in range(6): stone((side*.78,.88,.18+i*.35),(.22,.20,.34),'stone_dark',i+side*6)
        beam('Upper lintel',(-.83,.88,2.28),(.83,.88,2.29),.15,.18,'wood_dark' if wood else 'stone',4)
        box('Upper passage shadow',(0,.925,1.48),(1.39,.02,1.56),'void')

def round_pit():
    verts=[]
    for radius,z in [(1,0),(.69,.012),(.53,-.90)]:
        for i in range(24):
            a=i*math.tau/24
            if radius==1:
                factor=1/max(abs(math.cos(a)),abs(math.sin(a)))
                verts.append((math.cos(a)*factor,math.sin(a)*factor,z))
            else: verts.append((radius*math.cos(a),radius*1.13*math.sin(a),z))
    mesh('Square to round floor apron',verts[:48],[(i,(i+1)%24,(i+1)%24+24,i+24) for i in range(24)],'ground')
    mesh('Recessed shaft walls',verts[24:],[(i,(i+1)%24,(i+1)%24+24,i+24) for i in range(24)],'stone_dark')
    mesh('Dark shaft bottom',verts[48:],[tuple(range(24))],'void')
    for i in range(10):
        a=i*math.tau/10
        lump('Chipped pit lip',(.72*math.cos(a),.80*math.sin(a),.025),(.11,.10,.07),'stone',i)

def ledge():
    round_pit()
    for i in range(3): stone((-.48+i*.10,-.51+i*.15,-.15-i*.23),(.24,.28,.13),'stone',i+40)
    beam('Broken landing timber',(.55,-.65,.025),(.53,.15,-.08),.10,.085,'wood_dark',5)

def root_climb():
    # Top cap masks the existing ceiling; controller owns actual level travel.
    for i in range(12):
        a=i*math.tau/12
        lump('Ceiling shaft rim',(.60*math.cos(a),.42*math.sin(a),2.33),(.10,.10,.065),'roof_rock',i)
    points=[(.56*math.cos(i*math.tau/24),.38*math.sin(i*math.tau/24),2.365) for i in range(24)]
    mesh('Dark upward aperture',points,[tuple(reversed(range(24)))],'roof_void')
    for i,x in enumerate([-.45,-.17,.18,.45]):
        path=[(x,.04,2.38),(x+.07,-.03,1.93),(x-.04,-.02,1.44),(x+.06,-.08,.89),(x-.03,-.14,.40),(x+.08,-.18,.06)]
        branch('Climbable hanging root',path,[.070,.061,.055,.048,.034,.015],'root',i+2,7,smooth=True)
        for j in [1,2,3]: branch('Root handhold',[path[j],(x+.13,-.13,path[j][2]-.13),(x-.05,-.10,path[j][2]-.20)],[.028,.022,.008],'root_dark',i+j,6)

def daylight():
    for side in [-1,1]:
        for i in range(5): lump('Cave mouth cheek',(side*(.84+.02*math.sin(i)),.33,.18+i*.42),(.145,.27,.25),'stone_dark' if i%2 else 'stone',i+7*side)
    for i in range(7):
        a=i*math.pi/6
        lump('Mouth arch',(.80*math.cos(a),.33,1.87+.28*math.sin(a)),(.17,.28,.21),'stone',i+30)
    mesh('Muted daylight backdrop',[(-.68,.58,.03),(.68,.58,.03),(.68,.58,1.80),(.57,.58,1.95),
        (.34,.58,2.08),(0,.58,2.13),(-.34,.58,2.08),(-.57,.58,1.95),(-.68,.58,1.80)],
        [tuple(range(9))],'sky')
    # A shallow, fixed vista suggests daylight beyond the aperture without a new zone.
    mesh('Distant ridge',[(-.66,.54,.03),(.66,.54,.03),(.66,.54,.85),(.49,.54,1.10),
        (.13,.54,.90),(-.18,.54,1.27),(-.50,.54,1.04),(-.66,.54,1.10)],
        [tuple(range(8))],'distance_dark')
    mesh('Near hillside',[(-.66,.51,.03),(.66,.51,.03),(.66,.51,.59),(.40,.51,.70),
        (.09,.51,.49),(-.25,.51,.66),(-.66,.51,.83)],[tuple(range(7))],'distance')
    mesh('Pale path beyond mouth',[(-.28,.49,.03),(.20,.49,.03),(.10,.49,.32),(.17,.49,.47),
        (.04,.49,.50),(-.08,.49,.31)],[tuple(range(6))],'outside_path')
    for side in [-1,1]: branch('Mouth hanging root',[(side*.54,.16,2.13),(side*.57,.08,1.90),(side*.43,.03,1.72)],[.035,.022,.005],'root_dark',side+9)

def web(torn):
    centre=Vector((-.15,0,1.28))
    outer=[]
    for i in range(16):
        a=i*math.tau/16
        outer.append(Vector((.94*math.cos(a),.04*math.sin(i*2),1.20+1.10*math.sin(a))))
    if not torn:
        for i,end in enumerate(outer):
            middle=centre.lerp(end,.52)+Vector((.01,-.045,.012))
            branch('Radial silk',[centre,middle,end],[.006,.005,.005],'web',i,3)
    for row in range(1,5):
        amount=row/4
        ring=[centre.lerp(end,amount)+Vector((0,.025*math.sin(i+row),.01*math.sin(i*2+row))) for i,end in enumerate(outer)]
        for i,a in enumerate(ring):
            b=ring[(i+1)%16]
            if torn and (abs(a.x)<.62 or abs(b.x)<.62) and min(a.z,b.z)<2.12: continue
            branch('Irregular spiral silk',[a,(a+b)/2+Vector((0,-.015,-.02)),b],[.005,.0045,.005],'web',i+row,3)
    if torn:
        for side in [-1,1]:
            branch('Torn dangling silk',[(side*.91,0,2.20),(side*.74,-.10,1.84),(side*.81,-.15,1.35)],[.009,.006,.003],'web',side+6,3)

def root_barrier():
    for i,x in enumerate([-.84,-.56,-.27,.10,.40,.70,.85]):
        path=[(x,.10*math.sin(i),-.01),(x+.07,-.13,.45),(x-.07,.10,.94),(x+.03,-.07,1.48),(x-.04,.08,1.92),(x,.02,2.36)]
        branch('Dense twisted root',path,[.10,.10,.085,.075,.085,.11],'root' if i%2 else 'root_dark',i+3,7,smooth=True)
        for j in [1,2,3]:
            direction=-1 if i>3 else 1
            point=Vector(path[j])
            branch('Crossed root fork',[point,point+Vector((direction*.18,-.12,.16)),point+Vector((direction*.34,.06,.40))],[.06,.041,.008],'root_dark' if i%2 else 'root',i+j+20,6)

builds={'stone-up':lambda:stairs(False,False),'stone-down':lambda:stairs(False,True),
        'fortress-up':lambda:stairs(True,False),'fortress-down':lambda:stairs(True,True),
        'cave-ledge-down':ledge,'root-climb-up':root_climb,'daylight-mouth':daylight,
        'web-intact':lambda:web(False),'web-torn':lambda:web(True),'root-barrier':root_barrier}
assets=[]
for name,build in builds.items():
    entry=geometry.export(name,build,material_groups={'ground':'Ground','sky':'Sky','roof_rock':'Canopy','roof_void':'Canopy',
        'distance':'Vista','distance_dark':'Vista','outside_path':'Vista'})
    entry['batch']='blockers' if name in ['web-intact','web-torn','root-barrier'] else 'transitions'
    entry['direction']='down' if name.endswith('down') else ('up' if name.endswith('up') else 'passage')
    entry['floor_aperture']=entry['direction']=='down'
    assets.append(entry)
sources=[]
for name in ['stairs-stone.glb','stairs-wood.glb','LICENSE.txt']:
    sources.append({'file':(SOURCE/name).relative_to(ROOT).as_posix(),'sha256':hashlib.sha256((SOURCE/name).read_bytes()).hexdigest()})
(ART/'catalog.json').write_text(json.dumps({'issue':250,'assets':assets,'palette':geometry.COLOURS,
    'sources':sources,'cell_metres':2,'wall_metres':2.4,'forward':'-Z',
    'builder_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
    'helpers_sha256':hashlib.sha256(Path(geometry.__file__).read_bytes()).hexdigest()},indent=2)+'\n',encoding='utf-8',newline='\n')
print('TRANSITIONS_3D',[(a['id'],a['triangles']) for a in assets])
