"""CC0 br-n518 spider family: source rig, metric wrapper, broad palette masses."""
import argparse,bpy,hashlib,json,math,sys
from pathlib import Path
from mathutils import Vector,Quaternion,Matrix
ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser();parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
OUT=args.workspace/'build/local-spiders-goblin-v1';(OUT/'masters').mkdir(parents=True,exist_ok=True)
ART=ROOT/'art/enemies/field-creatures-3d-v1';ART.mkdir(parents=True,exist_ok=True)
SOURCE=ROOT/'art/third-party/oga-creatures-v1'
assert hashlib.sha256((SOURCE/'spider.blend').read_bytes()).hexdigest()=='01e0d50597ba9d4a1d5ebaaa78da89ef6fd79df207f3fa9962b3e4e069b0112b'
COLOURS={'charcoal':'252c29','shell_dark':'3d4036','shell':'665f49','shell_light':'8c7b59',
    'web_dark':'596255','web_shell':'929485','web_light':'bbb69d','venom_dark':'494233',
    'venom_shell':'947a43','venom_light':'baa367','joint':'493d31','eye':'a45b35',
    'ivory':'c4b48c','skin_dark':'354132','skin':'5f6c4c','skin_light':'83916c',
    'cloth_dark':'382f2b','cloth':'63503f','cloth_light':'8b7152','wood_dark':'30291f',
    'wood':'58432e','wood_light':'785c3d','iron':'3b4440','iron_edge':'69716b',
    'rust':'794d34','leather':'4a3527','leather_light':'725139','mouth':'302326',
    'ochre':'9d8a57','ash':'7b7b6b','worn':'aaa28a','scar':'806859'}

def evaluated_points(mesh):
    ev=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get())
    return [mesh.matrix_world@v.co for v in ev.data.vertices]

def author_action(rig,name,baseline,length,poses):
    a=bpy.data.actions.new(name);a.use_fake_user=True;rig.animation_data.action=a
    for frame,amount in poses:
        for b in rig.pose.bones:
            b.matrix_basis=baseline[b.name].copy()
            if name=='hurt':
                if b.name=='thorax':b.rotation_quaternion=b.rotation_quaternion@Quaternion((0,1,0),math.radians(13)*amount)
                if b.name=='base':b.location.z-=.55*amount
                if b.name=='Bone':b.location.y+=.45*amount
            elif name=='fall':
                if b.name=='base':b.location.z-=1.45*amount
                if b.name in ['leg_AL','leg_AR','leg_BL','leg_BR','leg_CL','leg_CR','leg_DL','leg_DR']:
                    m=b.matrix.copy();p=m.translation.copy()
                    m.translation=Vector((p.x*(1-.55*amount),p.y*(1-.35*amount),p.z+(2.5-p.z)*amount));b.matrix=m
            elif name=='web':
                if b.name=='abdomen':b.rotation_quaternion=b.rotation_quaternion@Quaternion((1,0,0),math.radians(-22)*amount)
                if b.name=='base':b.location.z+=.4*amount
                if b.name=='Bone':b.location.y+=.15*amount
            elif name=='venom':
                if b.name=='thorax':b.rotation_quaternion=b.rotation_quaternion@Quaternion((1,0,0),math.radians(12)*amount)
                if b.name=='base':b.location.y-=.65*amount
            for path in ['location','rotation_quaternion','scale']:b.keyframe_insert(path,frame=frame)
    return a

def build(name):
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE/'spider.blend'),load_ui=False,use_scripts=False)
    for c in bpy.data.collections:c.hide_viewport=False
    for o in bpy.data.objects:o.hide_set(False);o.hide_viewport=False;o.hide_render=False
    if bpy.context.object and bpy.context.object.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
    rig=bpy.data.objects['Spider_Armature'];body=bpy.data.objects['Spider']
    for action in bpy.data.actions:action.name={'IDLE':'idle','WALK':'walk','ATTACK':'attack'}[action.name];action.use_fake_user=True
    rig.animation_data.action=bpy.data.actions['idle'];rig.animation_data.action_slot=rig.animation_data.action.slots[0]
    bpy.context.scene.frame_set(0);bpy.context.view_layer.update()
    groups={i:g.name for i,g in enumerate(body.vertex_groups)}
    source_uv=body.data.uv_layers.active
    old_uvs={p.index:[source_uv.data[i].uv.copy() for i in p.loop_indices] for p in body.data.polygons}
    picture=bpy.data.images.load(str(SOURCE/'spider.png'),check_existing=False);pixels=list(picture.pixels)
    semantics={}
    for v in body.data.vertices:
        weights={groups[g.group]:g.weight for g in v.groups};semantics[v.index]=max(weights,key=weights.get)
    abdomen=[v.co.copy() for v in body.data.vertices if semantics[v.index]=='abdomen']
    centre=sum(abdomen,Vector())/len(abdomen)
    for v in body.data.vertices:
        group=semantics[v.index]
        if group.startswith('leg') and group in rig.data.bones:
            bone=rig.data.bones[group];axis=bone.tail_local-bone.head_local
            t=max(0,min(1,(v.co-bone.head_local).dot(axis)/axis.length_squared))
            on=bone.head_local+axis*t
            v.co=on+(v.co-on)*1.6 # retain a readable leg width at phone size
        if group=='abdomen':
            f={'spider':(1,1,1),'webspinner':(1.20,1.24,1.27),'venom-spider':(.88,1.12,1.08)}[name]
            v.co=centre+Vector(tuple((v.co-centre)[i]*f[i] for i in range(3)))
    body.data.update()
    palette=body.data.uv_layers.new(name='DepthsPalette')
    for face in body.data.polygons:
        dom=[semantics[i] for i in face.vertices];part=max(set(dom),key=dom.count)
        uv=sum(old_uvs[face.index],Vector((0,0)))/len(old_uvs[face.index])
        x=min(255,max(0,int(uv.x*256)));y=min(255,max(0,int(uv.y*256)));r,g,b=pixels[(y*256+x)*4:(y*256+x)*4+3]
        normal=face.normal.z
        if min(r,g,b)>.7:colour='ivory'
        elif part.startswith('leg'):colour='joint' if face.index%7==0 else 'shell_dark' if normal<.1 else 'shell'
        else:
            level=0 if normal<-.1 else 2 if normal>.45 else 1
            colour={'spider':['shell_dark','shell','shell_light'],'webspinner':['web_dark','web_shell','web_light'],'venom-spider':['venom_dark','venom_shell','venom_light']}[name][level]
            if name=='venom-spider' and part=='abdomen' and abs(face.center.y-centre.y)<.9:colour='charcoal'
            if name=='webspinner' and part=='abdomen' and face.index%8==0:colour='web_dark'
        idx=list(COLOURS).index(colour)
        for loop in face.loop_indices:palette.data[loop].uv=((idx%8+.5)/8,(idx//8+.5)/4)
    body.data.uv_layers.active=palette
    for uv in body.data.uv_layers:uv.active_render=uv.name=='DepthsPalette'
    # Tiny modeled eyes survive palette simplification without painting whole
    # body/leg faces red. All six are attached to the thorax's skin group.
    eye_vertices=[];eye_faces=[]
    for x,y,z in [(-.28,-2.47,3.02),(.28,-2.47,3.02),(-.68,-2.29,2.83),(.68,-2.29,2.83),(-.92,-2.02,2.88),(.92,-2.02,2.88)]:
        start=len(eye_vertices);radius=.12
        eye_vertices.extend([(x+radius,y,z),(x-radius,y,z),(x,y-radius*.65,z),(x,y+radius*.65,z),(x,y,z+radius),(x,y,z-radius)])
        eye_faces.extend(tuple(start+i for i in f) for f in [(0,2,4),(2,1,4),(1,3,4),(3,0,4),(2,0,5),(1,2,5),(3,1,5),(0,3,5)])
    eye_mesh=bpy.data.meshes.new('Six eye islands');eye_mesh.from_pydata(eye_vertices,[],eye_faces);eye_mesh.update()
    eye=bpy.data.objects.new('Eyes',eye_mesh);bpy.context.collection.objects.link(eye)
    group=eye.vertex_groups.new(name='thorax');group.add(list(range(len(eye_vertices))),1,'REPLACE')
    mod=eye.modifiers.new('Thorax skin','ARMATURE');mod.object=rig
    eye_uv=eye_mesh.uv_layers.new(name='DepthsPalette');index=list(COLOURS).index('eye')
    for loop in eye_uv.data:loop.uv=((index%8+.5)/8,(index//8+.5)/4)
    bpy.ops.object.select_all(action='DESELECT');body.select_set(True);eye.select_set(True);bpy.context.view_layer.objects.active=body;bpy.ops.object.join()
    baseline={b.name:b.matrix_basis.copy() for b in rig.pose.bones}
    author_action(rig,'hurt',baseline,10,[(0,0),(3,1),(6,.6),(10,0)])
    author_action(rig,'fall',baseline,16,[(0,0),(5,.25),(11,.85),(16,1)])
    author_action(rig,'web',baseline,16,[(0,0),(5,1),(10,.7),(16,0)])
    author_action(rig,'venom',baseline,16,[(0,0),(4,.35),(7,1),(12,.3),(16,0)])
    wrapper=bpy.data.objects.new('MetricFloorOrigin',None);bpy.context.collection.objects.link(wrapper);rig.parent=wrapper
    rig.animation_data.action=bpy.data.actions['idle'];rig.animation_data.action_slot=rig.animation_data.action.slots[0]
    bpy.context.scene.frame_set(0);bpy.context.view_layer.update()
    points=evaluated_points(body);low=Vector(tuple(min(p[i] for p in points) for i in range(3)));high=Vector(tuple(max(p[i] for p in points) for i in range(3)))
    scale=.094
    wrapper.scale=(scale,)*3;wrapper.location=(-.5*(low.x+high.x)*scale,-.5*(low.y+high.y)*scale,-low.z*scale+.006)
    # Roll the complete internal rig (including IK controls) for the fall.
    # Fit each sample to its floor without moving the shared outer origin.
    corrections=[]
    rig.rotation_mode='QUATERNION'
    for action in bpy.data.actions:
        rig.animation_data.action=action;rig.animation_data.action_slot=action.slots[0]
        samples=[]
        for frame in range(int(action.frame_range[1])+1):
            bpy.context.scene.frame_set(frame)
            amount=frame/max(1,action.frame_range[1]) if action.name=='fall' else 0
            rig.rotation_quaternion=Quaternion((0,1,0),math.radians(120)*amount)
            pivot=Vector((0,0,2.2));rig.location=pivot-rig.rotation_quaternion@pivot
            bpy.context.view_layer.update()
            z=min(p.z for p in evaluated_points(body));delta=max(0,.006-z)
            location=rig.location.copy();location.z+=delta/scale
            samples.append((frame,location,rig.rotation_quaternion.copy()))
            corrections.append({'clip':action.name,'frame':frame,'lift':delta})
        for frame,location,rotation in samples:
            rig.location=location;rig.rotation_quaternion=rotation
            rig.keyframe_insert('location',frame=frame);rig.keyframe_insert('rotation_quaternion',frame=frame)
    rig.animation_data.action=bpy.data.actions['idle'];rig.animation_data.action_slot=rig.animation_data.action.slots[0];bpy.context.scene.frame_set(0)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'masters'/f'{name}.blend'))
    # Keep original UVs in the editable master; export only the runtime palette.
    for uv in list(body.data.uv_layers):
        if uv.name!='DepthsPalette':body.data.uv_layers.remove(uv)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [wrapper,rig,body]:obj.select_set(True)
    bpy.context.view_layer.objects.active=rig
    target=ART/(name+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,export_materials='NONE',
        export_animations=True,export_animation_mode='ACTIONS',export_frame_range=False,export_anim_slide_to_zero=True,
        export_force_sampling=True,export_frame_step=1,export_optimize_animation_size=False,
        export_current_frame=False,export_rest_position_armature=True,export_skins=True,export_cameras=False,export_lights=False)
    body.data.calc_loop_triangles()
    return {'id':name,'triangles':len(body.data.loop_triangles),'bones':len(rig.data.bones),'scale':scale,'front':'+Z',
        'clips':{a.name:{'frames':list(a.frame_range),'fps':24} for a in bpy.data.actions},
        'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'contact_corrections':corrections}

assets=[build(name) for name in ['spider','webspinner','venom-spider']]
(ART/'catalog.json').write_text(json.dumps({'issue':255,'palette':COLOURS,'assets':assets},indent=2)+'\n',encoding='utf-8')
print('SPIDER_FAMILY',[(a['id'],a['triangles'],a['bones']) for a in assets])
