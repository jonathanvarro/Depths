"""#278/#279: refined mine geometry and CC0-derived tiered loot chests.

Blender --background --factory-startup --disable-autoexec --python-exit-code 1
--python tools/mine_polish/build_models.py -- --workspace E:/GitHub/Depths
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
from mathutils.bvhtree import BVHTree

ROOT=Path(__file__).resolve().parents[2]
sys.dont_write_bytecode=True
spec=importlib.util.spec_from_file_location('depths_mine_geometry',ROOT/'tools/mine_props/build_models.py')
G=importlib.util.module_from_spec(spec)
spec.loader.exec_module(G)
parser=argparse.ArgumentParser()
parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:]) if __name__=='__main__' else argparse.Namespace(workspace=ROOT)
preview_types={item.identifier for item in bpy.context.preferences.filepaths.bl_rna.properties['file_preview_type'].enum_items}
if 'NONE' in preview_types:bpy.context.preferences.filepaths.file_preview_type='NONE'
MINE=ROOT/'art/dressing/mine-refined-v2'
CHESTS=ROOT/'art/props/loot-chests-v2'
MASTERS=args.workspace/'build/local-mine-polish-v2/masters'
for path in [MINE,CHESTS,MASTERS]:path.mkdir(parents=True,exist_ok=True)
(MASTERS/'.gdignore').write_text('')
for key,colour in {'wood_grey':'635b4a','wood_end':'7b6548','silver':'858e8c',
 'silver_dark':'535d5b','silver_edge':'a7afaa','gold':'ab8241','gold_edge':'d0a95f',
 'gold_dark':'77582c','cloth_worn':'455452','leather':'453225','soot':'1b1c19'}.items():
    G.COLOURS[key]=colour
    material=bpy.data.materials.new(key)
    material.diffuse_color=(*(int(colour[i:i+2],16)/255 for i in (0,2,4)),1)
    G.MATERIALS[key]=material
original_box=G.box
original_beam=G.beam
original_lump=G.lump
original_source=G.source_mesh
original_miner=G.miner

def bevel(obj,width=.008,segments=1):
    bpy.context.view_layer.objects.active=obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    mod=obj.modifiers.new('Uneven worn arris','BEVEL')
    mod.width=width;mod.segments=segments
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj

def box(name,at,size,material,rotation=(0,0,0)):
    obj=original_box(name,at,size,material,rotation)
    if min(size)>.012:bevel(obj,min(.009,min(size)*.17))
    return obj

def beam(name,start,end,width,depth,material='wood',seed=0):
    rng=random.Random(seed)
    start,end=Vector(start),Vector(end)
    direction=end-start
    rotation=Vector((0,0,1)).rotation_difference(direction.normalized())
    cross=[(-.34,-.5),(.34,-.5),(.5,-.31),(.5,.32),(.32,.5),(-.35,.5),(-.5,.30),(-.5,-.32)]
    vertices=[]
    for row,t in enumerate([0,.18,.48,.78,1]):
        sway=Vector((math.sin(t*math.pi)*rng.uniform(-.013,.013),math.sin(t*math.pi)*rng.uniform(-.009,.009),0))
        for x,y in cross:
            chip=rng.uniform(.91,1.04)
            p=Vector((x*width*chip,y*depth*chip,direction.length*t))+sway
            vertices.append(start+rotation@p)
    faces=[tuple(reversed(range(8))),tuple(range(32,40))]
    for row in range(4):
        for i in range(8):faces.append((row*8+i,row*8+(i+1)%8,(row+1)*8+(i+1)%8,(row+1)*8+i))
    obj=G.mesh_object(name,vertices,faces,material)
    obj['grain_origin']=list(start);obj['grain_axis']=list(direction.normalized())
    return obj

def lump(name,at,size,material,seed=0):
    obj=original_lump(name,at,size,material,seed)
    if material.startswith('stone') or name.startswith(('Fractured','Worked','Ore chunk')):
        # Fractured secondary faces, not an evenly inflated low-poly ball.
        bevel(obj,min(size)*.14)
    return obj

def source_mesh(*arguments):
    original_source(*arguments)
    obj=bpy.context.view_layer.objects.active
    # The source mesh is the only selected mesh after its import.
    objects=[o for o in bpy.context.selected_objects if o.type=='MESH']
    if objects:bevel(objects[0],.0022)

G.box=box;G.beam=beam;G.lump=lump;G.source_mesh=source_mesh

def rod(name,points,radius,material='iron',sides=6):
    points=[Vector(p) for p in points]
    vertices=[]
    for index,p in enumerate(points):
        axis=(points[min(index+1,len(points)-1)]-points[max(index-1,0)]).normalized()
        a=axis.cross(Vector((0,1,0)) if abs(axis.y)<.9 else Vector((1,0,0))).normalized()
        b=axis.cross(a)
        for j in range(sides):vertices.append(p+radius*(math.cos(j*math.tau/sides)*a+math.sin(j*math.tau/sides)*b))
    faces=[tuple(reversed(range(sides))),tuple(range((len(points)-1)*sides,len(points)*sides))]
    for row in range(len(points)-1):
        for i in range(sides):faces.append((row*sides+i,row*sides+(i+1)%sides,(row+1)*sides+(i+1)%sides,(row+1)*sides+i))
    return G.mesh_object(name,vertices,faces,material)

def ring(name,at,radius,material='iron',rotation=(math.pi/2,0,0),wire=.008):
    bpy.ops.mesh.primitive_torus_add(major_radius=radius,minor_radius=wire,major_segments=16,minor_segments=4,location=at,rotation=rotation)
    obj=bpy.context.object;obj.name=name;obj.data.materials.append(G.MATERIALS[material])
    return obj

def nail(at,material='iron_edge',size=.012):
    return box('Hammered square nail',at,(size*1.4,.007,size*1.2),material,(0,.12,.11))

def timber_split(x,y,z,length=.6,width=.008):
    G.mesh_object('Recessed split',[(x-width,y,z),(x+.003,y-.001,z+length*.43),(x+width*.35,y,z+length),
       (x+width*.8,y-.001,z+length*.61),(x+width,y,z+.03)],[(0,1,2,3,4)],'split')

def support(damaged):
    G.support(damaged)
    for side in [-1,1]:
        x=side*.925
        # Broad notched bearing blocks and a second, crooked brace convey load.
        beam('Splayed foot', (x-side*.018,.012,.015),(x,.008,.18),.255,.29,'wood_dark',42+side)
        beam('Header bearing pad',(x,-.014,2.12),(x,-.014,2.28),.255,.285,'wood_dark',51+side)
        for i in range(3):timber_split(x+(.022*i-.033),-.126,.38+i*.34,.42+i*.05,.004)
        beam('Old packing shim',(x-side*.10,-.015,2.16),(x+side*.10,-.015,2.17),.018,.25,'wood_end',65+side)
        for h in [.24,1.91]:
            for dx in [-.064,.061]:nail((x+dx,-.14,h),size=.014)
        # Axe hewing marks reveal the grain rather than a stone-pattern overlay.
        for i in range(4):
            z=.55+i*.29
            rod('Shallow hewing scar',[(x-.06,-.132,z),(x-.015,-.137,z+.015),(x+.052,-.132,z+.008)],.0026,'wood_dark',3)
    if damaged:
        beam('Crooked iron repair splint',(-1.005,-.178,.69),(-.91,-.178,1.48),.027,.017,'iron',83)
        for z in [.78,1.37]:nail((-.96,-.193,z),'rust',.02)

def lantern(hanging):
    G.lantern(hanging)
    y=-.245 if hanging else 0.0
    z=-.535 if hanging else 0.0
    # The retained CC0 core gains a real protective cage, cap vents and rivets.
    for x in [-.094,.094]:
        for front in [-1,1]:
            rod('Bent protective cage',[(x,y+front*.084,z+.07),(x*1.09,y+front*.098,z+.15),(x*.96,y+front*.085,z+.255)],.006,'iron',5)
    for i in [-1,0,1]:
        box('Hood vent',(i*.034,y-.094,z+.276),(.018,.003,.014),'soot')
    box('Stained lower lip',(0,y,z+.042),(.232,.22,.015),'rust',(.013,-.02,.008))
    for x in [-.084,.084]:nail((x,y-.115,z+.051),'iron_edge',.008)
    if hanging:
        rod('Curved bracket stay',[(0,-.026,-.20),(0,-.12,-.18),(0,-.235,-.045)],.011,'iron',6)
    else:
        rod('Hinged carrying bail',[(-.085,0,.29),(-.086,.003,.372),(-.045,.008,.411),(.047,.008,.413),(.087,.003,.37),(.085,0,.29)],.008,'iron',6)

def miner():
    original_miner()
    # Distinct cap, beard, belt and grasp read as a worn carving at eye height.
    lump('Chipped carved beard',(0,-.233,1.004),(.034,.022,.035),'wood_dark',72)
    beam('Carved belt',(-.085,-.247,.846),(.080,-.247,.844),.018,.018,'wood_dark',5)
    for side in [-1,1]:
        lump('Carved hand',(side*.065,-.285,.902),(.022,.023,.025),'wood_light',side+8)
        G.mesh_object('Recessed carved eye',[(side*.023-.007,-.242,1.060),(side*.023+.005,-.244,1.061),
             (side*.023+.005,-.244,1.054),(side*.023-.007,-.242,1.053)],[(0,1,2,3)],'split')
    for i in range(4):rod('Carving gouge',[(-.065+i*.035,-.258,.90),(-.062+i*.035,-.26,.96)],.0016,'wood_dark',3)

def shrine_base():
    # Retain the former root/shelf/figure seats while breaking up masonry courses.
    old=G.miner;G.miner=miner
    try:G.shrine_base()
    finally:G.miner=old
    for side in [-1,1]:
        for i in range(4):
            z=.57+i*.23
            rod('Cracked mortar',[(side*.39,-.286,z-.05),(side*.44,-.29,z),(side*.48,-.283,z+.035)],.003,'stone_dark',3)
    for i in range(3):
        nail((-.38+i*.38,-.267,1.464),'rust',.018)
    # A shallow, irregular stone footing ties it into the cave floor.
    for i in range(4):lump('Chipped footing',(-.42+i*.28,-.22,.027),(.16,.20,.027),'stone_dark',i+20)

def offerings(spent):
    G.offerings(spent)
    if not spent:
        for i in range(4):
            x=-.16+i*.09
            rod('Cloth fold',[(x,-.28,.673),(x+.009,-.43,.667),(x-.006,-.458,.46)],.003,'cloth_dark',3)
        for x,y,_,height in G.CANDLES:
            rod('Wax drip',[(x+.017,y-.018,height*.73),(x+.02,y-.018,.025)],.0045,'wax',5)

def flames():
    # One combined surface for all three tiny flames.
    for x,y,z,height in G.CANDLES:
        bpy.ops.mesh.primitive_cone_add(vertices=6,radius1=.008,radius2=0,depth=.026,location=(x,y,z+height+.013))
        bpy.context.object.name='Candle flame'
        bpy.context.object.data.materials.append(G.MATERIALS['glass'])

def workings(spent):
    for side in [-1,1]:
        beam('Short pit prop',(side*.49,.24,0),(side*.48,.25,.91),.12,.16,'wood_dark',side+14)
        beam('Short brace',(side*.47,.24,.66),(side*.26,.23,.87),.07,.085,'wood',side+16)
    beam('Sagging pit lintel',(-.59,.25,.90),(.59,.25,.88),.17,.20,'wood_grey',19)
    for i in range(4):
        lump('Fractured worked rock',(-.34+i*.22,.29,.25),(.20,.16,.23),'stone_dark',i+31)
    for side in [-1,1]:
        beam('Ore trough rim',(-.36,side*.20,.08),(.32,side*.20,.08),.07,.075,'wood_dark',side+5)
    for i in range(4):
        beam('Trough split board',(-.36,-.15+i*.10,.035),(.32,-.15+i*.10,.035),.045,.095,'wood',i+9)
    rod('Crooked pick handle',[(.36,-.21,.025),(.38,-.15,.20),(.43,.03,.48),(.46,.12,.60)],.016,'wood_light',7)
    rod('Forged pointed pick',[(.22,.10,.56),(.32,.11,.60),(.47,.13,.62),(.62,.14,.57)],.023,'iron',5)
    for i in range(5):lump('Loose rubble',(-.5+i*.24,-.34,.026),(.06,.05,.026),'stone_dark',i+4)
    if not spent:
        for i in range(5):
            at=((i%3-1)*.16,(i//3-.5)*.15,.12)
            lump('Ore chunk',at,(.09,.075,.075),'ore',i+5)
            rod('Irregular mineral seam',[(at[0]-.04,at[1]-.05,.16),(at[0],at[1]-.055,.18),(at[0]+.025,at[1]-.035,.16)],.009,'silver_dark',4)
    else:
        for x in [-.20,0,.20]:rod('Picked-clean scrape',[(x,-.14,.065),(x+.012,-.02,.061),(x+.05,.12,.065)],.003,'split',3)

def rail_profile(x,broken):
    section=[(-.045,0),(.045,0),(.045,.012),(.012,.020),(.012,.065),(.030,.070),(.030,.090),(-.030,.090),(-.030,.070),(-.012,.065),(-.012,.020),(-.045,.012)]
    vertices=[]
    for station,y in enumerate([-1,-.65,-.32,.02,.36,.70,1]):
        bend=.12*max(0,(y-.36)/.64)**2 if broken else 0
        lift=.13*max(0,(y-.36)/.64)**2 if broken else 0
        for dx,z in section:vertices.append((x+dx+bend+.0015*math.sin(station*3+z*40),y,z+.06+lift))
    faces=[tuple(reversed(range(12))),tuple(range(72,84))]
    for station in range(6):
        for i in range(12):faces.append((station*12+i,station*12+(i+1)%12,(station+1)*12+(i+1)%12,(station+1)*12+i))
    obj=G.mesh_object('Worn bent rail' if broken else 'Worn rail',vertices,[tuple(reversed(f)) for f in faces],'rust')
    obj.data.materials.append(G.MATERIALS['iron_edge'])
    for face in obj.data.polygons:
        if face.index>=2 and (face.index-2)%12 in [5,6,7]:face.material_index=1

def rails(broken):
    for i in range(5):
        if broken and i==3:continue
        y=(i-2)*.42
        beam('Hewn sleeper',(-.56,y,.035),(.56,y+.013,.035),.07,.16,'wood_dark',i+24)
        for side in [-1,1]:
            box('Rail shoe',(side*.37,y,.071),(.13,.12,.014),'iron')
            nail((side*.43,y-.03,.084),'iron_edge',.014)
        rod('Sleeper grain check',[(-.43,y-.081,.06),(-.10,y-.086,.062),(.16,y-.083,.063)],.0025,'split',3)
    rail_profile(-.37,False);rail_profile(.37,broken)
    for side in [-1,1]:
        box('Fishplate',(side*.37-.015,-.79,.098),(.023,.25,.040),'iron')
        for y in [-.87,-.73]:lump('Fishplate bolt',(side*.37-.031,y,.1),(.009,.012,.009),'iron_edge',3)
    if broken:beam('Splintered sleeper',(-.54,.42,.035),(.10,.47,.035),.07,.16,'wood_grey',18)

CHEST_SOURCE=ROOT/'art/third-party/kaykit-containers-rest-v1/chest.glb'
SCALE={'common':(.55,.55,.55,.55),'silver':(.575,.55,.55,.80),'gold':(.61,.57,.55,1.0)}
HINGE_Y=.5648832321166992

def chest_source(tier,lid):
    bpy.ops.import_scene.gltf(filepath=str(CHEST_SOURCE),import_pack_images=True)
    objects=list(bpy.context.selected_objects)
    obj=next(o for o in objects if o.name==('chest_lid' if lid else 'chest'))
    points=[obj.matrix_world@v.co for v in obj.data.vertices]
    image=next(n.image for n in obj.data.materials[0].node_tree.nodes if n.type=='TEX_IMAGE')
    pixels=list(image.pixels);names=[]
    for face in obj.data.polygons:
        uv=obj.data.uv_layers.active.data[face.loop_indices[0]].uv
        x=min(image.size[0]-1,max(0,int(uv.x*image.size[0])))
        y=min(image.size[1]-1,max(0,int(uv.y*image.size[1])))
        rgb=pixels[(y*image.size[0]+x)*4:(y*image.size[0]+x)*4+3]
        warm=rgb[0]>rgb[1]*1.1 and rgb[0]>rgb[2]*1.2
        names.append(('wood_light' if tier=='common' else 'wood_dark') if warm else ('iron' if tier=='common' else tier))
    obj.data.materials.clear()
    materials=list(dict.fromkeys(names))
    for name in materials:obj.data.materials.append(G.MATERIALS[name])
    for face,name in zip(obj.data.polygons,names):face.material_index=materials.index(name)
    sx,sy,sz,rise=SCALE[tier]
    origin=Vector((0,HINGE_Y,.5)) if lid else Vector((0,0,0))
    obj.parent=None;obj.matrix_world.identity()
    for vertex,point in zip(obj.data.vertices,points):
        point-=origin
        vertex.co=Vector((point.x*sx+.003*math.sin(point.z*6+point.y*4),point.y*sy,point.z*sz*(rise if lid else 1)))
        if not lid:vertex.co.z+=.04
    obj.name='CC0 chest '+('lid' if lid else 'body')
    for other in objects:
        if other!=obj:bpy.data.objects.remove(other,do_unlink=True)
    bevel(obj,.003 if tier=='common' else .004)
    return obj

def escutcheon(name,at,width,height,metal):
    x,y,z=at
    outline=[(-.5,-.22),(-.5,.32),(-.31,.50),(.31,.50),(.5,.32),(.5,-.22),(0,-.50)]
    vertices=[(x+u*width,y+depth,z+v*height) for depth in [0,.012] for u,v in outline]
    n=len(outline)
    faces=[tuple(reversed(range(n))),tuple(range(n,n*2))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return G.mesh_object(name,vertices,faces,metal)

def filigree(x,y,z,metal,scale=1):
    # Raised scrolls with a tapered leaf tip; shallow enough to survive handling.
    points=[]
    for i in range(15):
        a=i/14*math.pi*1.65;r=(.06-.0028*i)*scale
        points.append((x+r*math.cos(a),y,z+r*math.sin(a)))
    rod('Raised chased scroll',points,.0045*scale,metal,4)

def chest(tier,lid):
    source=chest_source(tier,lid)
    metal='iron' if tier=='common' else tier
    sx,sy,sz,rise=SCALE[tier]
    half=.48*(sx/.55)
    front=-.38
    if lid:
        bpy.context.view_layer.update()
        surface=BVHTree.FromObject(source,bpy.context.evaluated_depsgraph_get())
        def fitted(points):
            result=[]
            for x,y in points:
                hit,_,_,_=surface.ray_cast(Vector((x,y,2)),Vector((0,0,-1)),4)
                if hit is not None:result.append((x,y,hit.z+.006))
            return result
        if tier=='silver':
            # A third reinforcing arch and a broad engraved centre strap.
            points=fitted([(0,-.65+i*.08) for i in range(9)])
            if len(points)>1:rod('Silver central arched rib',points,.012,'silver_edge',6)
        elif tier=='gold':
            # Raised decoration is projected onto the actual curved CC0 lid.
            for side in [-1,1]:
                points=fitted([(side*half*.90,-.66+i*.08) for i in range(9)])
                if len(points)>1:rod('Embossed gold lid rail',points,.009,'gold_edge',6)
                spiral=[(side*.25+(.065-i*.003)*math.cos(i*.40),-.35+(.065-i*.003)*math.sin(i*.40)) for i in range(15)]
                points=fitted(spiral)
                if len(points)>1:rod('Chased lid scroll',points,.0045,'gold_edge',4)
            point=fitted([(0,-.35)])[0]
            outline=[(0,-.59),(.09,-.48),(.17,-.36),(.09,-.24),(0,-.13),(-.09,-.24),(-.17,-.36),(-.09,-.48),(0,-.59)]
            rod('Gold lozenge lid emblem',fitted(outline),.007,'gold_edge',5)
            bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=.054,depth=.008,location=point)
            bpy.context.object.name='Lid seal';bpy.context.object.data.materials.append(G.MATERIALS['gold_edge'])
        return
    for side in [-1,1]:
        for back in [-1,1]:
            box('Irregular chest foot',(side*(half-.07),back*.28,.032),(.115,.12,.064),'iron' if tier=='common' else metal,(0,.01,side*.02))
        ring('Side pull ring',(side*(half+.004),0,.23),.052,metal,(0,math.pi/2,0),.006)
        if tier!='common':
            for back in [-1,1]:
                box('Metal corner guard',(side*(half-.025),back*.315,.18),(.08,.065,.28),metal,(0,.012,side*.013))
                for z in [.08,.26]:nail((side*(half-.026),back*.351,z),tier+'_edge',.012)
    if tier=='common':
        beam('Old repair board',(-.37,front-.012,.10),(-.08,front-.012,.23),.043,.016,'wood_grey',43)
        for x,z in [(-.33,.12),(-.11,.21)]:nail((x,front-.029,z),'rust',.013)
        escutcheon('Simple lock plate',(0,front-.015,.21),.072,.095,'iron')
    else:
        escutcheon('Decorated lock plate',(0,front-.016,.20),.13 if tier=='silver' else .17,.16 if tier=='silver' else .20,tier+'_edge')
        box('Key slot',(0,front-.021,.20),(.008,.004,.026),'soot')
        for z in [.07,.28]:
            beam('Raised front trim',(-half+.065,front-.012,z),(half-.065,front-.012,z+.002),.018,.012,tier+'_edge',51)
        for side in [-1,1]:
            filigree(side*.245,front-.027,.18,tier+'_edge',.75 if tier=='silver' else 1.05)
        if tier=='gold':
            for side in [-1,1]:
                escutcheon('Gold inset shield',(side*.30,front-.02,.17),.20,.17,'gold_dark')
                filigree(side*.30,front-.037,.17,'gold_edge',.95)
                for i in range(5):
                    x=side*(.16+i*.055)
                    lump('Worn repoussé bead',(x,front-.025,.285),(.010,.006,.008),'gold_edge',i+4)

def contents():
    # Decorative only: the controller's actual loot never comes from these meshes.
    lump('Tied dark bundle',(-.13,.09,.23),(.13,.09,.09),'cloth_dark',6)
    ring('Bundle cord',(-.13,.09,.23),.09,'leather',(0,math.pi/2,0),.004)
    for i in range(7):
        bpy.ops.mesh.primitive_cylinder_add(vertices=10,radius=.022,depth=.004,location=(.10+i*.016,-.06+i*.009,.19+i*.003))
        bpy.context.object.name='Decorative coin';bpy.context.object.data.materials.append(G.MATERIALS['gold'])

def group_for(material):
    if material=='glass':return 'Glass'
    if material.startswith('silver'):return 'Silver'
    if material.startswith('gold') or material=='copper':return 'Gold'
    if material.startswith(('wood','split','leather')):return 'Wood'
    if material.startswith(('stone','ore','ash','soot')):return 'Stone'
    if material.startswith(('cloth','wax','wick')):return 'Cloth'
    return 'Iron'

def linear(value):return value/12.92 if value<=.04045 else ((value+.055)/1.055)**2.4

def export(name,build,folder):
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    build();bpy.context.view_layer.update()
    objects=[obj for obj in bpy.context.scene.objects if obj.type=='MESH']
    bpy.ops.wm.save_as_mainfile(filepath=str(MASTERS/(name+'.blend')),check_existing=False)
    groups={}
    for number,obj in enumerate(objects):
        obj.data.update()
        start=Vector(obj.get('grain_origin',(0,0,0)))
        axis=Vector(obj.get('grain_axis',(1,0,0)))
        cross=axis.cross(Vector((0,1,0)) if abs(axis.y)<.9 else Vector((1,0,0))).normalized()
        other=axis.cross(cross)
        for face in obj.data.polygons:
            material=obj.data.materials[face.material_index].name
            group=group_for(material)
            vertices,faces,uvs,flags,colours=groups.setdefault(group,([],[],[],[],[]))
            first=len(vertices)
            normal=(obj.matrix_world.to_3x3()@face.normal).normalized()
            is_beam='grain_axis' in obj
            seed=(number*.61803398875)%1
            rgb=[linear(int(G.COLOURS[material][i:i+2],16)/255) for i in (0,2,4)]
            for index in face.vertices:
                point=obj.matrix_world@obj.data.vertices[index].co
                vertices.append(point)
                end=False
                if group=='Wood' and is_beam:
                    delta=point-start
                    end=abs(normal.dot(axis))>.8
                    if end:uv=(delta.dot(cross),delta.dot(other))
                    else:uv=(delta.dot(other if abs(normal.dot(cross))>.5 else cross),delta.dot(axis))
                else:
                    dominant=max(range(3),key=lambda i:abs(normal[i]))
                    uv=[(point.y,point.z),(point.x,point.z),(point.x,point.y)][dominant]
                    if group=='Wood':
                        end=dominant==0
                        if dominant==1:uv=(point.z,point.x)
                        elif dominant==2:uv=(point.y,point.x)
                uvs.append(uv);flags.append((1 if end else 0,seed))
                colours.append((*rgb,1))
            faces.append(tuple(range(first,first+len(face.vertices))))
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    triangle_count=0;all_points=[]
    for group,(vertices,faces,uvs,flags,colours) in groups.items():
        mesh=bpy.data.meshes.new(group);mesh.from_pydata(vertices,[],faces);mesh.update()
        uv=mesh.uv_layers.new(name='Physical grain metres')
        uv2=mesh.uv_layers.new(name='End grain and piece seed')
        colour=mesh.color_attributes.new(name='Material colour',type='FLOAT_COLOR',domain='CORNER')
        for face in mesh.polygons:
            for loop in face.loop_indices:
                index=mesh.loops[loop].vertex_index
                uv.data[loop].uv=uvs[index];uv2.data[loop].uv=flags[index];colour.data[loop].color=colours[index]
        obj=bpy.data.objects.new(group,mesh);bpy.context.collection.objects.link(obj);obj.select_set(True)
        mesh.calc_loop_triangles();triangle_count+=len(mesh.loop_triangles);all_points+=vertices
    path=folder/(name+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_materials='NONE',
        export_texcoords=True,export_vertex_color='ACTIVE',export_active_vertex_color_when_no_material=True,
        export_animations=False,export_cameras=False,export_lights=False)
    return {'id':name,'triangles':triangle_count,'surfaces':list(groups),'min':[min(p[i] for p in all_points) for i in range(3)],
       'max':[max(p[i] for p in all_points) for i in range(3)],'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}


def main():
    sources=[]
    for family in ['kaykit-mine-props-v1','kaykit-containers-rest-v1']:
        base=ROOT/'art/third-party'/family
        for entry in json.loads((base/'provenance.json').read_text())['files']:
            assert hashlib.sha256((base/entry['file']).read_bytes()).hexdigest()==entry['sha256']
        sources.append({'originals':base.relative_to(ROOT).as_posix(),'licence':'CC0-1.0','record':'provenance.json'})
    assets=[]
    for name,build in [('support',lambda:support(False)),('support-damaged',lambda:support(True)),
     ('lantern-standing',lambda:lantern(False)),('lantern-hanging',lambda:lantern(True)),('shrine-base',shrine_base),
     ('offerings-fresh',lambda:offerings(False)),('offerings-spent',lambda:offerings(True)),('flames',flames),
     ('workings-fresh',lambda:workings(False)),('workings-spent',lambda:workings(True)),
     ('rails',lambda:rails(False)),('rails-broken',lambda:rails(True))]:assets.append(export(name,build,MINE))
    (MINE/'catalog.json').write_text(json.dumps({'issue':278,'assets':assets,'sources':sources,'front':'+Z',
     'builder_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
     'clear_passage':{'width':1.60,'height':1.85},'candle_flames':[[x,z+h,-y] for x,y,z,h in G.CANDLES]},indent=2)+'\n')
    chests=[]
    for tier in ['common','silver','gold']:
        for lid in [False,True]:chests.append(export(tier+('-lid' if lid else '-body'),lambda tier=tier,lid=lid:chest(tier,lid),CHESTS))
    chests.append(export('contents',contents,CHESTS))
    (CHESTS/'catalog.json').write_text(json.dumps({'issue':279,'assets':chests,'sources':sources,
     'builder_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
     'tiers':['common','silver','gold'],'hinges':{tier:[0,.315,-HINGE_Y*SCALE[tier][1]] for tier in SCALE},
     'front':'+Z','states':['closed','open','empty'],'lid_angle_degrees':-102,'loot_authority':'caller'},indent=2)+'\n')
    print('REFINED_MINE',[(a['id'],a['triangles']) for a in assets])
    print('CHEST_TYPES',[(a['id'],a['triangles']) for a in chests])

if __name__=='__main__':main()
