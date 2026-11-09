"""Build the #241 mine props from CC0 lantern/candle meshes and fitted framing.

Run with Blender --background --factory-startup --disable-autoexec
--python-exit-code 1 --python tools/mine_props/build_models.py -- --workspace PATH.
"""
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
SOURCE = ROOT / 'art/third-party/kaykit-mine-props-v1'
ART = ROOT / 'art/dressing/mine-3d-v1'
MASTERS = None

COLOURS = {
    'wood': '59432e', 'wood_light': '73583b', 'wood_dark': '352a20',
    'split': '241f19', 'iron': '383d3c', 'iron_edge': '555b57',
    'rust': '754b35', 'stone': '606158', 'stone_light': '77786b',
    'stone_dark': '42473f', 'wax': 'b9a87a', 'wick': '24221b',
    'cloth': '465b5c', 'cloth_dark': '2e4143', 'ore': '444b49',
    'ash': '777366', 'copper': '866040', 'glass': 'ca8f42',
}
MATERIALS = {}
for name, colour in COLOURS.items():
    material = bpy.data.materials.new(name)
    rgb = tuple(int(colour[i:i+2], 16)/255 for i in (0,2,4))
    material.diffuse_color = (*rgb, 1)
    MATERIALS[name] = material

def mesh_object(name, vertices, faces, material):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(MATERIALS[material])
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return obj

def beam(name, start, end, width, depth, material='wood', seed=0):
    """An irregular, chamfered timber with a slightly bowed middle section."""
    rng = random.Random(seed)
    start, end = Vector(start), Vector(end)
    direction = end-start
    rotation = Vector((0,0,1)).rotation_difference(direction.normalized())
    cross = [(-.36,-.5),(.35,-.5),(.5,-.32),(.5,.34),
             (.34,.5),(-.36,.5),(-.5,.31),(-.5,-.34)]
    vertices = []
    for ring, amount in enumerate([0,.48,1]):
        sway = Vector((rng.uniform(-.012,.012), rng.uniform(-.009,.009),0))
        for x,y in cross:
            point = Vector((x*width, y*depth, direction.length*amount))
            point.x += rng.uniform(-.009,.009)
            point.y += rng.uniform(-.007,.007)
            vertices.append(start + rotation @ (point+sway))
    faces = [tuple(reversed(range(8))), tuple(range(16,24))]
    for ring in range(2):
        for side in range(8):
            next_side=(side+1)%8
            faces.append((ring*8+side,ring*8+next_side,(ring+1)*8+next_side,(ring+1)*8+side))
    return mesh_object(name,vertices,faces,material)

def box(name, at, size, material, rotation=(0,0,0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=at, rotation=rotation)
    obj=bpy.context.object
    obj.name=name
    obj.scale=size
    obj.data.materials.append(MATERIALS[material])
    return obj

def lump(name, at, size, material, seed=0):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=at)
    obj=bpy.context.object
    obj.name=name
    obj.scale=size
    rng=random.Random(seed)
    for vertex in obj.data.vertices:
        vertex.co *= rng.uniform(.92,1.05)
    obj.data.materials.append(MATERIALS[material])
    return obj

def stone(at, size, material, seed):
    obj=box('Rough masonry',at,size,material)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    bevel=obj.modifiers.new('Chipped corners','BEVEL')
    bevel.width=.025
    bevel.segments=1
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    rng=random.Random(seed)
    for vertex in obj.data.vertices:
        vertex.co += Vector(tuple(rng.uniform(-.009,.009) for _ in range(3)))

def cup(at, filled):
    vertices=[]
    for radius,height in [(.045,0),(.071,.055),(.055,.055),(.034,.014)]:
        for i in range(10):
            angle=i*math.tau/10
            vertices.append(Vector(at)+Vector((radius*math.cos(angle),radius*math.sin(angle),height)))
    faces=[]
    for ring in range(3):
        for i in range(10):
            j=(i+1)%10
            faces.append((ring*10+i,ring*10+j,(ring+1)*10+j,(ring+1)*10+i))
    faces.append(tuple(range(30,40)))
    mesh_object('Offering cup',vertices,faces,'copper')
    if filled:
        for i in range(3):
            lump('Ore offering',Vector(at)+Vector(((i-1)*.025,0,.043)),(.018,.023,.014),'ore',i)

def source_mesh(name, at, scale, kind):
    """Read only sibling glTF dependencies and replace colours with our palette."""
    path=SOURCE/'halloween'/(name+'.gltf')
    source=json.loads(path.read_text(encoding='utf-8'))
    for item in source.get('buffers',[])+source.get('images',[]):
        uri=item.get('uri','')
        assert '/' not in uri and '\\' not in uri and ':' not in uri
    bpy.ops.import_scene.gltf(filepath=str(path),import_pack_images=True)
    objects=[o for o in bpy.context.selected_objects if o.type=='MESH']
    assert len(objects)==1
    obj=objects[0]
    coordinates=[obj.matrix_world@v.co for v in obj.data.vertices]
    bottom=min(v.z for v in coordinates)
    centre=Vector(((min(v.x for v in coordinates)+max(v.x for v in coordinates))/2,
                   (min(v.y for v in coordinates)+max(v.y for v in coordinates))/2,bottom))
    image=next(n.image for n in obj.data.materials[0].node_tree.nodes if n.type=='TEX_IMAGE')
    pixels=list(image.pixels)
    colours=[]
    for face in obj.data.polygons:
        uv=obj.data.uv_layers.active.data[face.loop_indices[0]].uv
        x=min(image.size[0]-1,max(0,int(uv.x*image.size[0])))
        y=min(image.size[1]-1,max(0,int(uv.y*image.size[1])))
        rgb=pixels[(y*image.size[0]+x)*4:(y*image.size[0]+x)*4+3]
        if kind=='lantern':
            material='glass' if rgb[0]>.7 and rgb[0]>rgb[2]*1.4 else 'iron'
            if material=='iron' and face.index%17==0:
                material='rust'
        else:
            material='wick' if max(rgb)<.15 else 'wax'
        colours.append(material)
    obj.data.materials.clear()
    names=list(dict.fromkeys(colours))
    for material in names:
        obj.data.materials.append(MATERIALS[material])
    for face,material in zip(obj.data.polygons,colours):
        face.material_index=names.index(material)
    for vertex,point in zip(obj.data.vertices,coordinates):
        local=point-centre
        if kind=='lantern':
            local.x += .006*math.sin(local.z*5.7+local.y*7)*math.sin(local.z*3.1)
        vertex.co=Vector(at)+Vector(tuple(local[i]*scale[i] for i in range(3)))
    obj.matrix_world.identity()
    obj.name=name

def support(damaged):
    for side in [-1,1]:
        x=side*.925
        beam('Upright', (x,0,0),(x+side*.012,.006,2.30),.21,.24,seed=side+4)
        for height in [.24,1.90]:
            box('Iron strap',(x,-.006,height),(.228,.252,.045),'rust' if side<0 else 'iron')
        for height in [.27,1.87]:
            lump('Square nail',(x,-.138,height),(.018,.009,.018),'iron_edge',side+3)
        beam('Corner brace',(side*.84,0,1.94),(side*.50,0,2.23),.105,.12,seed=side+7)
        mesh_object('Open grain split',[(x-.035,-.128,.5),(x-.025,-.130,1.15),
                     (x-.018,-.13,.85),(x-.022,-.131,.53)],[(0,1,2,3)],'split')
    beam('Header',(-1.055,0,2.27),(1.055,.008,2.26),.25,.29,'wood_light',13)
    if damaged:
        beam('Repair plank',(-1.01,-.15,.65),(-.89,-.15,1.62),.075,.045,'wood_light',17)
        mesh_object('Header split',[(-.31,-.15,2.23),(.22,-.15,2.21),(.08,-.151,2.24),
                    (.35,-.151,2.255),(-.30,-.151,2.25)],[(0,1,2,3,4)],'split')
        for i in range(3):
            lump('Split timber foot',(-.93+i*.035,-.07,.03),(.05,.06,.03),'wood_dark',i)

def lantern(hanging):
    factor=.38
    if hanging:
        source_mesh('lantern_hanging',(0,-.245,-1.408575892*factor),(factor,)*3,'lantern')
        beam('Wall bracket',(0,-.015,-.025),(0,-.25,-.025),.034,.034,'iron',22)
        box('Wall plate',(0,-.014,-.08),(.07,.028,.17),'iron')
        for z in [-.025,-.14]:
            lump('Mount rivet',(0,-.035,z),(.011,.009,.011),'rust',3)
    else:
        source_mesh('lantern_standing',(0,0,0),(factor,)*3,'lantern')

def miner():
    # A small, stooped wooden carving of a working miner, with a proper head ratio.
    for side in [-1,1]:
        x=side*.052
        beam('Carved leg',(x,-.16,.66),(x,-.175,.82),.065,.075,'wood_dark',side+8)
        lump('Carved boot',(x,-.19,.665),(.045,.07,.028),'wood_dark',side+8)
    beam('Carved body',(0,-.16,.79),(0,-.19,1.00),.19,.13,'wood',9)
    lump('Carved head',(0,-.20,1.052),(.046,.041,.055),'wood_light',9)
    lump('Miner cap',(0,-.196,1.097),(.060,.052,.023),'wood_dark',5)
    box('Cap brim',(0,-.236,1.09),(.116,.037,.014),'wood_dark',(.05,0,.025))
    lump('Carved nose',(0,-.244,1.05),(.013,.018,.020),'wood_light',1)
    for side in [-1,1]:
        beam('Carved sleeve',(side*.09,-.18,.98),(side*.11,-.245,.88),.057,.065,'wood',side+3)
        beam('Carved forearm',(side*.11,-.245,.88),(side*.065,-.28,.90),.046,.05,'wood_light',side+6)
    beam('Pick handle',(-.14,-.29,.78),(.14,-.29,1.09),.018,.021,'wood_light',12)
    mesh_object('Carved iron pick',[(.02,-.307,1.12),(.16,-.307,1.14),(.30,-.307,1.04),
                (.17,-.307,1.10),(.04,-.307,1.09),(.02,-.284,1.12),(.16,-.284,1.14),
                (.30,-.284,1.04),(.17,-.284,1.10),(.04,-.284,1.09)],
                [(0,1,2,3,4),(9,8,7,6,5),(0,5,6,1),(1,6,7,2),(2,7,8,3),(3,8,9,4),(4,9,5,0)],'iron')

def shrine_base():
    box('Dark niche back',(0,-.035,.98),(.72,.07,.92),'stone_dark')
    for side in [-1,1]:
        for i in range(4):
            stone((side*.45,-.13,.57+i*.23),(.24,.30,.24),
                  'stone_light' if i%3==0 else 'stone',i+side+8)
    beam('Timber lintel',(-.55,-.13,1.48),(.54,-.125,1.46),.17,.25,'wood_dark',19)
    box('Stone shelf',(0,-.205,.605),(1.02,.41,.12),'stone',(.008,.015,-.018))
    for i in range(3):
        stone(((i-1)*.30,-.10,.20),(.31,.30,.40),'stone_dark',i+2)
    miner()

CANDLES=[(-.29,-.43,.0,.16),(-.14,-.40,.0,.11),(.29,-.41,.0,.19)]

def offerings(spent):
    for i,(x,y,z,height) in enumerate(CANDLES):
        candle_height=.045+i*.008 if spent else height
        source_name='candle_melted' if spent else 'candle'
        original_height=.631385505 if spent else .785683811
        source_mesh(source_name,(x,y,z),(.12,.12,candle_height/original_height),'candle')
    cup((.09,-.43,.005),not spent)
    if not spent:
        mesh_object('Draped blue cloth',[(-.19,-.25,.671),(.18,-.25,.671),(-.20,-.43,.665),
                    (.17,-.43,.666),(-.17,-.455,.43),(.15,-.46,.45),(-.01,-.47,.42)],
                    [(2,3,1,0),(4,6,5,3,2)],'cloth')
        for i in range(2):
            lump('Mineral offering',(-.31+i*.11,-.25,.69),(.04,.03,.025),'ore',i)
    else:
        for i in range(3):
            lump('Candle ash',(-.26+i*.11,-.43,.006),(.04,.03,.006),'ash',i)

def export(name, build):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    build()
    bpy.context.view_layer.update()
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
    # Editable masters retain individual pieces and their material names.
    bpy.ops.wm.save_as_mainfile(filepath=str(MASTERS/(name+'.blend')))
    grouped={'Body':([],[]), 'Glass':([],[])}
    for obj in objects:
        vertices=[obj.matrix_world@v.co for v in obj.data.vertices]
        for polygon in obj.data.polygons:
            colour=obj.data.materials[polygon.material_index].name
            group='Glass' if colour=='glass' else 'Body'
            destination,faces=grouped[group]
            first=len(destination)
            destination.extend(vertices[i] for i in polygon.vertices)
            faces.append((tuple(range(first,first+len(polygon.vertices))),colour))
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    triangles=0
    points=[]
    for group,(vertices,faces) in grouped.items():
        if not faces:
            continue
        mesh=bpy.data.meshes.new(group)
        mesh.from_pydata(vertices,[],[f[0] for f in faces])
        uv=mesh.uv_layers.new(name='Palette')
        for polygon,(_,colour) in zip(mesh.polygons,faces):
            index=list(COLOURS).index(colour)
            coordinate=((index%8+.5)/8,(index//8+.5)/4)
            for loop in polygon.loop_indices:
                uv.data[loop].uv=coordinate
        mesh.update()
        obj=bpy.data.objects.new(group,mesh)
        bpy.context.collection.objects.link(obj)
        obj.select_set(True)
        mesh.calc_loop_triangles()
        triangles+=len(mesh.loop_triangles)
        points.extend(vertices)
    path=ART/(name+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,
        export_materials='NONE',export_texcoords=True,export_animations=False,
        export_cameras=False,export_lights=False)
    low=[min(p[i] for p in points) for i in range(3)]
    high=[max(p[i] for p in points) for i in range(3)]
    return {'id':name,'triangles':triangles,'min':low,'max':high,
            'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--workspace', type=Path, required=True)
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
    MASTERS = args.workspace / 'build/local-mine-props-v1/masters'
    ART.mkdir(parents=True, exist_ok=True)
    MASTERS.mkdir(parents=True, exist_ok=True)
    (MASTERS/'.gdignore').write_text('', encoding='utf-8')
    assets=[]
    for name,build in [('support',lambda:support(False)),('support-damaged',lambda:support(True)),
                       ('lantern-standing',lambda:lantern(False)),('lantern-hanging',lambda:lantern(True)),
                       ('shrine-base',shrine_base),('offerings-fresh',lambda:offerings(False)),
                       ('offerings-spent',lambda:offerings(True))]:
        assets.append(export(name,build))
    for entry in json.loads((SOURCE/'provenance.json').read_text(encoding='utf-8'))['files']:
        assert hashlib.sha256((SOURCE/entry['file']).read_bytes()).hexdigest()==entry['sha256']
    (ART/'catalog.json').write_text(json.dumps({'issue':241,'assets':assets,
        'palette':COLOURS,'candle_flames':[[x,z+height,-y] for x,y,z,height in CANDLES],
        'support_clearance':{'width':1.60,'height':1.85},
        'wall_facing':'+Z','cell_metres':2.0,'wall_metres':2.4},indent=2)+'\n',encoding='utf-8')
    print('MINE_PROPS',[(a['id'],a['triangles']) for a in assets])
