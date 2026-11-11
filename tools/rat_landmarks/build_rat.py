"""Adapt br-n518's CC0 rat; originals remain byte-for-byte unchanged."""
import argparse, hashlib, json, math, sys
from pathlib import Path
import bpy
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser()
parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
WORK=args.workspace/'build/local-rat-landmarks-v1'
ART=ROOT/'art/enemies/rat-3d-v1'
ART.mkdir(parents=True,exist_ok=True)
(WORK/'masters').mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(WORK/'source/rat.blend'),load_ui=False,use_scripts=False)
rig=bpy.data.objects['Rat_Armature']; rat=bpy.data.objects['Rat']
for collection in bpy.data.collections:
    collection.hide_viewport=False
for o in bpy.data.objects:
    o.hide_set(False); o.hide_viewport=False; o.hide_render=False
if bpy.context.object and bpy.context.object.mode!='OBJECT': bpy.ops.object.mode_set(mode='OBJECT')
# A compact, worn colour treatment; original UVs/weights/topology are preserved.
image=bpy.data.images.load(str(ART/'rat.png'),check_existing=False)
mat=bpy.data.materials.new('Muted rat hide'); mat.use_nodes=True
bsdf=mat.node_tree.nodes.get('Principled BSDF'); bsdf.inputs['Roughness'].default_value=1
tex=mat.node_tree.nodes.new('ShaderNodeTexImage'); tex.image=image; tex.interpolation='Closest'
mat.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
rat.data.materials.clear(); rat.data.materials.append(mat)
for p in rat.data.polygons: p.material_index=0

wrapper=bpy.data.objects.new('MetricFloorOrigin',None); bpy.context.collection.objects.link(wrapper)
rig.parent=wrapper
# Source front -Y becomes glTF/Godot +Z. One constant transform for all clips.
rig.animation_data.action=bpy.data.actions['idle-loop']
rig.animation_data.action_slot=rig.animation_data.action.slots[0]
bpy.context.scene.frame_set(0); bpy.context.view_layer.update()
deps=bpy.context.evaluated_depsgraph_get(); evaluated=rat.evaluated_get(deps)
points=[rat.matrix_world@v.co for v in evaluated.data.vertices]
low=Vector(tuple(min(p[i] for p in points) for i in range(3)))
high=Vector(tuple(max(p[i] for p in points) for i in range(3)))
SCALE=.48
wrapper.scale=(SCALE,)*3
wrapper.location=Vector((-(low.x+high.x)/2*SCALE,-(low.y+high.y)/2*SCALE,-low.z*SCALE))

source_actions=list(bpy.data.actions)
for a in source_actions:
    a.name={'idle-loop':'idle','death':'fall','walk-loop':'walk','run-loop':'run'}.get(a.name,a.name)
    a.use_fake_user=True
# Source walk/run omit the repeated closing frame (15 is the last unique
# sample). Add frame 16 = frame 0 so a continuous glTF loop has its full period.
for name in ['walk','run']:
    action=bpy.data.actions[name]
    rig.animation_data.action=action;rig.animation_data.action_slot=action.slots[0]
    bpy.context.scene.frame_set(0);bpy.context.view_layer.update()
    closure={b.name:b.matrix_basis.copy() for b in rig.pose.bones}
    for b in rig.pose.bones:
        b.matrix_basis=closure[b.name]
        for path in ['location','rotation_quaternion','scale']:b.keyframe_insert(path,frame=16)
# Author a brief recoil with a planted, constant root; full rebound to idle.
rig.animation_data.action=bpy.data.actions['idle']
rig.animation_data.action_slot=rig.animation_data.action.slots[0]
bpy.context.scene.frame_set(0);bpy.context.view_layer.update()
baseline={b.name:b.matrix_basis.decompose() for b in rig.pose.bones}
hurt=bpy.data.actions.new('hurt'); hurt.use_fake_user=True
rig.animation_data.action=hurt
from mathutils import Quaternion
for frame,amount in [(0,0),(3,1),(6,.55),(10,0)]:
    for b in rig.pose.bones:
        b.rotation_mode='QUATERNION'
        b.location,b.rotation_quaternion,b.scale=baseline[b.name]
        if b.name=='root': b.rotation_quaternion=b.rotation_quaternion @ Quaternion((0,0,1),math.radians(-11)*amount)
        if b.name=='spine': b.rotation_quaternion=b.rotation_quaternion @ Quaternion((1,0,0),math.radians(-10)*amount)
        if b.name=='base': b.location.z-=.07*amount
        if b.name=='head_target': b.location.y+=.20*amount
        b.keyframe_insert('location',frame=frame)
        b.keyframe_insert('rotation_quaternion',frame=frame)
        b.keyframe_insert('scale',frame=frame)
# Source fall penetrates its floor. Correct only the internal root height;
# the shared outer origin stays fixed and original files remain unchanged.
contact=[]
for action in bpy.data.actions:
    rig.animation_data.action=action
    rig.animation_data.action_slot=action.slots[0]
    values=[]
    for frame in range(int(action.frame_range[0]),int(action.frame_range[1])+1):
        bpy.context.scene.frame_set(frame);bpy.context.view_layer.update()
        ev=rat.evaluated_get(bpy.context.evaluated_depsgraph_get())
        minimum=min((rat.matrix_world@v.co).z for v in ev.data.vertices)
        correction=max(0,.008-minimum) # 8 mm allowance for sampled skin interpolation.
        local=rig.pose.bones['root'].bone.matrix_local.to_3x3().inverted() @ (rig.matrix_world.inverted().to_3x3() @ Vector((0,0,correction)))
        values.append((frame,rig.pose.bones['root'].location.copy()+local))
        contact.append({'clip':action.name,'frame':frame,'source_low_metres':minimum,'lift_metres':correction})
    for frame,location in values:
        rig.pose.bones['root'].location=location
        rig.pose.bones['root'].keyframe_insert('location',frame=frame)
(WORK/'contact-corrections.json').write_text(json.dumps(contact,indent=2)+'\n')
rig.animation_data.action=bpy.data.actions['idle']
rig.animation_data.action_slot=rig.animation_data.action.slots[0]
bpy.context.scene.frame_set(0)
bpy.context.scene.render.fps=24
bpy.ops.wm.save_as_mainfile(filepath=str(WORK/'masters/rat-adapted.blend'))
bpy.ops.object.select_all(action='DESELECT')
for o in [wrapper,rig,rat]: o.select_set(True)
bpy.context.view_layer.objects.active=rig
target=ART/'rat.glb'
bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,
    export_animations=True,export_animation_mode='ACTIONS',export_frame_range=False,
    export_anim_slide_to_zero=True,export_force_sampling=True,export_frame_step=1,
    export_optimize_animation_size=False,export_rest_position_armature=True,
    export_current_frame=False,export_skins=True,export_cameras=False,export_lights=False,
    export_materials='NONE')
rat.data.calc_loop_triangles()
report={'source':'br-n518, https://opengameart.org/content/rat-0','licence':'CC0-1.0',
    'triangles':len(rat.data.loop_triangles),'source_bones':len(rig.data.bones),'scale':SCALE,
    'origin':'floor-centred full idle envelope; front +Z in Godot','source_rest_low':list(low),
    'source_rest_high':list(high),'clips':{a.name:{'frames':list(a.frame_range),'fps':24} for a in bpy.data.actions},
    'sha256':hashlib.sha256(target.read_bytes()).hexdigest()}
(ART/'catalog.json').write_text(json.dumps(report,indent=2)+'\n')
print('RAT_EXPORT',json.dumps(report))
