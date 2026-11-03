"""#215: preserve/categorize every uploaded clip and measure both bind candidates.

All source, skeleton, Action and pose data remain in ignored local output.
Names/gendered pack labels do not establish animation or body compatibility.
"""
import bpy,sys,json,hashlib,math
from pathlib import Path
from mathutils import Vector,Matrix
sys.dont_write_bytecode=True
sys.path.insert(0,str(Path(__file__).parent))
from audit_body_downloads import read_fbx,bind_check
from audit_sources import scene_report
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'build/local-blender-kit-v1';OUT=BASE/'animation-requests-v1/received-v1'

def pose(rig):
    result={}
    for key in ['Hips','Head','LeftArm','RightArm','LeftForeArm','RightForeArm','LeftUpLeg','RightUpLeg','LeftLeg','RightLeg','LeftFoot','RightFoot']:
        bone=rig.pose.bones.get('mixamorig:'+key)
        if bone:result[key]={'head':list(rig.matrix_world@bone.head),'axis':list((rig.matrix_world.to_3x3()@(bone.tail-bone.head)).normalized())}
    return result
def main():
    sources=json.loads((OUT/'source-manifest.json').read_text());targets={};base_hashes={}
    for fit in ['female','male']:
        path=BASE/(fit+'_base.blend');base_hashes[fit]=hashlib.sha256(path.read_bytes()).hexdigest()
        bpy.ops.wm.open_mainfile(filepath=str(path),load_ui=False,use_scripts=False)
        targets[fit]=next(o for o in scene_report()['objects'] if o['type']=='ARMATURE')
    records=[]
    for entry in sources['files']:
        path=Path(entry['destination']);before=hashlib.sha256(path.read_bytes()).hexdigest();assert before==entry['sha256']
        source=read_fbx(path);rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
        actions=source['actions'];action=rig.animation_data.action
        first,last=[float(v) for v in action.frame_range];samples={}
        # Explicit real source frames; no trimmed or manufactured motion.
        for label,frame in [('start',first),('middle',(first+last)/2+.5),('end',last)]:
            bpy.context.scene.frame_set(math.floor(frame),subframe=frame%1);bpy.context.view_layer.update();samples[label]={'frame':frame,'bones':pose(rig)}
        start=samples['start']['bones'];end=samples['end']['bones']
        delta=Vector(end['Hips']['head'])-Vector(start['Hips']['head'])
        closure={name:math.degrees(Vector(values['axis']).angle(Vector(end[name]['axis']))) for name,values in start.items()}
        seated={}
        for label,data in samples.items():
            b=data['bones'];seated[label]={'hips_minus_feet_height':b['Hips']['head'][2]-(b['LeftFoot']['head'][2]+b['RightFoot']['head'][2])/2,'head_minus_hips_height':b['Head']['head'][2]-b['Hips']['head'][2]}
        compatibility={fit:bind_check(source,target) for fit,target in targets.items()}
        record={k:v for k,v in entry.items() if k!='header'}|{'fps':source['fps']/source.get('fps_base',1),'frames':[first,last],'seconds':(last-first)/(source['fps']/source.get('fps_base',1)),'bone_count':len(rig.data.bones),'mesh_count':sum(o.type=='MESH' for o in bpy.context.scene.objects),'actions':actions,'compatibility':compatibility,'samples':samples,'source_hips_end_minus_start':list(delta),'loop_axis_closure_degrees':closure,'pose_height_samples':seated,'loop_approved':False,'in_place_approved':False,'playback_approved':False}
        records.append(record)
        assert hashlib.sha256(path.read_bytes()).hexdigest()==before
        own=compatibility[entry['fit']]
        print('RECEIVED_CLIP',entry['fit'],entry['collection'],entry['name'],'fps',record['fps'],'bones',record['bone_count'],'frames',record['frames'],'bind',own['bind_compatible_candidate'],'angle',round(own.get('max_local_rest_angle_deg',999),3),'pos',round(own.get('max_local_translation_error_source_units',999),4),'lengtherr',round(own.get('max_relative_bone_length_error',999),4),'root',list(round(v,4) for v in delta),flush=True)
    for fit in targets:assert hashlib.sha256((BASE/(fit+'_base.blend')).read_bytes()).hexdigest()==base_hashes[fit]
    (OUT/'library-audit.json').write_text(json.dumps({'files':records,'count':len(records),'source_files_unchanged':True,'base_masters_unchanged':True,'final_animation_approval':False},indent=2)+'\n',encoding='utf-8')
    print('RECEIVED_LIBRARY',len(records),'files; original sources and base masters unchanged',flush=True)
if __name__=='__main__':main()
