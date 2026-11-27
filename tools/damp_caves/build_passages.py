"""#302 B/N1-N3. Blender-authored static geometry; no live travel authority.

Blender --background --factory-startup --disable-autoexec --python-exit-code 1
 --python tools/damp_caves/build_passages.py -- --workspace E:/GitHub/Depths
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
spec = importlib.util.spec_from_file_location('damp_worked_geometry', ROOT/'tools/mine_polish/build_models.py')
P = importlib.util.module_from_spec(spec); spec.loader.exec_module(P)
G = P.G
parser = argparse.ArgumentParser()
parser.add_argument('--workspace', type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
ART = ROOT/'art/features/damp-passages-v1'
MASTERS = args.workspace/'build/local-damp-passages-v1/masters'
ART.mkdir(parents=True, exist_ok=True); MASTERS.mkdir(parents=True, exist_ok=True)
(MASTERS/'.gdignore').write_text('')
colours = {'wet_rock':'687779','wet_dark':'35474a','calcite':'9ca69d','mud':'454b3f',
           'root_wet':'4e5140','root_cut':'84816a','rope':'898374','rope_dark':'555c51',
           'fungus_cap':'647c68','fungus_under':'a4ae91','fungus_dark':'394f45',
           'water_black':'192d31','void':'111c20','chalk':'dfd9b8','ground':'626d68',
           'canopy':'304347'}
for name, colour in colours.items():
    G.COLOURS[name] = colour
    material = bpy.data.materials.new(name)
    material.diffuse_color = (*(int(colour[i:i+2],16)/255 for i in (0,2,4)),1)
    G.MATERIALS[name] = material


def tube(name, points, radii, material='root_wet', sides=6):
    points = [Vector(p) for p in points]; vertices=[]
    for index, (point, radius) in enumerate(zip(points, radii)):
        direction=(points[min(index+1,len(points)-1)]-points[max(index-1,0)]).normalized()
        a=direction.cross(Vector((0,1,0)) if abs(direction.y)<.9 else Vector((1,0,0))).normalized()
        b=direction.cross(a)
        for i in range(sides):
            angle=i*math.tau/sides
            vertices.append(point+radius*(a*math.cos(angle)+b*math.sin(angle)))
    faces=[tuple(reversed(range(sides))),tuple(range((len(points)-1)*sides,len(points)*sides))]
    for ring in range(len(points)-1):
        for i in range(sides):
            j=(i+1)%sides;faces.append((ring*sides+i,ring*sides+j,(ring+1)*sides+j,(ring+1)*sides+i))
    obj=G.mesh_object(name,vertices,faces,material)
    for face in obj.data.polygons:face.use_smooth=True
    return obj


def rock(name, at, size, seed):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1,location=at)
    obj=bpy.context.object;obj.name=name;obj.scale=size
    rng=random.Random(seed)
    for v in obj.data.vertices:
        v.co*=1+.045*math.sin(v.co.z*18+seed)+rng.uniform(-.025,.025)
    obj.data.materials.append(G.MATERIALS['wet_rock'])
    for face in obj.data.polygons:face.use_smooth=True
    return obj


def floor_apron(pit=False):
    if not pit:
        P.box('Ground complete floor apron',(0,0,-.025),(2,2,.05),'ground')
        return
    vertices=[]; count=24
    for ring in range(2):
        for i in range(count):
            angle=i*math.tau/count; c,s=math.cos(angle),math.sin(angle)
            if ring==0:
                scale=1/max(abs(c),abs(s));vertices.append((c*scale,s*scale,0))
            else:vertices.append((c*.57,s*.69,-.025))
    G.mesh_object('Ground open shaft apron',vertices,
                  [(i,(i+1)%count,(i+1)%count+count,i+count) for i in range(count)],'ground')
    wall=vertices[count:]+[(x*.78,y*.8,-.9) for x,y,z in vertices[count:]]
    G.mesh_object('Water-cut shaft lining',wall,
                  [(i,(i+1)%count,(i+1)%count+count,i+count) for i in range(count)],'wet_dark')
    # Opaque dark water is below the footholds, never a lid across the aperture.
    bottom=[(x*.78,y*.8,-.91) for x,y,z in vertices[count:]]
    G.mesh_object('Black water below',bottom,[tuple(range(count))],'water_black')


def glyph(kind, at, size=.13):
    """Actual raised/chalk geometry, matching the small map glyph silhouettes."""
    x,y,z=at
    def stroke(points, radius=.010):
        return tube('Route mark',[(x+a*size,y,z+b*size) for a,b in points],
                    [radius]*len(points),'chalk',5)
    if kind=='cavern':
        stroke([(-1,-.6),(-1,.15),(-.65,.9),(0,1.15),(.65,.9),(1,.15),(1,-.6)])
        stroke([(-.35,-.6),(-.35,.0),(.05,.35),(.45,.0),(.45,-.6)],.009)
    elif kind=='hollows':
        stroke([(-1,.15),(-.8,.65),(0,1.0),(.8,.65),(1,.15),(-1,.15)])
        stroke([(-.25,.1),(-.25,-.65),(.3,-.65),(.3,.1)])
        stroke([(-.65,-.65),(.65,-.65)],.009)
    else:
        stroke([(-.5,1),(-.95,.15),(-.8,-.2),(-.45,-.35),(-.1,-.2),(.05,.15),(-.5,1)])
        stroke([(.55,.65),(.15,-.05),(.22,-.4),(.58,-.55),(.9,-.4),(1,-.05),(.55,.65)],.009)


def sign(kind):
    P.beam('Scout marker stake',(-.72,-.65,.01),(-.72,-.65,.76),.055,.055,'wood_dark',13)
    P.box('Ragged route board',(-.72,-.65,.65),(.46,.065,.29),'wood_grey')
    glyph(kind,(-.72,-.69,.67),.09)
    for x in [-.90,-.54]:P.nail((x,-.69,.65),size=.01)


def shaft():
    floor_apron(True)
    for i in range(14):
        a=i*math.tau/14
        rock('Water-worn lip',(.64*math.cos(a),.76*math.sin(a),.025),(.13,.13,.08),i+10)
    for i in range(4):
        # Descends away from the observer (+Z front, -Z onward in Godot).
        rock('Rough descending foothold',(-.38+i*.065,-.38+i*.22,-.16-i*.19),(.23,.19,.095),i+40)
    tube('Rope handhold',[(-.67,-.62,.25),(-.60,-.24,.12),(-.50,.12,-.24),(-.39,.47,-.69)],
         [.025,.023,.021,.018],'rope')
    for y in [-.68,.48]:P.beam('Fixed rope peg',(-.72,y,.01),(-.72,y,.31),.055,.055,'wood_dark',int(y*20))
    sign('cavern')


def ladder():
    for i,x in enumerate([-.30,.30]):
        tube('Wet ladder side rope',[(x,-.55,.03),(x-.02,-.25,.72),(x+.015,.15,1.43),(x,.52,2.13)],
             [.026,.027,.025,.026],'rope',7)
    for i in range(9):
        z=.18+i*.215;y=-.55+(z/2.13)*1.07
        P.beam('Worn ladder rung',(-.34,y,z),(.34,y,z),.055,.05,'wood_grey',i+21)
    for i in range(14):
        a=i*math.tau/14
        obj=rock('Canopy wet ceiling rim',(.56*math.cos(a),.52+.32*math.sin(a),2.13),(.13,.11,.065),i+91)
        obj.data.materials.clear();obj.data.materials.append(G.MATERIALS['canopy'])
    points=[(.51*math.cos(i*math.tau/24),.52+.28*math.sin(i*math.tau/24),2.175) for i in range(24)]
    G.mesh_object('Canopy dark upper aperture',points,[tuple(reversed(range(24)))],'canopy')
    for x in [-.72,.72]:rock('Ladder landing stone',(x,.27,.08),(.16,.25,.12),int(x*20))
    sign('damp')


def mushroom(at, radius, height, seed):
    x,y,z=at
    tube('Fungal stem',[(x,y,z),(x+.015,y,z+height*.6),(x+.025,y,z+height)],
         [.023,.017,.014],'fungus_under',7)
    vertices=[];sides=11
    for radius_factor, dz in [(.76,-.035),(1,0),(.7,.05),(0,.085)]:
        for i in range(sides):
            angle=i*math.tau/sides
            r=radius*radius_factor*(1+.07*math.sin(i*3+seed))
            vertices.append((x+.025+r*math.cos(angle),y+r*math.sin(angle),z+height+dz))
    faces=[tuple(reversed(range(sides)))]
    for ring in range(3):
        for i in range(sides):faces.append((ring*sides+i,ring*sides+(i+1)%sides,(ring+1)*sides+(i+1)%sides,(ring+1)*sides+i))
    obj=G.mesh_object('Shelf fungus cap',vertices,faces,'fungus_cap')
    obj.data.materials.append(G.MATERIALS['fungus_under']);obj.data.polygons[0].material_index=1


def crawl(returning=False):
    if not returning:floor_apron(False)
    # Irregular connected arch, with a real recessed throat behind the opening.
    inner=[(-.62,0),(-.65,.58),(-.52,1.01),(-.34,1.28),(-.04,1.35),(.30,1.24),(.56,.98),(.65,.64),(.62,0)]
    vertices=[]
    for depth,outer in [(-.05,False),(-.05,True),(.84,False)]:
        for x,z in inner:
            vertices.append((x*(1.42 if outer else 1),depth,z*(1.28 if outer else 1)+(.03 if outer else 0)))
    faces=[];n=len(inner)
    for i in range(n-1):
        faces.extend([(i,i+1,i+1+n,i+n),(i+1,i,i+2*n,i+1+2*n)])
    G.mesh_object('Eroded low crawl arch',vertices,faces,'wet_dark' if returning else 'wet_rock')
    # The back is a sculpted dark tunnel end rather than a transparent poster.
    G.mesh_object('Deep crawl shadow',vertices[2*n:],[tuple(reversed(range(n)))],'void')
    for i in [0,1,3,5,7,9]:
        a=i*math.pi/9
        rock('Low eroded crawl rim',(.78*math.cos(a),.0,.25+1.28*math.sin(a)),(.20,.11,.105),i+122)
    for i,(x,y,z,r,h) in enumerate([(-.73,-.26,0,.18,.28),(.72,-.22,.03,.15,.18),(-.71,.38,.10,.13,.20),(.76,.43,.06,.12,.24)]):
        mushroom((x,y,z),r,h,i+11)
    if not returning:
        for i in range(3):mushroom((-.40+i*.33,.66,.02),.08,.13,i+40)
    else:
        # Return piece belongs to the fungal side, but shows colder stone beyond.
        tube('Thin mineral seep',[(-.40,.78,1.0),(-.44,.75,.65),(-.42,.73,.31)], [.014,.013,.006],'calcite',5)
    sign('damp' if returning else 'hollows')


def curtain(opened=False):
    rng=random.Random(602)
    for i in range(12):
        x=-.88+i*.16
        drift=rng.uniform(-.09,.09);sway=rng.uniform(-.07,.07)
        if opened:
            end=rng.uniform(1.89,2.00) if abs(x)<.7 else rng.uniform(.48,.75)
            points=[(x,.08,2.14),(x+drift,-.03,2.00),(x+sway,-.05,end)]
            radii=[.035,.026,.009]
        else:
            end=rng.uniform(.04,.26)
            points=[(x,.08,2.14),(x+drift,-.03,1.78),(x+sway,-.11,1.13),
                    (x-drift*.5,-.05,.54),(x+drift*.4,.01,end)]
            radii=[.035,.030,.022,.014,.003]
        tube('Gnarled hanging wet root',points,radii,'root_wet',7)
        if not opened:
            for j in [1,2]:
                a=Vector(points[j]);side=-1 if i%2 else 1
                tube('Snagged fibrous fork',[a,a+Vector((side*.09,-.02,-.13)),a+Vector((side*.15,-.03,-.34))],
                     [.013,.008,.002],'root_cut',5)
    if not opened:
        # Asymmetric snagged connections avoid the look of a woven fence.
        for i in range(7):
            x=-.78+i*.23;z=rng.uniform(.52,1.68)
            tube('Fine tangled root',[ (x,-.08,z),(x+.08,-.12,z-.15),(x+.26,-.06,z-.09)],
                 [.010,.007,.003],'root_wet',5)
    else:
        for x in [-.86,.86]:
            tube('Torn side root',[(x,.04,1.77),(x*.96,-.07,1.20),(x*1.03,-.02,.71)], [.031,.021,.009],'root_cut',6)
    for i,x in enumerate([-.86,.86]):rock('Root anchor',(x,.12,2.10),(.12,.16,.08),i+191)


def siltfall(cleared=False):
    # Both states retain the same edge banks; only the central fallen slab changes.
    for i in range(8):
        side=-1 if i<4 else 1
        rock('Bank of wet slide rubble',(side*(.81+.015*(i%2)),(i%4)*.20-.30,.07),(.13,.17,.08),i+201)
    if not cleared:
        profile=[(-.80,.10),(-.88,.50),(-.70,1.49),(-.44,1.77),(.34,1.67),(.80,1.32),(.74,.30),(.34,.09)]
        front=[(x,-.22+.035*math.sin(z*6),z) for x,z in profile]
        back=[(x+.03,.26,z-.025) for x,z in profile]
        n=len(profile);faces=[tuple(range(n)),tuple(reversed(range(n,2*n)))]
        faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
        # Reverse the front winding to face the approaching player.
        faces[0]=tuple(reversed(range(n)))
        G.mesh_object('Fractured limestone slab',front+back,faces,'wet_rock')
        for path in [[(-.47,-.27,1.62),(-.26,-.27,1.22),(-.32,-.27,.91),(.03,-.27,.58)],
                     [(.48,-.27,1.48),(.22,-.27,1.12),(.40,-.27,.69)]]:
            tube('Dark fractured vein',path,[.003 if i in [0,len(path)-1] else .006 for i in range(len(path))],'wet_dark',5)
        for i in range(7):
            x=-.62+i*.20
            rock('Silt-coated slab foot',(x,-.22+.04*math.sin(i*2),.13+.035*math.cos(i)),(.18+.05*math.cos(i*1.3),.19+.04*math.sin(i),.12+.04*math.cos(i*2)),i+250)
        obj=rock('Compacted silt bank',(0,.18,.15),(.73,.35,.18),312)
        obj.data.materials.clear();obj.data.materials.append(G.MATERIALS['mud'])
    else:
        for side in [-1,1]:P.box('Residual silt edge',(side*.83,.10,.035),(.20,.65,.06),'mud')


def kind(material):
    if material.startswith(('wood','rope')):return 1
    if material.startswith(('root','fungus')):return 2
    if material=='chalk':return 3
    if material in ['void','water_black','canopy']:return 4
    return 0


def export(ident, build):
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    build();bpy.context.view_layer.update()
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
    bpy.ops.wm.save_as_mainfile(filepath=str(MASTERS/(ident+'.blend')),check_existing=False)
    groups={};all_points=[]
    for number,obj in enumerate(objects):
        for face in obj.data.polygons:
            name=obj.data.materials[face.material_index].name
            group='Ground' if name=='ground' else ('Canopy' if name=='canopy' else 'Surface')
            vertices,faces,uvs,colours,flags,normals=groups.setdefault(group,([],[],[],[],[],[]))
            normal=(obj.matrix_world.to_3x3()@face.normal).normalized();dominant=max(range(3),key=lambda i:abs(normal[i]))
            first=len(vertices)
            rgb=[P.linear(int(G.COLOURS[name][i:i+2],16)/255) for i in (0,2,4)]
            for index in face.vertices:
                point=obj.matrix_world@obj.data.vertices[index].co
                vertices.append(point);all_points.append(point)
                source_normal=obj.data.vertices[index].normal if face.use_smooth else face.normal
                normals.append((obj.matrix_world.to_3x3().inverted().transposed()@source_normal).normalized())
                uvs.append([(point.y,point.z),(point.x,point.z),(point.x,point.y)][dominant])
                colours.append((*rgb,1));flags.append((kind(name),(number*.61803398875)%1))
            faces.append(tuple(range(first,first+len(face.vertices))))
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    triangles=0
    for group,(vertices,faces,uvs,colours,flags,normals) in groups.items():
        mesh=bpy.data.meshes.new(group);mesh.from_pydata(vertices,[],faces);mesh.update()
        uv=mesh.uv_layers.new(name='Physical material metres');uv2=mesh.uv_layers.new(name='Material type and piece seed')
        colour=mesh.color_attributes.new(name='Material colour',type='FLOAT_COLOR',domain='CORNER')
        for face in mesh.polygons:
            for loop in face.loop_indices:
                index=mesh.loops[loop].vertex_index
                uv.data[loop].uv=uvs[index];uv2.data[loop].uv=flags[index];colour.data[loop].color=colours[index]
        for face in mesh.polygons:face.use_smooth=True
        mesh.normals_split_custom_set([normals[loop.vertex_index] for loop in mesh.loops])
        obj=bpy.data.objects.new(group,mesh);bpy.context.collection.objects.link(obj);obj.select_set(True)
        mesh.calc_loop_triangles();triangles+=len(mesh.loop_triangles)
    target=ART/(ident+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,export_materials='NONE',
        export_texcoords=True,export_vertex_color='ACTIVE',export_active_vertex_color_when_no_material=True,
        export_animations=False,export_cameras=False,export_lights=False)
    lo=[min(p[i] for p in all_points) for i in range(3)];hi=[max(p[i] for p in all_points) for i in range(3)]
    # Blender Z-up -> Godot Y-up; store the final engine envelope explicitly.
    return {'id':ident,'model':'res://art/features/damp-passages-v1/'+ident+'.glb','triangles':triangles,
            'draws':len(groups),'materials':len(groups),'min':[lo[0],lo[2],-hi[1]],'max':[hi[0],hi[2],-lo[1]],
            'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'states':['static'],'mount':'floor-centre',
            'forward':'-Z','lights':0,'bones':0,'motion':'static; set_motion(false) is exact'}


recipes=[('cavern-onward',shaft),('cavern-return',ladder),('hollows-onward',lambda:crawl(False)),
         ('hollows-return',lambda:crawl(True)),('curtain-intact',lambda:curtain(False)),
         ('curtain-opened',lambda:curtain(True)),('siltfall-blocked',lambda:siltfall(False)),
         ('siltfall-cleared',lambda:siltfall(True))]
assets=[export(ident,recipe) for ident,recipe in recipes]
for row in assets:
    row['floor_aperture']=row['id']=='cavern-onward'
    row['provides_ground']=row['id'] in ['cavern-onward','hollows-onward']
    row['has_canopy']=row['id']=='cavern-return'
    row['sign']=row['id'] in ['cavern-onward','cavern-return','hollows-onward','hollows-return']
    if row['sign']:
        destination='cavern' if row['id']=='cavern-onward' else ('fungal-hollows' if row['id']=='hollows-onward' else 'damp-caves')
        row['destination_hint']=destination
        row['paired_asset']=row['id'].replace('onward','return') if 'onward' in row['id'] else row['id'].replace('return','onward')
    assert row['triangles']<=3200,row
    assert row['max'][0]<=1.01 and row['min'][0]>=-1.01,row
    assert row['max'][1]<=2.20 and row['min'][1]>=-.94,row
    assert row['max'][2]<=1.01 and row['min'][2]>=-1.01,row
catalog={'issue':302,'brief':'B1-B4 and destination-specific N1/N2/N3','assets':assets,
         'cell_metres':2,'wall_metres':2.2,'forward':'-Z','units':'metres, Godot coordinates in min/max',
         'gameplay':'No travel, collision, visibility, destination IDs, RNG or save authority. Metadata are art hints only.',
         'sources':[{'type':'Original authored geometry','builder':'tools/damp_caves/build_passages.py',
          'helpers':['tools/mine_props/build_models.py','tools/mine_polish/build_models.py'],
          'notes':'Reuses the existing original worked-prop primitives; no downloaded/private models, animations or source pixels.'}],
         'builder_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
(ART/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8')
print('DAMP_PASSAGES',[(row['id'],row['triangles'],row['draws']) for row in assets])
