"""#214: local editable review copies and disjoint, reversible body coverage.

Run with Blender --background --factory-startup --disable-autoexec
--python-exit-code 1 --python tools/blender_kit/prepare_wardrobe.py.
Nothing is saved into source masters. All model/animation output stays ignored.
"""
import bpy,bmesh,sys,json,hashlib,shutil,math
from pathlib import Path
sys.dont_write_bytecode=True
sys.path.insert(0,str(Path(__file__).parent))
from wardrobe_visibility import PIECES,set_pieces
from export_check_garments import points,cloud_error,select
from prepare_masters import digest_rig
from build_garments import skin_digest

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'build/local-blender-kit-v1'
SOURCE=BASE/'garments-v1'
OUT=BASE/'assembly-v1'
checks=0
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def check(ok,label):
    global checks
    checks+=1
    if not ok:raise AssertionError(label)
def bit_for(piece):return 1<<PIECES.index(piece)
def build(fit):
    record=json.loads((SOURCE/(fit+'-manifest.json')).read_text())
    source=SOURCE/record['master'];source_hash=sha(source)
    master=OUT/'masters'/(fit+'_review.blend');master.parent.mkdir(exist_ok=True)
    (master.parent/'.gdignore').touch()
    if master.exists():
        previous=json.loads((OUT/'manifest.json').read_text())['fits'][fit]
        check(sha(master)==previous['master_sha256'],'Preserve manual review-master edits; choose a new output version')
    shutil.copy2(source,master)
    legacy=OUT/(fit+'_review.blend')
    if legacy.exists():
        check(sha(legacy)==source_hash,'Preserve any edits to the first generated review copy')
        legacy.unlink()
    bpy.ops.wm.open_mainfile(filepath=str(master),load_ui=False,use_scripts=False)
    rig=bpy.data.objects['rig.'+fit+'.v1'];body=bpy.data.objects['body.'+fit+'.v1']
    original=rig.animation_data.action;body_name=body.name;rig_hash=digest_rig(rig);skin_hash=skin_digest(body,rig)
    motions=[{'id':'dying','action':original.name,'frames':[1,261],'fps':60,'source':'Base '+fit.title()+' - Dying.fbx','temporary':False}]
    motions += [dict(m,temporary=not record.get('received_profile',False)) for m in record['motions']]
    keep={m['action'] for m in motions}
    for action in list(bpy.data.actions):
        if action.name not in keep:bpy.data.actions.remove(action,do_unlink=True)
    expected_counts=[];expected_clouds=[]
    for mask in range(32):
        set_pieces(fit,{p for i,p in enumerate(PIECES) if mask&(1<<i)})
        ev=body.evaluated_get(bpy.context.evaluated_depsgraph_get());mesh=ev.to_mesh()
        expected_counts.append(sum(len(p.vertices)-2 for p in mesh.polygons));ev.to_mesh_clear()
        expected_clouds.append(points(body))
    set_pieces(fit,PIECES);garments=[o for o in bpy.context.scene.objects if o.get('piece')]
    samples={};full_body_samples={}
    for motion in motions:
        first,last=motion['frames'];samples[motion['id']]={};full_body_samples[motion['id']]={}
        for frame in [first,first+(last-first)*.25+.25,(first+last)/2+.5,last]:
            select(rig,bpy.data.actions[motion['action']],frame)
            samples[motion['id']][frame]={o.name:points(o) for o in [body]+garments}
            mask=body.modifiers['Reversible visible-garment coverage'];mask.show_viewport=False;bpy.context.view_layer.update()
            full_body_samples[motion['id']][frame]=points(body)
            mask.show_viewport=True;bpy.context.view_layer.update()
    rig.data.pose_position='REST';bpy.context.scene.frame_set(1);bpy.context.view_layer.update()
    vertex_bits=[0]*len(body.data.vertices)
    for piece in PIECES:
        if piece=='belt':continue
        group=body.vertex_groups['cover.'+('boots.'+piece.split('.')[1] if piece.startswith('boot.') else piece)]
        for v in body.data.vertices:
            if any(g.group==group.index and g.weight>.5 for g in v.groups):vertex_bits[v.index]|=bit_for(piece)
    face_bits=[]
    for face in body.data.polygons:
        bits=0
        for i in face.vertices:bits|=vertex_bits[i]
        face_bits.append(bits)
    chunks=[];objects=[]
    for bits in sorted(set(face_bits)):
        obj=body.copy();obj.data=body.data.copy();obj.name='body.cover.%02d.%s'%(bits,fit)
        bpy.context.scene.collection.objects.link(obj)
        for mod in list(obj.modifiers):
            if mod.type!='ARMATURE':obj.modifiers.remove(mod)
        bm=bmesh.new();bm.from_mesh(obj.data);bm.faces.ensure_lookup_table()
        bmesh.ops.delete(bm,geom=[f for f in bm.faces if face_bits[f.index]!=bits],context='FACES')
        bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS')
        bm.to_mesh(obj.data);bm.free();obj.data.update();obj.hide_set(False);obj.hide_render=False
        obj.data.calc_loop_triangles();triangles=len(obj.data.loop_triangles)
        chunks.append({'name':obj.name,'hidden_by':bits,'triangles':triangles});objects.append(obj)
    check(digest_rig(rig)==rig_hash and skin_digest(body,rig)==skin_hash,fit+' original geometry/rig intact')
    for mask in range(32):
        selected=[o for o,c in zip(objects,chunks) if not(c['hidden_by']&mask)]
        check(sum(c['triangles'] for c in chunks if not(c['hidden_by']&mask))==expected_counts[mask],fit+' exact Blender coverage triangle count '+str(mask))
        cloud=[p for o in selected for p in points(o)]
        check(cloud_error(expected_clouds[mask],cloud)<1e-5,fit+' same complete visible surface '+str(mask))
    set_pieces(fit,PIECES)
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
    for obj in objects+garments:obj.select_set(True)
    bpy.context.view_layer.objects.active=rig
    select(rig,original,1)
    path=OUT/'assets'/(fit+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_yup=True,
        export_apply=True,export_animations=True,export_animation_mode='ACTIONS',export_frame_range=False,
        export_anim_slide_to_zero=True,export_force_sampling=True,export_frame_step=1,
        export_optimize_animation_size=False,export_rest_position_armature=True,export_current_frame=False,
        export_skins=True,export_all_influences=True,export_influence_nb=8,export_cameras=False,
        export_lights=False,export_extras=True,will_save_settings=False)
    # Independent import proves the partitioned body and all garment deformation.
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.scene.render.fps=60
    bpy.ops.import_scene.gltf(filepath=str(path),import_pack_images=True)
    imported={o.name:o for o in bpy.context.scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers)}
    imported_rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
    check(set(imported)=={c['name'] for c in chunks}|{o for sample in samples.values() for values in sample.values() for o in values if o!=body_name},fit+' complete independent mesh set')
    check(len(imported_rig.data.bones)==(65 if fit=='female' else 49),fit+' full original joint set')
    check(set(bpy.data.actions.keys())==keep,fit+' exact intended motion set')
    imported_rig.data.pose_position='REST';bpy.context.view_layer.update()
    for mask in range(32):
        cloud=[p for c in chunks if not(c['hidden_by']&mask) for p in points(imported[c['name']])]
        check(cloud_error(expected_clouds[mask],cloud)<.001,fit+' imported reversible body surface '+str(mask))
    maximum=0
    for motion in motions:
        for frame,expected in samples[motion['id']].items():
            select(imported_rig,bpy.data.actions[motion['action']],frame-1)
            full_error=cloud_error(full_body_samples[motion['id']][frame],[p for c in chunks for p in points(imported[c['name']])])
            maximum=max(maximum,full_error);check(full_error<.001,fit+' restored entire body deforms exactly '+motion['id']+' '+str(frame))
            for name,cloud in expected.items():
                actual=([p for c in chunks if c['hidden_by']==0 for p in points(imported[c['name']])]
                    if name=='body.'+fit+'.v1' else points(imported[name]))
                error=cloud_error(cloud,actual);maximum=max(maximum,error)
                check(error<.001,fit+' imported motion '+motion['id']+' '+name+' '+str(frame))
    check(sha(source)==source_hash==sha(master),fit+' source and editable copy bytes unchanged')
    return {'fit_id':fit+'-v1','master':master.relative_to(OUT).as_posix(),'master_sha256':sha(master),'source_master':source.relative_to(BASE).as_posix(),
        'source_master_sha256':source_hash,'export':'assets/'+path.name,'export_sha256':sha(path),
        'bones':65 if fit=='female' else 49,'body_chunks':chunks,'body_triangles_by_selection':expected_counts,
        'garments':[{'name':o['name'],'piece':o['piece']} for o in record['garments']],
        'motions':motions,'max_independent_deformation_error':maximum,'per_body_downloads_verified':record.get('received_profile',False),
        'floor_y':min(record['parameters']['boot.'+side]['sole_bottom'] for side in ['left','right'])-.002}

def main():
    (OUT/'assets').mkdir(parents=True,exist_ok=True)
    fits={fit:build(fit) for fit in ['female','male']}
    manifest={'version':1,'pieces':list(PIECES),'fits':fits,'checks':checks,'failures':[],
        'source_art_local_only':True,'final_animation_acceptance_pending':215,
        'sit_transition_continuous':False,'physical_iphone_tested':False}
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    for source,name in [('wardrobe_actor.gd','actor.gd'),('wardrobe_review.gd','review.gd'),('check_wardrobe.gd','check.gd')]:
        shutil.copy2(Path(__file__).with_name(source),OUT/name)
    shutil.copy2(Path(__file__).with_name('display_normalization.json'),OUT/'display_normalization.json')
    (OUT/'project.godot').write_text('''config_version=5
[application]
config/name="Depths · editable kit review"
run/main_scene="res://review.tscn"
[display]
window/size/viewport_width=1278
window/size/viewport_height=590
[input_devices]
pointing/emulate_touch_from_mouse=true
pointing/emulate_mouse_from_touch=true
[rendering]
renderer/rendering_method="mobile"
renderer/rendering_method.mobile="mobile"
rendering_device/driver.windows="d3d12"
''',encoding='utf-8')
    (OUT/'review.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://review.gd" id="1"]\n[node name="WardrobeReview" type="Control"]\nlayout_mode=3\nanchors_preset=15\nanchor_right=1.0\nanchor_bottom=1.0\ngrow_horizontal=2\ngrow_vertical=2\nscript=ExtResource("1")\n',encoding='utf-8')
    exe=ROOT/'build/research-godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe'
    (OUT/'START_REVIEW.cmd').write_text('@echo off\n"'+str(exe)+'" --path "%~dp0." %*\n',encoding='utf-8')
    print('WARDROBE_PREPARED',checks,'checks, no failures; source masters unchanged',flush=True)
if __name__=='__main__':main()
