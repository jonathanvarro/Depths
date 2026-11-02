"""Catalogue supplied clips and measure rest compatibility, without retargeting."""
import bpy,sys,json,math,hashlib
sys.dont_write_bytecode=True
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
from audit_sources import scene_report
from mathutils import Matrix
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/local-blender-kit-v1'
def main():
    bases=json.loads((OUT/'source-audit.json').read_text(encoding='utf-8'))['sources'];records=[]
    for p in sorted((OUT/'source/clips').glob('*.fbx')):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.fbx(filepath=str(p),use_image_search=False,automatic_bone_orientation=False)
        record=scene_report();rig=next((o for o in record['objects'] if o['type']=='ARMATURE'),None)
        record.update({'file':p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'compatibility':{}})
        if rig:
            source={b['name']:b for b in rig['bones']}
            for fit in ['female','male']:
                base=next(s for s in bases if s['file']=='Base '+fit.title()+' - Dying.fbx');target_rig=next(o for o in base['objects'] if o['type']=='ARMATURE');target={b['name']:b for b in target_rig['bones']}
                shared=sorted(source.keys()&target.keys());angles=[];ratios=[];parents=[]
                for name in shared:
                    a=Matrix(source[name]['matrix_local']);b=Matrix(target[name]['matrix_local'])
                    # Compare parent-relative basis, matching local Action channels.
                    ap=source[name]['parent'];bp=target[name]['parent']
                    if ap!=bp:parents.append(name)
                    if ap in source:a=Matrix(source[ap]['matrix_local']).inverted()@a
                    if bp in target:b=Matrix(target[bp]['matrix_local']).inverted()@b
                    angle=math.degrees(a.to_quaternion().rotation_difference(b.to_quaternion()).angle);angles.append((min(angle,360-angle),name))
                    av=Matrix(source[name]['matrix_local']).translation;bv=Matrix(target[name]['matrix_local']).translation
                    # Actual bone length ratio, not root-position scale assumptions.
                    from mathutils import Vector
                    la=(Vector(source[name]['tail'])-Vector(source[name]['head'])).length;lb=(Vector(target[name]['tail'])-Vector(target[name]['head'])).length
                    if la>1e-5:ratios.append(lb/la)
                worst=sorted(angles,reverse=True)[:8];max_angle=worst[0][0] if worst else 0
                record['compatibility'][fit]={'shared_bones':len(shared),'source_only':sorted(source.keys()-target.keys()),'target_only':sorted(target.keys()-source.keys()),'parent_mismatches':parents,'max_local_rest_angle_deg':max_angle,'worst_angles':worst,'length_ratio_range':[min(ratios),max(ratios)] if ratios else [],'direct_assignment_approved':False,'reason':'Rest/length audit only. Any cross-rig assignment needs target-space sampling and visual review; matching names are insufficient.'}
        records.append(record);print('KIT_CLIP',p.name,len(rig['bones']) if rig else 0,[(a['frame_range']) for a in record['actions']],flush=True)
    (OUT/'clip-audit.json').write_text(json.dumps({'clips':records},indent=2)+'\n',encoding='utf-8')
if __name__=='__main__':main()
