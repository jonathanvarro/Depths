"""Target-space copies of supplied motions for garment validation only.

Source files/Actions and target rest rigs remain unchanged. No invented clips.
"""
import bpy,math
from mathutils import Matrix,Vector,Quaternion

CLIPS={'idle':'Idle.fbx','walk':'Walking.fbx','sit_down':'Stand To Sit.fbx','seated':'Sitting Idle.fbx'}

def retarget(rig,fit,source_path,clip_id):
    scene=bpy.context.scene
    original=rig.animation_data.action;original_slot=rig.animation_data.action_slot
    before=set(scene.objects);bpy.ops.import_scene.fbx(filepath=str(source_path),use_image_search=False,automatic_bone_orientation=False)
    added=set(scene.objects)-before;source=next(o for o in added if o.type=='ARMATURE')
    source_action=source.animation_data.action;first,last=map(round,source_action.frame_range)
    scene.frame_set(first);bpy.context.view_layer.update()
    target_world=rig.matrix_world.copy();target_inverse=target_world.inverted()
    source_rest_world=source.matrix_world@source.data.bones['mixamorig:Hips'].matrix_local
    target_rest_world=target_world@rig.data.bones['mixamorig:Hips'].matrix_local
    ratio=target_rest_world.translation.z/source_rest_world.translation.z
    toes=['mixamorig:LeftToeBase','mixamorig:RightToeBase']
    source_rest_low=min((source.matrix_world@source.data.bones[n].head_local).z for n in toes)
    target_rest_low=min((target_world@rig.data.bones[n].head_local).z for n in toes)
    action=bpy.data.actions.new('fit.'+fit+'.'+clip_id);action.use_fake_user=True
    slot=action.slots.new('OBJECT',rig.name);rig.animation_data.action=action;rig.animation_data.action_slot=slot
    rig.data.pose_position='POSE';source.data.pose_position='POSE'
    previous={};max_axis=0.0;largest_height_adjustment=0.0
    for frame in range(first,last+1):
        scene.frame_set(frame);bpy.context.view_layer.update();desired={}
        for bone in rig.data.bones:
            name=bone.name;parent=bone.parent
            relative=parent.matrix_local.inverted()@bone.matrix_local if parent else bone.matrix_local.copy()
            if name in source.pose.bones:
                sp=source.pose.bones[name];world=source.matrix_world@sp.matrix
                rotation=target_inverse.to_quaternion()@world.to_quaternion()
                position=(desired[parent.name]@relative).translation if parent else target_inverse@(target_rest_world.translation+(world.translation-source_rest_world.translation)*ratio)
                wanted=Matrix.Translation(position)@rotation.to_matrix().to_4x4()
            else:
                wanted=desired[parent.name]@relative if parent else bone.matrix_local.copy()
            desired[name]=wanted
        # Retarget foot-height differences caused by unequal limb lengths.
        # Preserve the source lower-toe trajectory, not an invented floor lock.
        source_low=min((source.matrix_world@source.pose.bones[n].matrix).translation.z for n in toes)
        target_low=min((target_world@desired[n]).translation.z for n in toes)
        shift=target_rest_low+(source_low-source_rest_low)*ratio-target_low
        largest_height_adjustment=max(largest_height_adjustment,abs(shift))
        delta=target_inverse.to_3x3()@Vector((0,0,shift))
        for wanted in desired.values():wanted.translation+=delta
        for bone in rig.data.bones:
            name=bone.name;parent=bone.parent;wanted=desired[name]
            relative=parent.matrix_local.inverted()@bone.matrix_local if parent else bone.matrix_local.copy()
            local=relative.inverted()@desired[parent.name].inverted()@wanted if parent else bone.matrix_local.inverted()@wanted
            p=rig.pose.bones[name];loc,rot,scale=local.decompose()
            if name in previous and rot.dot(previous[name])<0:rot.negate()
            previous[name]=rot.copy();p.rotation_mode='QUATERNION';p.location=loc;p.rotation_quaternion=rot;p.scale=(1,1,1)
            p.keyframe_insert('location',frame=frame,group=name);p.keyframe_insert('rotation_quaternion',frame=frame,group=name)
        if frame in [first,(first+last)//2,last]:
            bpy.context.view_layer.update()
            for name in ['mixamorig:LeftArm','mixamorig:RightArm','mixamorig:LeftUpLeg','mixamorig:RightUpLeg']:
                a=source.matrix_world.to_3x3()@(source.pose.bones[name].tail-source.pose.bones[name].head)
                b=target_world.to_3x3()@(rig.pose.bones[name].tail-rig.pose.bones[name].head)
                max_axis=max(max_axis,math.degrees(a.angle(b)))
    action['fit_id']=fit+'-v1';action['source_clip']=source_path.name
    action['root_motion']='Source hips displacement scaled by target/source rest hip height, with explicit target-only vertical lower-toe trajectory reconciliation for unequal leg lengths. No foot lock, floor IK or hand edits; lateral source path retained.'
    action['finger_policy']='Target-only ring/pinky bones keep their original rest-relative rotation under the animated parent.'
    for layer in action.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                for curve in bag.fcurves:
                    for k in curve.keyframe_points:k.interpolation='LINEAR'
    for o in added:bpy.data.objects.remove(o,do_unlink=True)
    source_action.use_fake_user=False  # immutable originals remain in source/clips
    if source_action.users==0:bpy.data.actions.remove(source_action)
    rig.animation_data.action=original;rig.animation_data.action_slot=original_slot;rig.data.pose_position='REST'
    return {'id':clip_id,'action':action.name,'slot':slot.identifier,'source':source_path.name,'frames':[first,last],'fps':scene.render.fps,'hip_displacement_scale':ratio,'max_explicit_vertical_retarget_adjustment':largest_height_adjustment,'sampled_max_limb_axis_error_deg':max_axis,'owner_approved':False}
