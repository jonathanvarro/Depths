"""Adapt CDmir/TinyWorlds' CC0 goblin to a reusable clothed combat base."""
import argparse,bpy,hashlib,json,math,sys
from pathlib import Path
from mathutils import Vector,Quaternion
ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser();parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
OUT=args.workspace/'build/local-spiders-goblin-v1';ART=ROOT/'art/enemies/field-creatures-3d-v1';SOURCE=ROOT/'art/third-party/oga-creatures-v1'
assert hashlib.sha256((SOURCE/'goblin.blend').read_bytes()).hexdigest()=='cec34eb0c06d6efd35b42f8a70c7921a0d404aa6755ac6ba526a6b4585faab1a'
catalog=json.loads((ART/'catalog.json').read_text(encoding='utf-8'));colours=catalog['palette']
bpy.ops.wm.open_mainfile(filepath=str(SOURCE/'goblin.blend'),load_ui=False,use_scripts=False)
for c in bpy.data.collections:c.hide_viewport=False
for o in bpy.data.objects:o.hide_set(False);o.hide_viewport=False;o.hide_render=False
if bpy.context.object and bpy.context.object.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
rig=bpy.data.objects['Armature'];body=bpy.data.objects['Body']
rig.animation_data.action=bpy.data.actions['Stand'];rig.animation_data.action_slot=rig.animation_data.action.slots[0]
bpy.context.scene.frame_set(0);bpy.context.view_layer.update()
baseline={b.name:b.matrix_basis.copy() for b in rig.pose.bones}
source_image=bpy.data.images['gobli-tex'];pixels=list(source_image.pixels)
MATERIAL=bpy.data.materials.new('Depths palette')

def palette(obj,kind):
    old=obj.data.uv_layers.active
    samples={p.index:sum((old.data[i].uv.copy() for i in p.loop_indices),Vector((0,0)))/len(p.loop_indices) for p in obj.data.polygons} if old else {}
    layer=obj.data.uv_layers.get('DepthsPalette') or obj.data.uv_layers.new(name='DepthsPalette')
    for face in obj.data.polygons:
        if kind=='skin':
            uv=samples.get(face.index,Vector((.5,.5)));x=max(0,min(1023,int(uv.x*1024)));y=max(0,min(1023,int(uv.y*1024)))
            r,g,b=pixels[(y*1024+x)*4:(y*1024+x)*4+3];l=(r+g+b)/3
            colour='skin_dark' if l<.22 else 'skin_light' if l>.60 else 'skin'
        elif kind=='eyes':colour='ochre' if face.normal.y<-.45 else 'charcoal'
        elif kind=='cloth':colour='cloth_dark' if face.normal.z<-.1 else 'cloth' if face.index%5 else 'cloth_light'
        else:colour=kind
        i=list(colours).index(colour)
        for loop in face.loop_indices:layer.data[loop].uv=((i%8+.5)/8,(i//8+.5)/4)
        face.use_smooth=False;face.material_index=0
    obj.data.materials.clear();obj.data.materials.append(MATERIAL)
    obj.data.uv_layers.active=layer
    for uv in obj.data.uv_layers:uv.active_render=uv.name=='DepthsPalette'

# Remove jewellery/necklace and the source preview plane, not the body rig.
for name in ['Ear','Neck','Tooth','Plane.003']:
    if name in bpy.data.objects:bpy.data.objects.remove(bpy.data.objects[name],do_unlink=True)
for obj,ratio in [(body,.58),(bpy.data.objects['Eyes'],.55)]:
    bpy.context.view_layer.objects.active=obj
    mod=obj.modifiers.new('Phone mesh budget','DECIMATE');mod.ratio=ratio
    # Topology reduction in bind space; source weights transfer with the mesh.
    bpy.ops.object.modifier_move_up(modifier=mod.name)
    bpy.ops.object.modifier_apply(modifier=mod.name)

# Fit a sleeveless, ragged tunic to the source's own torso weights.
verts=[];faces=[];indices={}
groups={g.index:g.name for g in body.vertex_groups}
for face in body.data.polygons:
    centre=face.center
    torso=sum(g.weight for v in face.vertices for g in body.data.vertices[v].groups if groups[g.group].startswith('spine'))/len(face.vertices)
    if not (5.1<centre.z<9.15 and abs(centre.x)<1.95 and centre.y>-1.65):continue
    f=[]
    for vi in face.vertices:
        if vi not in indices:
            co=body.data.vertices[vi].co.copy();co.x*=1.07;co.y=.4+(co.y-.4)*1.09
            if co.z<5.7:co.z-=.10*(vi%3)
            indices[vi]=len(verts);verts.append(co)
        f.append(indices[vi])
    faces.append(f)
mesh=bpy.data.meshes.new('Ragged tunic');mesh.from_pydata(verts,[],faces);mesh.update()
tunic=bpy.data.objects.new('Tunic',mesh);bpy.context.collection.objects.link(tunic)
for group in body.vertex_groups:tunic.vertex_groups.new(name=group.name)
for old,new in indices.items():
    for w in body.data.vertices[old].groups:tunic.vertex_groups[w.group].add([new],w.weight,'REPLACE')
mod=tunic.modifiers.new('Body rig','ARMATURE');mod.object=rig
for obj,kind in [(body,'skin'),(bpy.data.objects['Eyes'],'eyes'),(bpy.data.objects['Belt'],'leather'),(bpy.data.objects['Cloth'],'cloth'),(tunic,'cloth')]:palette(obj,kind)
bpy.ops.object.select_all(action='DESELECT')
parts=[body,bpy.data.objects['Eyes'],bpy.data.objects['Belt'],bpy.data.objects['Cloth'],tunic]
for obj in parts:obj.select_set(True)
bpy.context.view_layer.objects.active=body;bpy.ops.object.join();body.name='GoblinBody'

def equipment(name,vertices,faces,face_colours,bone):
    # Author in hand-local coordinates, then bind rigidly to that named bone.
    transform=rig.data.bones[bone].matrix_local
    mesh=bpy.data.meshes.new(name);mesh.from_pydata([transform@Vector(v) for v in vertices],[],faces);mesh.update()
    obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj)
    group=obj.vertex_groups.new(name=bone);group.add(list(range(len(vertices))),1,'REPLACE')
    mod=obj.modifiers.new('Hand attachment','ARMATURE');mod.object=rig
    layer=mesh.uv_layers.new(name='DepthsPalette');mesh.materials.append(MATERIAL)
    for p,c in zip(mesh.polygons,face_colours):
        i=list(colours).index(c)
        for loop in p.loop_indices:layer.data[loop].uv=((i%8+.5)/8,(i//8+.5)/4)
    return obj

# An uneven, clipped iron blade. Local +Y follows the fingers in the source grip.
knife_vertices=[(-.12,.0,0),(.12,.0,0),(.10,.8,0),(.32,.85,0),(.25,2.75,0),(-.06,3.2,0),(-.25,2.8,0),(-.30,.85,0)]
vs=[(x,y+.4,z+.14) for x,y,z in knife_vertices]+[(x,y+.4,z-.02) for x,y,z in knife_vertices]
fs=[tuple(range(8)),tuple(reversed(range(8,16)))]+[(i,(i+1)%8,(i+1)%8+8,i+8) for i in range(8)]
knife=equipment('Knife',vs,fs,['iron_edge','iron']+['iron']*8,'hand_R')

# Crude round wooden buckler, with a faceted iron boss and edge damage.
vs=[(0,.5,.1)];fs=[];cs=[]
for i in range(12):
    a=i*math.tau/12;r=1.35*(.94 if i in [2,7] else 1)
    vs.append((r*math.cos(a),.5+r*math.sin(a),.1))
for i in range(12):fs.append((0,i+1,(i+1)%12+1));cs.append('wood' if i%3 else 'wood_light')
vs.append((0,.5,.36));boss=len(vs)-1
for i in range(8):
    a=i*math.tau/8;vs.append((.36*math.cos(a),.5+.36*math.sin(a),.13))
for i in range(8):fs.append((boss,boss+1+i,boss+1+(i+1)%8));cs.append('iron' if i%3 else 'rust')
back=len(vs);vs.append((0,.5,-.05))
for i in range(12):vs.append((vs[i+1][0],vs[i+1][1],-.05))
for i in range(12):
    j=(i+1)%12
    fs.append((back,back+1+j,back+1+i));cs.append('wood_dark')
    fs.append((i+1,back+1+i,back+1+j,j+1));cs.append('wood')
shield=equipment('Buckler',vs,fs,cs,'hand_L')

for action in list(bpy.data.actions):
    if action.name!='Die':bpy.data.actions.remove(action)
fall=bpy.data.actions['Die'];fall.name='fall';fall.use_fake_user=True
for layer in fall.layers:
    for strip in layer.strips:
        for bag in strip.channelbags:
            for curve in bag.fcurves:
                for key in curve.keyframe_points:
                    key.co.x*=.5;key.handle_left.x*=.5;key.handle_right.x*=.5

def action(name,frames):
    a=bpy.data.actions.new(name);a.use_fake_user=True;rig.animation_data.action=a
    for frame,amount in frames:
        for b in rig.pose.bones:b.matrix_basis=baseline[b.name].copy()
        if name=='idle':
            b=rig.pose.bones['IK-spine'];b.location.z+=.075*amount
            b=rig.pose.bones['IK-Head'];b.rotation_quaternion=b.rotation_quaternion@Quaternion((0,0,1),math.radians(2)*amount)
        elif name=='attack':
            b=rig.pose.bones['IK-Hand_R'];m=b.matrix.copy();m.translation+=Vector((1.8,-2.4,1.5))*amount;b.matrix=m
            b=rig.pose.bones['IK-spine'];b.location.y-=.25*amount
            b=rig.pose.bones['IK-Hand_L'];m=b.matrix.copy();m.translation+=Vector((-.3,-.6,.6))*amount;b.matrix=m
        elif name=='hurt':
            b=rig.pose.bones['IK-spine'];b.location.y+=.75*amount
            b=rig.pose.bones['IK-Head'];b.rotation_quaternion=b.rotation_quaternion@Quaternion((1,0,0),math.radians(-12)*amount)
        for b in rig.pose.bones:
            for path in ['location','rotation_quaternion','scale']:b.keyframe_insert(path,frame=frame)
    return a
idle=action('idle',[(0,0),(12,1),(24,0),(36,-1),(48,0)])
action('attack',[(0,0),(4,-.20),(8,1),(12,.45),(18,0)])
action('hurt',[(0,0),(3,1),(7,.4),(12,0)])
# Preserve the editable IK fitting master, then bake evaluated poses to FK.
# The source's constrained controls otherwise export differently from Blender
# for newly authored Actions. Capture all bones before removing constraints.
(OUT/'masters').mkdir(parents=True,exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'masters/goblin-controls.blend'))
sampled={}
for a in bpy.data.actions:
    rig.animation_data.action=a;rig.animation_data.action_slot=a.slots[0]
    frames=[]
    for frame in range(int(a.frame_range[1])+1):
        bpy.context.scene.frame_set(frame);bpy.context.view_layer.update()
        pose={b.name:b.matrix.copy() for b in rig.pose.bones}
        basis={}
        for b in rig.pose.bones:
            kw={'parent_matrix':pose[b.parent.name],'parent_matrix_local':b.parent.bone.matrix_local} if b.parent else {}
            basis[b.name]=b.bone.convert_local_to_pose(pose[b.name],b.bone.matrix_local,invert=True,**kw)
        frames.append((frame,basis))
    sampled[a.name]=frames
for b in rig.pose.bones:
    for c in list(b.constraints):b.constraints.remove(c)
    b.rotation_mode='QUATERNION'
for a in list(bpy.data.actions):bpy.data.actions.remove(a)
for name,frames in sampled.items():
    a=bpy.data.actions.new(name);a.use_fake_user=True;rig.animation_data.action=a
    for frame,basis in frames:
        for b in rig.pose.bones:
            b.matrix_basis=basis[b.name]
            for path in ['location','rotation_quaternion','scale']:b.keyframe_insert(path,frame=frame)
idle=bpy.data.actions['idle']
rig.animation_data.action=idle;rig.animation_data.action_slot=idle.slots[0];bpy.context.scene.frame_set(0);bpy.context.view_layer.update()
# All meshes must inherit the same metric wrapper, including the unparented source pieces.
for obj in [body,knife,shield]:
    world=obj.matrix_world.copy();obj.parent=rig;obj.matrix_world=world
wrapper=bpy.data.objects.new('MetricFloorOrigin',None);bpy.context.collection.objects.link(wrapper);rig.parent=wrapper
ev=body.evaluated_get(bpy.context.evaluated_depsgraph_get());points=[body.matrix_world@v.co for v in ev.data.vertices]
low=Vector(tuple(min(p[i] for p in points) for i in range(3)));high=Vector(tuple(max(p[i] for p in points) for i in range(3)))
scale=1.25/(high.z-low.z);wrapper.scale=(scale,)*3;wrapper.location=(-.5*(low.x+high.x)*scale,-.5*(low.y+high.y)*scale,-low.z*scale+.006)
# Correct only the internal rig's floor height, leaving the shared origin fixed.
rig.rotation_mode='QUATERNION';corrections=[]
for a in bpy.data.actions:
    rig.animation_data.action=a;rig.animation_data.action_slot=a.slots[0]
    samples=[]
    for frame in range(int(a.frame_range[1])+1):
        bpy.context.scene.frame_set(frame);rig.location=(0,0,0);bpy.context.view_layer.update()
        points=[]
        for mesh in [body,knife,shield]:
            ev=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get());points.extend(mesh.matrix_world@v.co for v in ev.data.vertices)
        delta=max(0,.006-min(p.z for p in points))
        shifts=[]
        for axis in [0,1]:
            low=min(p[axis] for p in points);high=max(p[axis] for p in points)
            shifts.append(max(0,-.97-low) if low<-.97 else min(0,.97-high) if high>.97 else 0)
        if a.name!='fall':shifts=[0,0]
        samples.append((frame,Vector((shifts[0]/scale,shifts[1]/scale,delta/scale))))
        corrections.append({'clip':a.name,'frame':frame,'lift':delta,'tile_shift_metres':shifts})
    for frame,location in samples:rig.location=location;rig.keyframe_insert('location',frame=frame)
rig.animation_data.action=idle;rig.animation_data.action_slot=idle.slots[0];bpy.context.scene.frame_set(0)
(OUT/'masters').mkdir(parents=True,exist_ok=True);bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'masters/goblin.blend'))
for obj in [body,knife,shield]:
    for uv in list(obj.data.uv_layers):
        if uv.name!='DepthsPalette':obj.data.uv_layers.remove(uv)
bpy.ops.object.select_all(action='DESELECT')
for obj in [wrapper,rig,body,knife,shield]:obj.select_set(True)
bpy.context.view_layer.objects.active=rig;target=ART/'goblin.glb'
bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,export_materials='NONE',
    export_animations=True,export_animation_mode='ACTIONS',export_frame_range=False,export_anim_slide_to_zero=True,
    export_force_sampling=True,export_frame_step=1,export_optimize_animation_size=False,
    export_current_frame=False,export_rest_position_armature=True,export_skins=True,export_all_influences=True,export_influence_nb=8,
    export_cameras=False,export_lights=False)
counts={}
for obj in [body,knife,shield]:obj.data.calc_loop_triangles();counts[obj.name]=len(obj.data.loop_triangles)
entry={'id':'goblin','triangles':sum(counts.values()),'parts':counts,'bones':len(rig.data.bones),'scale':scale,'front':'+Z',
    'clips':{a.name:{'frames':list(a.frame_range),'fps':24} for a in bpy.data.actions},'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),
    'equipment_bones':{'Knife':'hand_R','Buckler':'hand_L'},'contact_corrections':corrections}
catalog['assets']=[a for a in catalog['assets'] if a['id']!='goblin']+[entry]
(ART/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8')
print('GOBLIN_BASE',{k:v for k,v in entry.items() if k not in ['contact_corrections','clips']})
