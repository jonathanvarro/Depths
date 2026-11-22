"""New editable seat-fit copies; never overwrite v2 or alter original body/Actions."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import shutil
import sys
import bpy
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[2]
sys.dont_write_bytecode=True
sys.path.insert(0,str(ROOT/'tools/blender_kit'))
sys.path.insert(0,str(Path(__file__).parent))
from export_check_garments import select,points
from validate_jacket import snapshot

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def smooth(t):
    t=max(0,min(1,t));return t*t*(3-2*t)

def clips_box(triangle,low,high):
    polygon=list(triangle)
    for axis in range(3):
        for edge,sign in [(low[axis],1),(high[axis],-1)]:
            result=[]
            for a,b in zip(polygon,polygon[1:]+polygon[:1]):
                da=(a[axis]-edge)*sign;db=(b[axis]-edge)*sign
                if da>=0:result.append(a)
                if (da>=0)!=(db>=0):result.append(a.lerp(b,da/(da-db)))
            polygon=result
            if not polygon:return False
    return True

def seat_audit(rig,shell,record,scale,step=3):
    clips={m['id']:m for m in record['motions']}
    hip=rig.pose.bones['mixamorig:Hips']
    def hips():return rig.matrix_world@hip.head
    first=clips['sit_down'];select(rig,bpy.data.actions[first['action']],first['frames'][1])
    end=hips();centre=end.copy();centre.y-=.025/scale
    seat_z=record['floor_y']+.43/scale
    low=Vector((centre.x-.20/scale,centre.y-.16/scale,seat_z-.026/scale))
    high=Vector((centre.x+.20/scale,centre.y+.16/scale,seat_z-.0005/scale))
    offsets={};previous=None;rows=[]
    for name in ['sit_down','seated','stand_up']:
        m=clips[name];a=bpy.data.actions[m['action']];start,last=m['frames']
        select(rig,a,start);offset=Vector((0,0,0)) if previous is None else previous-hips();offset.z=0
        offsets[name]=offset
        select(rig,a,last);previous=hips()+offset
        for frame in range(int(start),int(last)+1,step):
            select(rig,a,frame)
            cloud=[p+offset for p in points(shell)]
            # A clear diagnostic volume, not a closed-body hand/leg inside test.
            inside=[p for p in cloud if abs(p.x-centre.x)<.198/scale and abs(p.y-centre.y)<.158/scale
                    and seat_z-.045/scale<p.z<seat_z+.005/scale]
            ev=shell.evaluated_get(bpy.context.evaluated_depsgraph_get());mesh=ev.to_mesh();mesh.calc_loop_triangles()
            pts=[shell.matrix_world@v.co+offset for v in mesh.vertices]
            intersections=sum(clips_box([pts[i] for i in tri.vertices],low,high) for tri in mesh.loop_triangles
                if all(max(pts[i][axis] for i in tri.vertices)>=low[axis] and min(pts[i][axis] for i in tri.vertices)<=high[axis] for axis in range(3)))
            ev.to_mesh_clear()
            rows.append({'motion':name,'frame':frame,'seat_band_vertices':len(inside),'seat_intersections':intersections})
    return {'seat_metres':.43,'seat_centre_source':list(centre),'seat_top_source':seat_z,
            'samples':rows,'maximum_seat_band_vertices':max(x['seat_band_vertices'] for x in rows),
            'maximum_seat_intersections':max(x['seat_intersections'] for x in rows),
            'note':'Diagnostic seat band; actual side/front/back renders decide contact acceptance.'}

def main():
    p=argparse.ArgumentParser();p.add_argument('--workspace',type=Path,required=True)
    args=p.parse_args(sys.argv[sys.argv.index('--')+1:])
    source=args.workspace/'build/local-padded-jacket-v2';out=args.workspace/'build/local-companion-polish-v1'
    for name in ['editable','textures','assets','export-inputs','review']:(out/name).mkdir(parents=True,exist_ok=True)
    for name in ['editable','masters','export-inputs']:
        (out/name).mkdir(exist_ok=True);(out/name/'.gdignore').touch()
    original=json.loads((source/'construction.json').read_text(encoding='utf-8'))
    scale=json.loads((source/'display_normalization.json').read_text())['source_unit_to_metres']
    data=dict(original);data['fits']={};audits={}
    for fit,record in original['fits'].items():
        master=Path(record['master']);assert sha(master)==record['master_sha256']
        bpy.ops.wm.open_mainfile(filepath=str(master),load_ui=False,use_scripts=False)
        before=snapshot(fit);rig=bpy.data.objects['rig.'+fit+'.v1']
        original_action=rig.animation_data.action
        shell=bpy.data.objects['garment.padded-jacket.'+fit+'.v2']
        prior=seat_audit(rig,shell,record,scale)
        rig.data.pose_position='REST';bpy.context.view_layer.update()
        hip=rig.matrix_world@rig.data.bones['mixamorig:Hips'].head_local
        changed=0
        # Keep the front skirt, but shorten the back and side panels into a
        # riding-jacket cut. Compress the low rings smoothly rather than moving
        # only the bottom row through its neighbours; UVs and weights stay intact.
        for obj in [o for o in bpy.context.scene.objects if o.get('outfit')=='jacket']:
            if obj.get('piece')=='belt':continue
            for v in obj.data.vertices:
                pworld=obj.matrix_world@v.co
                dz=pworld.z-hip.z
                if dz>=.35:continue
                back=.74+.26*smooth((pworld.y-hip.y+.20)/.23)
                lift=max(0,.35-dz)*.82*back
                if lift>0:
                    pworld.z+=lift;v.co=obj.matrix_world.inverted()@pworld;changed+=1
                    if obj==shell:
                        for group in obj.vertex_groups:group.remove([v.index])
                        spine=.35*smooth((pworld.y-hip.y+.10)/.18)
                        for name,weight in [('mixamorig:Hips',1-spine),('mixamorig:Spine',spine)]:
                            if weight:
                                group=obj.vertex_groups.get(name) or obj.vertex_groups.new(name=name)
                                group.add([v.index],weight,'REPLACE')
            obj.data.update()
        # The shorter hem must reveal the waist when trousers are removed.
        # Only the reversible visibility tag changes; skin geometry, UVs and
        # actual bone weights remain byte-identical in the snapshot below.
        body=bpy.data.objects['body.'+fit+'.v1'];coverage=body.vertex_groups['cover.tunic']
        reveal=[v.index for v in body.data.vertices if (body.matrix_world@v.co).z<hip.z+.40]
        coverage.remove(reveal)
        after=snapshot(fit)
        assert {k:v for k,v in before.items() if k!='body'}=={k:v for k,v in after.items() if k!='body'},'Body skin, rig, UVs, bone weights, original garments or Actions changed'
        rig.data.pose_position='POSE';bpy.context.view_layer.update()
        audit=seat_audit(rig,shell,record,scale,1)
        assert audit['maximum_seat_intersections']==0,'Jacket still crosses the fixed seat; inspect the diagnostic before delivery'
        audits[fit]={'before':prior,'after':audit,'changed_jacket_vertices':changed,
                    'waist_coverage_reveal_vertices':len(reveal),'preserved_source_snapshot':before,
                    'body_visibility_only_digest':after['body']}
        rig.animation_data.action=original_action;rig.animation_data.action_slot=original_action.slots[0]
        rig.data.pose_position='REST';bpy.context.scene.frame_set(1);bpy.context.view_layer.update()
        target=out/'editable'/(fit+'_seat-fit.blend')
        bpy.ops.wm.save_as_mainfile(filepath=str(target))
        r=dict(record,master=str(target),master_sha256=sha(target),jacket_v2_master=str(master),jacket_v2_sha256=sha(master))
        data['fits'][fit]=r
        print('SEAT_FIT',fit,'changed',changed,'seat intersections',prior['maximum_seat_intersections'],'->',audit['maximum_seat_intersections'],flush=True)
    data['polish']='Shorter back/side hem on editable masters; source body, rigs, original garments and Actions preserved'
    (out/'construction.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
    (out/'seat-fit-validation.json').write_text(json.dumps(audits,indent=2)+'\n',encoding='utf-8')
    for name in ['project.godot','review.tscn','actor_base.gd','review_base.gd','actor.gd','review.gd','display_normalization.json']:
        shutil.copy2(source/name,out/name)
    for file in (source/'textures').glob('*'):shutil.copy2(file,out/'textures'/file.name)

if __name__=='__main__':main()
