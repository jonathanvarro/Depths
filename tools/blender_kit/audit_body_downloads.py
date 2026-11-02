"""#215 incoming per-body FBX bind audit. No source/master writes or approval.

Blender -b --factory-startup --disable-autoexec --python-exit-code 1
--python tools/blender_kit/audit_body_downloads.py -- --probe
"""
import bpy,sys,json,hashlib,math,argparse
from pathlib import Path
from mathutils import Matrix,Vector
sys.dont_write_bytecode=True
sys.path.insert(0,str(Path(__file__).parent))
from audit_sources import scene_report
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'build/local-blender-kit-v1';OUT=BASE/'animation-requests-v1'
REQUIRED=['Idle.fbx','Walking.fbx','Stand To Sit.fbx','Sitting.fbx']
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def read_fbx(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(path),use_image_search=False,automatic_bone_orientation=False)
    report=scene_report();report['sha256']=sha(path);report['fps_base']=bpy.context.scene.render.fps_base
    return report
def bind_check(source,target):
    rigs=[o for o in source['objects'] if o['type']=='ARMATURE']
    if len(rigs)!=1:return {'bind_compatible_candidate':False,'reason':'Expected exactly one supplied skeleton','playback_approved':False}
    rig=rigs[0];s={b['name']:b for b in rig['bones']};t={b['name']:b for b in target['bones']}
    common=set(s)&set(t);missing=sorted(set(t)-set(s));extra=sorted(set(s)-set(t))
    parents=[];max_angle=0;max_translation=0;max_length_error=0;worst=None
    target_scale=Matrix(target['matrix_world']).to_scale().length/math.sqrt(3)
    for name in common:
        a,b=s[name],t[name]
        if a['parent']!=b['parent']:parents.append(name)
        am,bm=Matrix(a['matrix_local']),Matrix(b['matrix_local'])
        if a['parent'] in s:am=Matrix(s[a['parent']]['matrix_local']).inverted()@am
        if b['parent'] in t:bm=Matrix(t[b['parent']]['matrix_local']).inverted()@bm
        angle=math.degrees(am.to_quaternion().rotation_difference(bm.to_quaternion()).angle);angle=min(angle,360-angle)
        if angle>max_angle:max_angle=angle;worst=name
        max_translation=max(max_translation,(am.translation-bm.translation).length*target_scale)
        sl=(Vector(a['tail'])-Vector(a['head'])).length;tl=(Vector(b['tail'])-Vector(b['head'])).length
        if tl>1e-6:max_length_error=max(max_length_error,abs(sl/tl-1))
    sm,tm=Matrix(rig['matrix_world']),Matrix(target['matrix_world'])
    object_error=max(abs(sm[r][c]-tm[r][c]) for r in range(4) for c in range(4))
    fingers_only=all(('HandRing' in n or 'HandPinky' in n) for n in missing)
    actions=source['actions'];has_motion=len(actions)==1 and actions[0]['frame_range'][1]>actions[0]['frame_range'][0]
    fps=source['fps']/source.get('fps_base',1)
    ok=(len(common)>=49 and not extra and not parents and fingers_only and max_angle<.1 and max_translation<.001 and max_length_error<.001 and object_error<.0001 and abs(fps-60)<.01 and has_motion)
    return {'bind_compatible_candidate':ok,'playback_approved':False,'shared_bones':len(common),'missing_target_bones':missing,'source_only_bones':extra,'parent_mismatches':parents,'max_local_rest_angle_deg':max_angle,'worst_angle_bone':worst,'max_local_translation_error_source_units':max_translation,'max_relative_bone_length_error':max_length_error,'object_transform_max_element_error':object_error,'fps':fps,'actions':actions,'finger_policy':'Only missing Ring/Pinky chains may retain their target rest-relative parent articulation; no claim of animated channels for them.','next':'Actual target-slot playback, seated continuity, floor/root checks and independent Blender/Godot export required before acceptance.'}
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--probe',action='store_true')
    # Materialize Drive downloads here with the connector, or supply a readable
    # synced folder explicitly. Do not infer cloud absence from filesystem access.
    for fit in ['female','male']:parser.add_argument('--'+fit+'-dir',type=Path,default=OUT/'incoming'/fit)
    opt=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    OUT.mkdir(exist_ok=True);targets={};hashes={}
    for fit in ['female','male']:
        path=BASE/(fit+'_base.blend');hashes[fit]=sha(path);bpy.ops.wm.open_mainfile(filepath=str(path),load_ui=False,use_scripts=False)
        targets[fit]=next(o for o in scene_report()['objects'] if o['type']=='ARMATURE')
    probes=[]
    if opt.probe:
        for fit in ['female','male']:
            for path,expected in [(BASE/'source'/('Base '+fit.title()+' - Dying.fbx'),True),(BASE/'source/clips/Idle.fbx',False)]:
                result=bind_check(read_fbx(path),targets[fit]);assert result['bind_compatible_candidate']==expected,(fit,path,result)
                probes.append({'fit':fit,'fixture':path.name,'expected_compatible':expected,'observed':result})
    incoming=[];missing=[];access_errors=[]
    for fit in ['female','male']:
        folder=getattr(opt,fit+'_dir')
        for file in REQUIRED:
            path=folder/file
            try:exists=path.is_file()
            except OSError as error:
                access_errors.append({'fit':fit,'file':file,'error':str(error)});continue
            if not exists:missing.append({'fit':fit,'file':file});continue
            record=read_fbx(path);result=bind_check(record,targets[fit]);incoming.append({'fit':fit,'file':file,'sha256':record['sha256'],'audit':result})
    for fit in targets:assert sha(BASE/(fit+'_base.blend'))==hashes[fit]
    status='input_access_unavailable' if access_errors else 'awaiting_downloads' if missing else 'bind_incompatible' if any(not r['audit']['bind_compatible_candidate'] for r in incoming) else 'bind_audit_only_playback_pending'
    result={'required_clips_per_body':REQUIRED,'status':status,'missing':missing,'access_errors':access_errors,'incoming':incoming,'regression_probes':probes,'regression_failures':[],'sources_unchanged':True,'final_animation_approval':False}
    (OUT/'incoming-audit.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print('BODY_DOWNLOAD_AUDIT',len(probes),'regression probes;',len(incoming),'incoming;',len(missing),'missing;',result['status'],flush=True)
if __name__=='__main__':main()
