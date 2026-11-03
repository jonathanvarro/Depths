"""#215: exact world-pose conversion for the selected body-matched uploads.

Unlike proportion retargeting, this copies the uploaded joint matrices exactly:
no hip-height ratio, toe reconciliation, timing edit or in-place conversion.
Existing masters and all downloaded source bytes remain untouched.
"""
import bpy,sys,json,hashlib,math
from pathlib import Path
from mathutils import Matrix
sys.dont_write_bytecode=True
sys.path.insert(0,str(Path(__file__).parent))
from prepare_masters import digest_rig
from build_garments import skin_digest
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'build/local-blender-kit-v1';RECEIVED=BASE/'animation-requests-v1/received-v1';OUT=RECEIVED/'candidates-v1'
SELECTION={
 'female':{'idle':('locomotion','idle.fbx'),'walk':('locomotion','walking.fbx'),'sit_down':('individual','Stand To Sit.fbx'),'seated':('individual','Sitting Talking.fbx')},
 'male':{'idle':('locomotion','idle.fbx'),'walk':('locomotion','walking.fbx'),'sit_down':('individual','Stand To Sit.fbx'),'seated':('individual','Sitting Idle.fbx')}
}
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def assign(rig,action):rig.animation_data.action=action;rig.animation_data.action_slot=action.slots[0];rig.data.pose_position='POSE'
def convert(rig,fit,key,entry):
    path=Path(entry['destination']);assert sha(path)==entry['sha256']
    original=rig.animation_data.action;original_slot=rig.animation_data.action_slot;scene=bpy.context.scene
    before=set(scene.objects);bpy.ops.import_scene.fbx(filepath=str(path),use_image_search=False,automatic_bone_orientation=False)
    added=set(scene.objects)-before;source=next(o for o in added if o.type=='ARMATURE');source_action=source.animation_data.action
    first,last=map(round,source_action.frame_range);assert scene.render.fps==60
    assert set(source.data.bones.keys())==set(rig.data.bones.keys()),'These candidates must be genuinely body-matched'
    inverse=rig.matrix_world.inverted();action=bpy.data.actions.new('received.'+fit+'.'+key);action.use_fake_user=True
    slot=action.slots.new('OBJECT',rig.name);assign(rig,action);source.data.pose_position='POSE';previous={}
    max_translation_channel=0;max_scale_error=0
    for frame in range(first,last+1):
        scene.frame_set(frame);bpy.context.view_layer.update()
        desired={name:inverse@source.matrix_world@source.pose.bones[name].matrix for name in rig.data.bones.keys()}
        for bone in rig.data.bones:
            parent=bone.parent;relative=parent.matrix_local.inverted()@bone.matrix_local if parent else bone.matrix_local.copy()
            local=relative.inverted()@desired[parent.name].inverted()@desired[bone.name] if parent else bone.matrix_local.inverted()@desired[bone.name]
            loc,rotation,scale=local.decompose()
            if bone.name in previous and rotation.dot(previous[bone.name])<0:rotation.negate()
            previous[bone.name]=rotation.copy();pose=rig.pose.bones[bone.name];pose.rotation_mode='QUATERNION';pose.location=loc;pose.rotation_quaternion=rotation;pose.scale=scale
            max_translation_channel=max(max_translation_channel,loc.length);max_scale_error=max(max_scale_error,max(abs(v-1) for v in scale))
            for prop in ['location','rotation_quaternion','scale']:pose.keyframe_insert(prop,frame=frame,group=bone.name)
        if frame%600==0:print('CONVERT_PROGRESS',fit,key,frame,'/',last,flush=True)
    for layer in action.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                for curve in bag.fcurves:
                    for point in curve.keyframe_points:point.interpolation='LINEAR'
    maximum_position=0;maximum_axis=0;maximum_matrix=0;samples=[]
    for frame in [first,first+.5,(first+last)/2+.5,last-.5,last]:
        scene.frame_set(math.floor(frame),subframe=frame%1);bpy.context.view_layer.update();position=0;axis=0;matrix_error=0
        for name in rig.data.bones.keys():
            a=source.matrix_world@source.pose.bones[name].matrix;b=rig.matrix_world@rig.pose.bones[name].matrix
            position=max(position,(a.translation-b.translation).length)
            av=source.matrix_world.to_3x3()@(source.pose.bones[name].tail-source.pose.bones[name].head);bv=rig.matrix_world.to_3x3()@(rig.pose.bones[name].tail-rig.pose.bones[name].head)
            axis=max(axis,math.degrees(av.angle(bv)))
            matrix_error=max(matrix_error,max(abs(a[i][j]-b[i][j]) for i in range(4) for j in range(4)))
        maximum_position=max(maximum_position,position);maximum_axis=max(maximum_axis,axis);maximum_matrix=max(maximum_matrix,matrix_error)
        samples.append({'frame':frame,'max_world_joint_position_error':position,'max_world_axis_error_degrees':axis,'max_world_matrix_element_error':matrix_error})
    assert maximum_position<.002 and maximum_axis<.2,(fit,key,maximum_position,maximum_axis)
    action['source_clip']=entry['name'];action['source_sha256']=entry['sha256'];action['conversion']='Full source world joint matrices baked into unchanged target rest space. No source root, proportions, floor, timing or loop modification.'
    for obj in added:bpy.data.objects.remove(obj,do_unlink=True)
    source_action.use_fake_user=False
    if source_action.users==0:bpy.data.actions.remove(source_action)
    rig.animation_data.action=original;rig.animation_data.action_slot=original_slot;rig.data.pose_position='REST'
    assert sha(path)==entry['sha256']
    return {'id':key,'action':action.name,'slot':slot.identifier,'source':fit+'/'+entry['collection']+'/'+entry['name'],'source_sha256':entry['sha256'],'frames':[first,last],'fps':60,'conversion_samples':samples,'max_world_position_error':maximum_position,'max_world_axis_error_degrees':maximum_axis,'max_world_matrix_element_error':maximum_matrix,'max_location_channel':max_translation_channel,'max_scale_channel_error':max_scale_error,'body_proportions_changed':False,'root_motion_modified':False,'floor_correction_added':False,'loop_approved':False,'owner_approved':False,'role':'Seated talking candidate; quiet chair hold still needed' if fit=='female' and key=='seated' else 'Uploaded motion candidate'}
def main():
    OUT.mkdir(exist_ok=True);(OUT/'.gdignore').touch();library=json.loads((RECEIVED/'library-audit.json').read_text())
    for fit in ['female','male']:
        source=BASE/'garments-v1'/(fit+'_garments.blend');source_hash=sha(source);path=OUT/(fit+'_received.blend')
        if path.exists():
            old=json.loads((OUT/(fit+'-manifest.json')).read_text());assert sha(path)==old['sha256'],'Preserve manually edited candidate'
        record=json.loads((BASE/'garments-v1'/(fit+'-manifest.json')).read_text())
        bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False,use_scripts=False);rig=bpy.data.objects['rig.'+fit+'.v1'];body=bpy.data.objects['body.'+fit+'.v1']
        original=rig.animation_data.action;rig_hash=digest_rig(rig);body_hash=skin_digest(body,rig)
        for action in list(bpy.data.actions):
            if action!=original:bpy.data.actions.remove(action,do_unlink=True)
        motions=[]
        for key,(collection,name) in SELECTION[fit].items():
            entry=next(e for e in library['files'] if e['fit']==fit and e['collection']==collection and e['name']==name)
            metrics=entry['compatibility'][fit];assert metrics['shared_bones']==(65 if fit=='female' else 49) and metrics['max_relative_bone_length_error']<.0001 and not metrics['parent_mismatches']
            motions.append(convert(rig,fit,key,entry));print('CONVERTED_RECEIVED',fit,key,motions[-1]['max_world_position_error'],motions[-1]['max_world_axis_error_degrees'],flush=True)
        assert digest_rig(rig)==rig_hash and skin_digest(body,rig)==body_hash
        rig.data.pose_position='REST';bpy.context.scene.frame_set(1);bpy.ops.wm.save_as_mainfile(filepath=str(path),check_existing=False)
        record.update({'master':path.name,'sha256':sha(path),'garment_source_master':source.relative_to(BASE).as_posix(),'garment_source_sha256':source_hash,'motions':motions,'received_profile':True,'final_animation_approval':False})
        (OUT/(fit+'-manifest.json')).write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8');assert sha(source)==source_hash
    print('RECEIVED_CANDIDATES_READY: eight uploaded motions, original bodies/rigs/clothes/sources unchanged',flush=True)
if __name__=='__main__':main()
