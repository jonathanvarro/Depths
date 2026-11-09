"""Build #243 mineral formations, roots and fungal growth on fixed mounts."""
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
ART=ROOT/'art/dressing/cave-growth-3d-v1'
geometry.ART=ART
geometry.MASTERS=args.workspace/'build/local-cave-growth-v1/masters'
ART.mkdir(parents=True,exist_ok=True)
geometry.MASTERS.mkdir(parents=True,exist_ok=True)
(geometry.MASTERS/'.gdignore').write_text('',encoding='utf-8')
for name,colour in {'mineral':'a29d84','mineral_dark':'807c69','root':'62503a',
                    'root_dark':'3d3629','fungus_cap':'828c69','fungus_edge':'b0aa86',
                    'fungus_under':'5f6852','mould':'626e4c'}.items():
    geometry.COLOURS[name]=colour
    material=bpy.data.materials.new(name)
    material.diffuse_color=(*(int(colour[i:i+2],16)/255 for i in (0,2,4)),1)
    geometry.MATERIALS[name]=material

def tube(name, points, radii, sides, materials, seed=0, cap_end=True, smooth=False):
    """A tapered faceted tube with stable, slightly irregular cross-sections."""
    rng=random.Random(seed)
    points=[Vector(point) for point in points]
    if smooth:
        curved=[]
        widths=[]
        for segment in range(len(points)-1):
            a=points[max(0,segment-1)]
            b=points[segment]
            c=points[segment+1]
            d=points[min(len(points)-1,segment+2)]
            for sample in range(3):
                t=sample/3
                curved.append(.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t))
                widths.append(radii[segment]*(1-t)+radii[segment+1]*t)
        points=curved+[points[-1]]
        radii=widths+[radii[-1]]
    cross=[rng.uniform(.88,1.08) for _ in range(sides)]
    vertices=[]
    first_tangent=(points[1]-points[0]).normalized()
    reference=Vector((1,0,0)) if abs(first_tangent.y)>.9 else Vector((0,1,0))
    axis=first_tangent.cross(reference).normalized()
    for ring,(point,radius) in enumerate(zip(points,radii)):
        before=points[max(0,ring-1)]
        after=points[min(len(points)-1,ring+1)]
        tangent=(after-before).normalized()
        # Transport the cross-section along the curve without roll flips near -Z.
        axis-=tangent*axis.dot(tangent)
        if axis.length_squared<.000001:
            reference=Vector((1,0,0)) if abs(tangent.y)>.9 else Vector((0,1,0))
            axis=tangent.cross(reference)
        axis.normalize()
        second=tangent.cross(axis)
        for side in range(sides):
            angle=side*math.tau/sides+.10*math.sin(ring+seed)
            direction=(axis*math.cos(angle)+second*math.sin(angle))*radius*cross[side]
            vertices.append(point+direction)
    faces=[tuple(reversed(range(sides)))]
    for ring in range(len(points)-1):
        for side in range(sides):
            next_side=(side+1)%sides
            faces.append((ring*sides+side,ring*sides+next_side,(ring+1)*sides+next_side,(ring+1)*sides+side))
    if cap_end: faces.append(tuple(range((len(points)-1)*sides,len(points)*sides)))
    obj=geometry.mesh_object(name,vertices,faces,materials[0])
    for material in materials[1:]: obj.data.materials.append(geometry.MATERIALS[material])
    for face in obj.data.polygons:
        face.material_index=rng.randrange(len(materials))
    return obj

def mineral(at,height,radius,seed,broken=False,down=False):
    rng=random.Random(seed)
    offsets=[(0,0,0),(.018,-.006,.16),(-.012,.014,.48),(.019,.006,.78),(.025,-.008,1)]
    widths=[radius,radius*.9,radius*.58,radius*.28,.006 if down else .014]
    if broken:
        offsets=offsets[:3]+[(.006,.004,.62)]
        widths=widths[:3]+[radius*.47]
    points=[]
    for x,y,z in offsets:
        points.append(Vector(at)+Vector((x+rng.uniform(-.008,.008),y+rng.uniform(-.008,.008),z*height*(-1 if down else 1))))
    obj=tube('Broken mineral' if broken else 'Mineral growth',points,widths,9,
             ['stone','stone_light','mineral_dark'],seed)
    for vertex in obj.data.vertices[:9]: vertex.co.z=at[2]
    if broken:
        obj.data.materials.append(geometry.MATERIALS['mineral'])
        obj.data.polygons[-1].material_index=3

def formation(kind):
    if kind=='stalagmite-stub': mineral((0,0,0),.34,.13,2)
    elif kind=='stalagmite-tall': mineral((0,0,0),.95,.16,7)
    elif kind=='stalagmite-broken': mineral((0,0,0),.72,.19,12,True)
    elif kind=='stalagmite-cluster':
        for at,height,radius,seed in [((-.16,.03,0),.68,.13,8),((.13,-.06,0),.42,.11,12),((.03,.15,0),.27,.09,15)]:
            mineral(at,height,radius,seed)
    elif kind=='stalactite-single': mineral((0,0,0),.55,.13,19,down=True)
    elif kind=='stalactite-cluster':
        for at,height,radius,seed in [((-.17,0,0),.65,.13,8),((.12,.05,0),.43,.11,3),((.02,-.15,0),.26,.08,15)]:
            mineral(at,height,radius,seed,down=True)

def flowstone():
    # Blender -Y faces the room. A single connected sheet has vertical mineral ribs.
    vertices=[]
    for row in range(7):
        for col in range(9):
            amount=row/6
            width=.50+.45*math.sin(amount*math.pi*.75)
            x=(col-4)*.09*width+.012*math.sin(row*2+col)
            bottom=-.54+.15*abs(math.sin(col*1.2+.4))
            top=.51+.035*math.cos(col*1.8)
            z=bottom*(1-amount)+top*amount
            depth=.035+.075*(.5+.5*math.cos(col*2.1))+.018*math.sin(row*.8+col)
            vertices.append((x,-max(.018,depth),z))
    faces=[]
    for row in range(6):
        for col in range(8):
            i=row*9+col
            faces.append((i,i+1,i+10,i+9))
    boundary=list(range(9))+[row*9+8 for row in range(1,7)]+list(range(61,53,-1))+[row*9 for row in range(5,0,-1)]
    first_back=len(vertices)
    vertices.extend((vertices[i][0],.003,vertices[i][2]) for i in boundary)
    for i in range(len(boundary)):
        j=(i+1)%len(boundary)
        faces.append((boundary[j],boundary[i],first_back+i,first_back+j))
    faces.append(tuple(reversed(range(first_back,len(vertices)))))
    obj=geometry.mesh_object('Ribbed flowstone',vertices,faces,'stone_light')
    obj.data.materials.append(geometry.MATERIALS['mineral_dark'])
    for face in obj.data.polygons: face.material_index=1 if face.index%8 in [2,5] else 0

RUBBLE=ROOT/'art/third-party/kaykit-dungeon-remastered/models/rubble_half.glb'

def rubble():
    bpy.ops.import_scene.gltf(filepath=str(RUBBLE),import_pack_images=True)
    objects=[o for o in bpy.context.selected_objects if o.type=='MESH']
    assert len(objects)==1
    obj=objects[0]
    coordinates=[obj.matrix_world@v.co for v in obj.data.vertices]
    low=Vector(tuple(min(p[i] for p in coordinates) for i in range(3)))
    high=Vector(tuple(max(p[i] for p in coordinates) for i in range(3)))
    scale=.72/(high.x-low.x)
    centre=Vector(((low.x+high.x)/2,(low.y+high.y)/2,low.z))
    obj.matrix_world.identity()
    for vertex,point in zip(obj.data.vertices,coordinates): vertex.co=(point-centre)*scale
    obj.data.materials.clear()
    for material in ['stone_dark','stone','stone_light']: obj.data.materials.append(geometry.MATERIALS[material])
    for face in obj.data.polygons: face.material_index=(face.index//5)%3

def roots(kind):
    paths={
        'wall-roots':[
            [(-.35,0,.54),(-.31,-.055,.33),(-.14,-.075,.06),(-.26,-.04,-.47)],
            [(.06,.01,.55),(.02,-.02,.27),(.14,-.06,-.11),(.43,-.04,-.44)],
            [(.42,0,.46),(.27,-.02,.31),(.05,-.10,.03),(-.08,-.07,-.39)],
            [(.02,-.02,.27),(-.14,-.04,.06),(-.34,-.05,-.13),(-.47,-.02,-.38)],
        ],
        'hanging-roots':[
            [(-.30,0,0),(-.24,-.03,-.14),(-.32,-.07,-.31),(-.16,-.05,-.56)],
            [(-.05,0,0),(-.09,-.02,-.11),(.02,-.04,-.25),(.03,-.06,-.38)],
            [(.18,0,0),(.25,-.02,-.18),(.14,-.08,-.40),(.28,-.04,-.62)],
            [(.37,0,0),(.30,-.06,-.13),(.40,-.08,-.25),(.43,-.04,-.44)],
        ],
        'floor-roots':[
            [(-.45,-.14,.04),(-.20,-.17,.05),(.10,-.08,.03),(.42,-.22,.018)],
            [(-.44,.14,.045),(-.15,.09,.06),(.12,.16,.035),(.38,.06,.018)],
            [(-.06,-.37,.04),(.04,-.16,.045),(-.05,.12,.035),(.10,.34,.018)],
            [(-.25,.32,.045),(-.09,.11,.055),(.18,-.09,.035),(.41,.04,.018)],
        ],
    }
    for index,points in enumerate(paths[kind]):
        rng=random.Random(index+60)
        if kind=='wall-roots':
            radii=[.050,.037,.024,.005] if index<3 else [.026,.021,.011,.003]
        elif kind=='hanging-roots':
            radii=[.035,.027,.014,.003]
        else:
            radii=[.045,.031,.019,.004]
        points=[(px+rng.uniform(-.025,.025),py+rng.uniform(-.012,.012),pz) for px,py,pz in points]
        tube('Gnarled root',points,radii,7,['root','root_dark'],index+5,smooth=True)
        branch=Vector(points[2])
        if kind=='floor-roots':
            twig=[branch,branch+Vector((.03,.10,.0)),branch+Vector((.12,.19,-.01))]
        else:
            twig=[branch,branch+Vector((.11,-.02,-.08)),branch+Vector((.21,-.03,-.17))]
        tube('Root fork',twig,[radii[2]*.75,.012,.002],6,['root_dark','root'],index+17,smooth=True)

def mushroom(at,height,radius,seed):
    at=Vector(at)
    top=at+Vector((.025,-.01,height))
    tube('Crooked fungal stem',[at,at+Vector((-.014,.008,height*.5)),top],
         [.023,.018,.013],7,['fungus_under','mineral_dark'],seed)
    vertices=[]
    # Underside rim, uneven cap edge, crown and top centre.
    for ring,(r,z) in enumerate([(radius*.75,-radius*.15),(radius,0),(radius*.68,radius*.38),(.006,radius*.60)]):
        for side in range(11):
            angle=side*math.tau/11
            variation=1+.09*math.sin(angle*3+seed)
            vertices.append(top+Vector((math.cos(angle)*r*variation,math.sin(angle)*r,
                                        z+.009*math.sin(angle*2+seed))))
    faces=[tuple(reversed(range(11)))]
    for ring in range(3):
        for i in range(11):
            j=(i+1)%11
            faces.append((ring*11+i,ring*11+j,(ring+1)*11+j,(ring+1)*11+i))
    faces.append(tuple(range(33,44)))
    obj=geometry.mesh_object('Uneven fungal cap',vertices,faces,'fungus_cap')
    obj.data.materials.append(geometry.MATERIALS['fungus_under'])
    obj.data.materials.append(geometry.MATERIALS['fungus_edge'])
    obj.data.polygons[0].material_index=1
    for face in obj.data.polygons[1:12]: face.material_index=2

def mushrooms():
    for at,height,radius,seed in [((-.12,.01,0),.23,.12,4),((.13,.06,0),.14,.10,9),((.04,-.14,0),.10,.075,2)]:
        mushroom(at,height,radius,seed)

def shelf():
    for index,(x,z,radius) in enumerate([(-.16,-.10,.20),(.14,.10,.17),(-.06,.25,.12)]):
        vertices=[]
        for height,scale in [(0,1),(.025,1.02),(.065,.50)]:
            for i in range(10):
                angle=i*math.pi/9
                vertices.append((x+math.cos(angle)*radius*scale,-.005-math.sin(angle)*radius*scale,z+height+.007*math.sin(i+index)))
        faces=[tuple(reversed(range(10)))]
        for ring in range(2):
            for i in range(9): faces.append((ring*10+i,ring*10+i+1,(ring+1)*10+i+1,(ring+1)*10+i))
        faces.append(tuple(range(20,30)))
        faces.append((0,10,20,29,19,9))
        obj=geometry.mesh_object('Layered shelf fungus',vertices,
                                 [tuple(reversed(face)) for face in faces],'fungus_cap')
        obj.data.materials.append(geometry.MATERIALS['fungus_under'])
        obj.data.polygons[0].material_index=1

def fungal_mat():
    for i in range(8):
        x=(i%3-1)*.15
        y=(i//3-1)*.13
        obj=geometry.lump('Low fungal growth',(x,y,.025),(.09,.08,.025),'mould',i)
    for i in range(3): mushroom(((i-1)*.13,.02,0),.045,.045,i+5)

MOUNTS={
    'stalagmite-stub':'floor','stalagmite-tall':'floor','stalagmite-broken':'floor','stalagmite-cluster':'floor',
    'stalactite-single':'ceiling','stalactite-cluster':'ceiling','flowstone-wall':'wall','rubble-cluster':'floor',
    'wall-roots':'wall','hanging-roots':'ceiling','floor-roots':'floor',
    'mushroom-clump':'floor','shelf-fungus':'wall','fungal-mat':'floor',
}
assets=[]
for name in MOUNTS:
    if name.startswith(('stalagmite','stalactite')): build=lambda name=name:formation(name)
    elif name=='flowstone-wall': build=flowstone
    elif name=='rubble-cluster': build=rubble
    elif name in ['wall-roots','hanging-roots','floor-roots']: build=lambda name=name:roots(name)
    elif name=='mushroom-clump': build=mushrooms
    elif name=='shelf-fungus': build=shelf
    else: build=fungal_mat
    entry=geometry.export(name,build,material_groups={'fungus_cap':'Caps'})
    entry['mount']=MOUNTS[name]
    entry['optional_glow']=name in ['mushroom-clump','shelf-fungus','fungal-mat']
    assets.append(entry)
source={'file':'art/third-party/kaykit-dungeon-remastered/models/rubble_half.glb',
        'sha256':hashlib.sha256(RUBBLE.read_bytes()).hexdigest(),
        'licence':'art/third-party/kaykit-dungeon-remastered/LICENSE.txt'}
assert source['sha256']=='7514ccbda643c13d5a782579e4f01ee6402eec5519590d3f048d396cdaedec24'
(ART/'catalog.json').write_text(json.dumps({'issue':243,'assets':assets,'palette':geometry.COLOURS,
    'sources':[source],'cell_metres':2,'wall_metres':2.4,'wall_facing':'+Z',
    'builder_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
    'helpers_sha256':hashlib.sha256(Path(geometry.__file__).read_bytes()).hexdigest()},indent=2)+'\n',encoding='utf-8')
print('CAVE_GROWTH',[(a['id'],a['triangles']) for a in assets])
