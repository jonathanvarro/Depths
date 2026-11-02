"""Actually assign representative supplied clips; measure bone-axis mismatch.

This is a diagnostic, not a retargeter or an approval of cross-rig motion.
"""
import bpy,json,math
from pathlib import Path
from mathutils import Matrix
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/local-blender-kit-v1'
def main():
    results=[];checks=0
    for clip in ['Idle.fbx','Walking.fbx','Sitting Idle.fbx']:
        for fit in ['female','male']:
            bpy.ops.wm.read_factory_settings(use_empty=True)
            bpy.ops.import_scene.fbx(filepath=str(OUT/'source/clips'/clip),use_image_search=False,automatic_bone_orientation=False)
            source=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE');action=source.animation_data.action;slot=source.animation_data.action_slot
            before=set(bpy.context.scene.objects)
            bpy.ops.import_scene.fbx(filepath=str(OUT/'source'/('Base '+fit.title()+' - Dying.fbx')),use_image_search=False,automatic_bone_orientation=False)
            target=next(o for o in set(bpy.context.scene.objects)-before if o.type=='ARMATURE')
            for p in target.pose.bones:p.matrix_basis=Matrix.Identity(4)
            target.animation_data.action=action;target.animation_data.action_slot=slot
            assert target.animation_data.action==action and target.animation_data.action_slot==slot;checks+=1
            measures=[]
            for frame in [1,(action.frame_range[0]+action.frame_range[1])/2]:
                bpy.context.scene.frame_set(math.floor(frame),subframe=frame%1);bpy.context.view_layer.update()
                for name in ['mixamorig:LeftArm','mixamorig:RightArm','mixamorig:LeftUpLeg','mixamorig:RightUpLeg']:
                    a=source.pose.bones[name];b=target.pose.bones[name]
                    av=source.matrix_world.to_3x3()@(a.tail-a.head);bv=target.matrix_world.to_3x3()@(b.tail-b.head)
                    angle=math.degrees(av.angle(bv));assert math.isfinite(angle);checks+=1
                    measures.append({'frame':frame,'bone':name,'world_axis_angle_deg':angle})
            maximum=max(m['world_axis_angle_deg'] for m in measures)
            results.append({'clip':clip,'fit_id':fit+'-v1','action':action.name,'assigned_slot':slot.identifier,'max_axis_angle_deg':maximum,'direct_assignment_approved':False,'finding':'Target-specific rest-space retargeting and visual review required. The clip was not saved into the master.','measurements':measures})
    (OUT/'transfer-validation.json').write_text(json.dumps({'checks':checks,'failures':[],'results':results},indent=2)+'\n',encoding='utf-8')
    print('KIT_TRANSFER',checks,'checks; direct assignment measured, not approved',flush=True)
if __name__=='__main__':main()
