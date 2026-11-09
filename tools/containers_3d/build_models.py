"""Build #242 containers, rest sites and workings with the established prop tools."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import random
import sys

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
sys.dont_write_bytecode = True
sys.path.insert(0,str(ROOT/'tools/mine_props'))
import build_models as geometry

parser=argparse.ArgumentParser()
parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
SOURCE=ROOT/'art/third-party/kaykit-containers-rest-v1'
ART=ROOT/'art/props/expedition-3d-v1'
geometry.ART=ART
geometry.MASTERS=args.workspace/'build/local-expedition-props-v1/masters'
ART.mkdir(parents=True,exist_ok=True)
geometry.MASTERS.mkdir(parents=True,exist_ok=True)
(geometry.MASTERS/'.gdignore').write_text('',encoding='utf-8')
for name,colour in {'canvas':'8a795a','canvas_dark':'635740','leather':'49382a',
                    'gold':'a98b4c','ore_light':'89938a','blanket':'596055'}.items():
    geometry.COLOURS[name]=colour
    material=bpy.data.materials.new(name)
    material.diffuse_color=(*(int(colour[i:i+2],16)/255 for i in (0,2,4)),1)
    geometry.MATERIALS[name]=material

box=geometry.box
beam=geometry.beam
lump=geometry.lump
stone=geometry.stone
mesh_object=geometry.mesh_object

def fitted_source(filename, object_name, scale, origin, kind):
    bpy.ops.import_scene.gltf(filepath=str(SOURCE/filename),import_pack_images=True)
    objects=list(bpy.context.selected_objects)
    obj=next(obj for obj in objects if obj.name==object_name)
    world=obj.matrix_world.copy()
    coordinates=[world@v.co for v in obj.data.vertices]
    image=next(n.image for n in obj.data.materials[0].node_tree.nodes if n.type=='TEX_IMAGE')
    pixels=list(image.pixels)
    colours=[]
    for face in obj.data.polygons:
        uv=obj.data.uv_layers.active.data[face.loop_indices[0]].uv
        x=min(image.size[0]-1,max(0,int(uv.x*image.size[0])))
        y=min(image.size[1]-1,max(0,int(uv.y*image.size[1])))
        rgb=pixels[(y*image.size[0]+x)*4:(y*image.size[0]+x)*4+3]
        if kind=='chest':
            warm=rgb[0]>rgb[1]*1.1 and rgb[0]>rgb[2]*1.2
            material='wood_light' if warm else 'iron'
            if warm and sum(rgb)<.75: material='wood_dark'
            if not warm and face.index%19==0: material='rust'
        else:
            material='canvas' if face.index%7 else 'canvas_dark'
        colours.append(material)
    obj.data.materials.clear()
    names=list(dict.fromkeys(colours))
    for name in names: obj.data.materials.append(geometry.MATERIALS[name])
    for face,name in zip(obj.data.polygons,colours): face.material_index=names.index(name)
    obj.parent=None
    obj.matrix_world.identity()
    for vertex,point in zip(obj.data.vertices,coordinates):
        point-=Vector(origin)
        point.x += .009*math.sin(point.z*4.3+point.y*3.9)
        if kind=='bed':
            point.x += .045*math.sin(point.y*4+point.z*7)
            point.y += .035*math.sin(point.x*7)
            point.z += .07*math.sin(point.y*5+point.x*9)*min(1,max(0,point.z)*4)
        vertex.co=Vector(tuple(point[i]*scale[i] for i in range(3)))
    for other in objects:
        if other!=obj: bpy.data.objects.remove(other,do_unlink=True)
    return obj

CHEST_HINGE=(0,.275,-.5648832321166992*.55)

def chest(part):
    origin=(0,.5648832321166992,.5) if part=='lid' else (0,0,0)
    fitted_source('chest.glb','chest_lid' if part=='lid' else 'chest',(.55,)*3,origin,'chest')

def battered_box(name,at,size,material,seed):
    obj=box(name,at,size,material)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    modifier=obj.modifiers.new('Worn corners','BEVEL')
    modifier.width=.006
    modifier.segments=1
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    rng=random.Random(seed)
    for vertex in obj.data.vertices:
        vertex.co+=Vector(tuple(rng.uniform(-.002,.002) for _ in range(3)))

def strongbox(part):
    if part=='lid':
        battered_box('Dented lid',(0,-.22,.025),(.64,.46,.05),'iron',22)
        for x in [-.22,.22]:
            box('Lid band',(x,-.22,.053),(.045,.47,.012),'rust')
        box('Lid hasp',(0,-.443,-.005),(.065,.02,.10),'iron_edge')
        return
    battered_box('Inside floor',(0,0,.026),(.60,.42,.05),'wood_dark',2)
    for side in [-1,1]:
        battered_box('Front back wall',(0,side*.196,.17),(.60,.035,.28),'iron',side+4)
        battered_box('Side wall',(side*.283,0,.17),(.035,.42,.28),'iron',side+7)
        for x in [-.22,.22]:
            box('Riveted strap',(x,side*.22,.17),(.044,.017,.29),'rust')
            for height in [.075,.265]:
                lump('Rivet',(x,side*.232,height),(.009,.006,.009),'iron_edge',2)
    box('Lock plate',(0,-.222,.22),(.075,.017,.08),'iron_edge')

def sack(at,size,material,seed=0):
    rng=random.Random(seed)
    vertices=[]
    for height,amount in [(0,.65),(.15,1),(.65,.95),(1,.60)]:
        for i in range(10):
            angle=i*math.tau/10
            radius=amount*rng.uniform(.94,1.05)
            vertices.append(Vector(at)+Vector((math.cos(angle)*size[0]*radius,
                math.sin(angle)*size[1]*radius+height*.025,size[2]*height)))
    faces=[tuple(reversed(range(10)))]
    for ring in range(3):
        for i in range(10):
            j=(i+1)%10
            faces.append((ring*10+i,ring*10+j,(ring+1)*10+j,(ring+1)*10+i))
    return mesh_object('Rumpled canvas',vertices,faces,material)

def contents():
    sack((-.05,0,.035),(.13,.09,.13),'cloth_dark',3)
    lump('Tied cloth',(-.05,0,.175),(.045,.04,.025),'cloth',3)
    for i in range(5):
        bpy.ops.mesh.primitive_cylinder_add(vertices=10,radius=.023,depth=.005,
            location=(.09+i*.015,-.08+i*.008,.05+i*.006))
        obj=bpy.context.object
        obj.name='Loose coin'
        obj.data.materials.append(geometry.MATERIALS['gold'])

def broken_lock():
    lump('Broken lock',(.35,-.07,.024),(.032,.021,.024),'rust',5)
    beam('Broken shackle',(.33,-.07,.04),(.35,-.07,.065),.008,.008,'iron',3)
    beam('Bent shackle',(.35,-.07,.065),(.39,-.07,.043),.008,.008,'iron',7)

def pack(spent):
    sack((0,0,.008),(.21,.145,.42),'canvas_dark',8)
    lump('Open pack mouth',(0,.025,.415),(.13,.085,.012),'split',2)
    if spent:
        flap=[(-.15,.08,.426),(.15,.08,.426),(-.13,.24,.45),(.14,.24,.43)]
    else:
        flap=[(-.15,.08,.431),(.15,.08,.431),(-.17,-.17,.31),(.17,-.17,.30)]
    obj=mesh_object('Folded flap',flap,[(0,2,3,1),(1,3,2,0)],'canvas')
    for side in [-1,1]:
        x=side*.11
        top=.24 if spent else .35
        beam('Front leather strap',(x,-.153,.04),(x+side*.025,-.16,top),.024,.015,'leather',side+4)
        box('Buckle',(x,-.168,.16),(.036,.012,.038),'iron')
        beam('Shoulder strap',(x,.12,.08),(x,.18,.36),.032,.018,'leather',side+8)
    battered_box('Patched pocket',(-.015,-.145,.16),(.19,.06,.15),'canvas',4)
    if not spent:
        lump('Tied blanket',(0,.01,.47),(.19,.075,.06),'blanket',6)
    else:
        beam('Loose strap tail',(.11,-.17,.05),(.31,-.25,.013),.025,.012,'leather',6)

def bedroll(spent,offset=(0,0,0)):
    obj=fitted_source('bed_floor.gltf.glb','bed_floor',(.44,.49,.13 if spent else .17),(0,0,0),'bed')
    obj.location=offset
    vertices=[]
    for row in range(5):
        for col in range(4):
            x=(col-1.5)*.18+.018*math.sin(row+col)
            y=(row-2)*.23
            z=(.11 if spent else .13)+(.026 if spent else .012)*math.sin(row*2+col*.8)
            vertices.append(Vector(offset)+Vector((x,y,z)))
    faces=[]
    for row in range(4):
        for col in range(3):
            i=row*4+col
            faces.append((i,i+1,i+5,i+4))
    mesh_object('Rumpled blanket',vertices,faces,'blanket')
    radius=.065 if spent else .095
    roll_at=Vector(offset)+Vector((.025 if spent else 0,.54,.13 if spent else .16))
    bpy.ops.mesh.primitive_cylinder_add(vertices=10,radius=radius,depth=.60,location=roll_at,
                                       rotation=(0,math.pi/2,0))
    bpy.context.object.name='Rolled blanket end'
    bpy.context.object.data.materials.append(geometry.MATERIALS['blanket'])
    for side in [-1,1]:
        bpy.ops.mesh.primitive_torus_add(major_radius=radius+.003,minor_radius=.007,
            major_segments=10,minor_segments=4,location=roll_at+Vector((side*.20,0,0)),
            rotation=(0,math.pi/2,0))
        bpy.context.object.name='Bedroll binding'
        bpy.context.object.data.materials.append(geometry.MATERIALS['leather'])

def fire_remains(at,spent):
    for i in range(8):
        angle=i*math.tau/8
        lump('Fire ring',Vector(at)+Vector((math.cos(angle)*.23,math.sin(angle)*.22,.035)),
             (.065,.05,.038),'stone_dark',i)
    lump('Ash bed',Vector(at)+Vector((0,0,.008)),(.20,.18,.008),'ash' if spent else 'split',4)
    for i in range(3):
        beam('Charred wood',Vector(at)+Vector((-.14,i*.06-.06,.02)),
            Vector(at)+Vector((.13,.07-i*.04,.027)),.035,.035,'split',i)
    if spent:
        for i in range(3):
            lump('Scattered ash',Vector(at)+Vector((.18+i*.06,-.17,.005)),(.045,.04,.005),'ash',i)

def rest_site(spent,camp):
    bedroll(spent,(-.30,0,0) if camp else (0,0,0))
    if camp:
        fire_remains((.45,-.22,0),spent)
        sack((.43,.38,.005),(.10,.08,.18),'leather',2)
        geometry.cup((.64,.12,.008),False)
    else:
        lump('Old ashes',(.38,-.45,.006),(.08 if spent else .045,.11,.006),'ash',3)

def workings(spent):
    for x in [-.48,.48]:
        beam('Short pit prop',(x,.18,0),(x,.21,.84),.11,.13,'wood_dark',int(x*10)+9)
    beam('Old header',(-.58,.20,.81),(.56,.20,.83),.15,.16,'wood',5)
    lump('Worked rock outcrop',(0,.26,.26),(.45,.18,.26),'stone_dark',8)
    for i in range(3):
        lump('Fractured rock',((i-1)*.23,.22,.15),(.18,.15,.15),'stone_dark',i+3)
    for side in [-1,1]:
        beam('Ore trough',(-.36,side*.20,.055),(.32,side*.20,.055),.08,.12,'wood_dark',side+5)
    for i in range(3):
        box('Trough bottom',((i-1)*.20,0,.035),(.18,.42,.05),'wood')
    beam('Pick handle',(.36,-.21,.025),(.46,.12,.60),.025,.03,'wood_light',7)
    beam('Worn pick head',(.33,.10,.60),(.59,.14,.57),.04,.035,'iron',9)
    for i in range(4):
        lump('Loose rubble',(-.5+i*.30,-.35,.025),(.08,.05,.025),'stone_dark',i)
    if not spent:
        for i in range(5):
            lump('Ore chunk',((i%3-1)*.16,(i//3-.5)*.15,.11),(.09,.08,.075),'ore',i)
            lump('Exposed mineral',((i%3-1)*.16,(i//3-.5)*.15-.02,.17),(.025,.025,.012),'ore_light',i)
    else:
        for x in [-.20,0,.20]: beam('Pick scrape',(x,-.14,.064),(x+.05,.12,.065),.009,.005,'split',5)

def rail_profile(x,broken):
    section=[(-.045,0),(.045,0),(.045,.012),(.012,.020),(.012,.065),(.030,.070),
             (.030,.090),(-.030,.090),(-.030,.070),(-.012,.065),(-.012,.020),(-.045,.012)]
    vertices=[]
    for station,y in enumerate([-1,-.35,.35,1]):
        bend=.12 if broken and station==3 else 0
        lift=.13 if broken and station==3 else 0
        for dx,z in section: vertices.append((x+dx+bend,y,z+.06+lift))
    faces=[tuple(reversed(range(12))),tuple(range(36,48))]
    for station in range(3):
        for i in range(12):
            j=(i+1)%12
            faces.append((station*12+i,station*12+j,(station+1)*12+j,(station+1)*12+i))
    obj=mesh_object('Bent rail' if broken else 'Iron rail',vertices,
                    [tuple(reversed(face)) for face in faces],'rust')
    obj.data.materials.append(geometry.MATERIALS['iron_edge'])
    for face in obj.data.polygons:
        if face.index>=2 and (face.index-2)%12 in [5,6,7]: face.material_index=1

def rails(broken):
    for i in range(5):
        if broken and i==3: continue
        y=(i-2)*.42
        beam('Split sleeper',(-.56,y,.035),(.56,y+.01,.035),.07,.16,'wood_dark',i+4)
        for side in [-1,1]: lump('Rail spike',(side*.37,y,.076),(.014,.014,.012),'iron',i)
    rail_profile(-.37,False)
    rail_profile(.37,broken)
    if broken:
        beam('Broken sleeper',(-.54,.42,.035),(.10,.47,.035),.07,.16,'wood',18)

for entry in json.loads((SOURCE/'provenance.json').read_text(encoding='utf-8'))['files']:
    assert hashlib.sha256((SOURCE/entry['file']).read_bytes()).hexdigest()==entry['sha256']
assets=[]
for name,build in [('chest-body',lambda:chest('body')),('chest-lid',lambda:chest('lid')),
                   ('strongbox-body',lambda:strongbox('body')),('strongbox-lid',lambda:strongbox('lid')),
                   ('contents',contents),('broken-lock',broken_lock),
                   ('pack-fresh',lambda:pack(False)),('pack-spent',lambda:pack(True)),
                   ('alcove-fresh',lambda:rest_site(False,False)),('alcove-spent',lambda:rest_site(True,False)),
                   ('camp-fresh',lambda:rest_site(False,True)),('camp-spent',lambda:rest_site(True,True)),
                   ('workings-fresh',lambda:workings(False)),('workings-spent',lambda:workings(True)),
                   ('rails',lambda:rails(False)),('rails-broken',lambda:rails(True))]:
    assets.append(geometry.export(name,build))
catalog={'issue':242,'assets':assets,'palette':geometry.COLOURS,
         'chest_hinge':CHEST_HINGE,'strongbox_hinge':[0,.30,-.22],
         'facing':'+Z','cell_metres':2,'lid_angle_degrees':-102}
(ART/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8')
print('EXPEDITION_MODELS',[(a['id'],a['triangles']) for a in assets])
