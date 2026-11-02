"""Real source, garment, coverage, skin and motion checks before export."""
import bpy,sys,json,math,itertools,hashlib
sys.dont_write_bytecode=True
from pathlib import Path
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).parent))
from prepare_masters import digest_rig
from build_garments import skin_digest
from wardrobe_visibility import set_pieces,PIECES
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'build/local-blender-kit-v1';OUT=BASE/'garments-v1'
checks=0;fails=[];reports=[]
def check(ok,label):
    global checks
    checks+=1
    if not ok:fails.append(label);print('FAIL',label,flush=True)
def evaluated(o):
    ev=o.evaluated_get(bpy.context.evaluated_depsgraph_get());m=ev.to_mesh();verts=[ev.matrix_world@v.co for v in m.vertices];edges=[tuple(e.vertices) for e in m.edges];triangles=len(m.loop_triangles) if m.loop_triangles else sum(len(p.vertices)-2 for p in m.polygons);faces=len(m.polygons);ev.to_mesh_clear();return verts,edges,triangles,faces
def select_action(rig,action):rig.animation_data.action=action;rig.animation_data.action_slot=action.slots[0];rig.data.pose_position='POSE'
def main():
    for fit in ['female','male']:
        record=json.loads((OUT/(fit+'-manifest.json')).read_text());bpy.ops.wm.open_mainfile(filepath=str(OUT/record['master']),load_ui=False,use_scripts=False)
        rig=bpy.data.objects['rig.'+fit+'.v1'];body=bpy.data.objects['body.'+fit+'.v1'];original=rig.animation_data.action
        check(hashlib.sha256((BASE/record['source_master']).read_bytes()).hexdigest()==record['source_master_sha256'],fit+' original base master unchanged')
        check(digest_rig(rig)==record['source_rig_digest'],fit+' original hierarchy and rest matrices')
        check(skin_digest(body,rig)==record['source_skin_digest'],fit+' source vertices/UVs/faces/skin unchanged')
        check(rig.data.pose_position=='REST',fit+' saved editable neutral mode')
        check(original.use_fake_user and rig.animation_data.action_slot.identifier=='OBSlot',fit+' original source Action/slot retained')
        items=[o for o in bpy.context.scene.objects if o.get('piece')]
        check({o['piece'] for o in items}==set(PIECES),fit+' all five separate garment selections')
        rest={};totals={'base_triangles':0,'evaluated_triangles':0,'garment_meshes':len(items),'materials':set()}
        source_feet={side:[v.index for v in body.data.vertices if (body.matrix_world@v.co).z<.40 and (body.matrix_world@v.co).x*sign>0] for side,sign in [('left',1),('right',-1)]}
        for o in items:
            check(o.get('fit_id')==fit+'-v1',o.name+' explicit body fit')
            check(o.modifiers[-1].type=='ARMATURE' and o.modifiers[-1].object==rig,o.name+' source Armature remains editable')
            if o.name.startswith('garment.') or 'cuff' in o.name:check(any(m.type=='SOLIDIFY' and m.thickness>0 for m in o.modifiers),o.name+' retained finished thickness')
            for v in o.data.vertices:
                weights=[g.weight for g in v.groups if g.weight>1e-8]
                check(1<=len(weights)<=8 and abs(sum(weights)-1)<1e-5 and all(o.vertex_groups[g.group].name in rig.data.bones for g in v.groups),o.name+' valid normalized skin vertex '+str(v.index))
            coords,edges,tris,faces=evaluated(o);rest[o.name]=(coords,edges);o.data.calc_loop_triangles();totals['base_triangles']+=len(o.data.loop_triangles);totals['evaluated_triangles']+=tris;totals['materials'].update(m.name for m in o.data.materials)
            check(all(p.length<10 and all(math.isfinite(x) for x in p) for p in coords),o.name+' finite fitted rest bounds')
            if o.get('piece')=='tunic':
                check(min(p.z for p in coords)>record['parameters']['tunic']['hem']-.05,o.name+' finished hem has no Solidify corner spike')
        for n in range(32):
            visible={piece for i,piece in enumerate(PIECES) if n&(1<<i)};keep=set_pieces(fit,visible)
            expected=sum(all(i in keep for i in f.vertices) for f in body.data.polygons)
            actual=evaluated(body)[3]
            check(actual==expected,fit+' reversible source coverage combination '+str(n))
        for piece in ['tunic','trousers','boot.left','boot.right']:
            set_pieces(fit,{piece})
            group=body.vertex_groups['coverage.keep']
            keep={v.index for v in body.data.vertices if any(g.group==group.index and g.weight>.5 for g in v.groups)}
            cut={i for f in body.data.polygons if any(i not in keep for i in f.vertices) for i in f.vertices}
            params=record['parameters'][piece]
            if piece=='tunic':low,high=params['hip_opening']-.04,params['neck']
            elif piece=='trousers':low,high=params['ankle']-.04,params['waist']
            else:low,high=-math.inf,params['cuff']
            check(bool(cut) and all(low-1e-5<=(body.matrix_world@body.data.vertices[i].co).z<=high+1e-5 for i in cut),fit+' '+piece+' removed incident faces stay inside garment opening planes')
        set_pieces(fit,());check(evaluated(body)[3]==len(body.data.polygons),fit+' removing everything restores full original body')
        set_pieces(fit,PIECES)
        motion_report=[]
        for clip in record['motions']+[{'id':'dying','action':original.name,'frames':[1,261],'slot':'OBSlot'}]:
            action=bpy.data.actions[clip['action']];select_action(rig,action);first,last=clip['frames'];frames=[first,first+.5,first+(last-first)*.25+.25,(first+last)/2+.5,last-.5,last]
            check(action.use_fake_user and rig.animation_data.action_slot.identifier==clip['slot'],fit+' '+clip['id']+' saved Action/slot retained')
            largest=0;sole_contact=[]
            for frame in frames:
                bpy.context.scene.frame_set(math.floor(frame),subframe=frame%1);bpy.context.view_layer.update()
                mask=body.modifiers['Reversible visible-garment coverage'];mask.show_viewport=False;bpy.context.view_layer.update();source_points=evaluated(body)[0];mask.show_viewport=True;bpy.context.view_layer.update()
                for o in items:
                    points,edges,_,_=evaluated(o);base_points,_=rest[o.name]
                    check(len(points)==len(base_points) and all(all(math.isfinite(x) for x in p) for p in points),fit+' '+clip['id']+' '+o.name+' frame '+str(frame))
                    stretch=max(((points[a]-points[b]).length/(base_points[a]-base_points[b]).length for a,b in edges if (base_points[a]-base_points[b]).length>.035),default=1)
                    largest=max(largest,stretch)
                    check(stretch<3.5,fit+' bounded garment edge stretch '+clip['id']+' '+o.name+' '+str(frame)+' ='+str(round(stretch,3)))
                    if 'detail.sole' in o.name:
                        side='left' if '.left.' in o.name else 'right';lowest=min(p.z for p in points);source_low=min(source_points[i].z for i in source_feet[side]);gap=lowest-source_low
                        check(-.15<gap<.08,fit+' '+clip['id']+' '+side+' sole follows source-foot envelope '+str(round(gap,4)))
                        sole_contact.append({'frame':frame,'object':o.name,'min_z':lowest,'source_foot_min_z':source_low,'sole_minus_source_foot':gap})
            motion_report.append({'id':clip['id'],'action':clip['action'],'frames':frames,'max_edge_stretch':largest,'sole_contact_samples':sole_contact,'floor_ik_added':False})
        check(digest_rig(rig)==record['source_rig_digest'] and skin_digest(body,rig)==record['source_skin_digest'],fit+' repeat preview leaves original rig/skin intact')
        for side in ['left','right']:
            boot=bpy.data.objects['garment.boot.'+side+'.'+fit+'.v1'];names={boot.vertex_groups[g.group].name for v in boot.data.vertices for g in v.groups if g.weight>.05}
            check(any(n.endswith('Leg') for n in names) and any(n.endswith('Foot') for n in names) and any('Toe' in n for n in names),fit+' '+side+' actual shaft/ankle/toe skinning')
        totals['materials']=sorted(totals['materials']);reports.append({'fit':fit,'counts':totals,'motions':motion_report})
    result={'checks':checks,'failures':fails,'reports':reports,'source_root_motion_modified':False,'new_cloth_simulation':False}
    (OUT/'garment-validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print('GARMENT_CHECKS',checks,'checks',len(fails),'failures',flush=True)
    if fails:raise RuntimeError('Garment validation needs fixes')
if __name__=='__main__':main()
