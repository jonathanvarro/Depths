"""Independent reopen, source-motion comparison and GLB round-trip smoke test."""
import bpy,sys,json,hashlib,math
sys.dont_write_bytecode=True
from pathlib import Path
from mathutils import Vector
from mathutils.kdtree import KDTree
sys.path.insert(0,str(Path(__file__).parent))
from prepare_masters import digest_geometry,digest_rig
from audit_sources import points_bbox,action_report
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/local-blender-kit-v1'
checks=[];failures=[]
FRAMES=[1,32.5,65.5,131,195.5,261]
def check(ok,label):
    checks.append(label)
    if not ok:failures.append(label);print('FAIL',label,flush=True)
def points(o):
    deps=bpy.context.evaluated_depsgraph_get();ev=o.evaluated_get(deps);m=ev.to_mesh()
    p=[ev.matrix_world@v.co for v in m.vertices];ev.to_mesh_clear();return p
def sample(o,frames):
    result={}
    for frame in frames:
        whole=math.floor(frame);bpy.context.scene.frame_set(whole,subframe=frame-whole);bpy.context.view_layer.update()
        result[str(frame)]=points(o)
    return result
def cloud_error(a,b):
    if not a or not b:return 1e9
    def directed(x,y):
        tree=KDTree(len(y))
        for i,p in enumerate(y):tree.insert(p,i)
        tree.balance();return max(tree.find(p)[2] for p in x)
    return max(directed(a,b),directed(b,a))
def run_fit(record):
    fit=record['fit_id'].split('-')[0];path=OUT/record['master'];bpy.ops.wm.open_mainfile(filepath=str(path),load_ui=False,use_scripts=False)
    rig=bpy.data.objects['rig.'+fit+'.v1'];body=bpy.data.objects['body.'+fit+'.v1'];scene=bpy.context.scene
    check(hashlib.sha256(path.read_bytes()).hexdigest()==record['master_sha256'],fit+' master hash')
    check(digest_rig(rig)==record['rig_sha256'],fit+' source rest/hierarchy retained after reopen')
    check(digest_geometry(body)==record['geometry_sha256'],fit+' mesh/UV/weights retained after reopen')
    check(rig.data.pose_position=='REST',fit+' opens in neutral rest mode')
    check(rig.animation_data.action.name==record['source_action_name'],fit+' existing source Action retained')
    check(rig.animation_data.action_slot.identifier=='OBSlot',fit+' source Action slot restored')
    check(rig.animation_data.action.use_fake_user,fit+' Action survives unused/rest save')
    check(all(bpy.data.materials.get(n) for n in ['cloth.tunic','cloth.trousers','leather.boots','leather.belt']),fit+' shared material palette retained')
    check(all(body.vertex_groups.get(n) for n in ['cover.tunic','cover.trousers','cover.boots']),fit+' reversible coverage convention')
    check(not any(m.type=='MASK' for m in body.modifiers),fit+' full source body still present')
    for image in bpy.data.images:
        check(bool(image.packed_file) and image.size[0]>0,fit+' portable image '+image.name)
    rest=points(body);rig.data.pose_position='POSE';master_samples=sample(body,FRAMES)
    check(cloud_error(master_samples['1'],master_samples['131'])>.1,fit+' existing Action genuinely deforms body')
    # Independently reimport the true source, instead of comparing only a file
    # against a fingerprint produced by the same preparation code.
    before=set(scene.objects);bpy.ops.import_scene.fbx(filepath=str(OUT/'source'/record['source']),use_image_search=False,automatic_bone_orientation=False)
    added=set(scene.objects)-before;reference=next(o for o in added if o.type=='MESH');reference_rig=next(o for o in added if o.type=='ARMATURE')
    reference_rig.data.pose_position='POSE';reference_samples=sample(reference,FRAMES)
    for frame in FRAMES:check(cloud_error(master_samples[str(frame)],reference_samples[str(frame)])<1e-5,fit+' source motion exact at '+str(frame))
    for o in added:bpy.data.objects.remove(o,do_unlink=True)
    # Export only the intended rig/body, excluding template palettes/helpers.
    scene.frame_set(1);bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);body.select_set(True);bpy.context.view_layer.objects.active=rig
    target=OUT/'exports'/(fit+'_base.glb');target.parent.mkdir(exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,export_yup=True,export_apply=False,export_animations=True,export_animation_mode='ACTIVE_ACTIONS',export_frame_range=False,export_anim_slide_to_zero=True,export_force_sampling=True,export_frame_step=1,export_optimize_animation_size=False,export_rest_position_armature=True,export_current_frame=False,export_skins=True,export_all_influences=True,export_influence_nb=8,export_cameras=False,export_lights=False,export_extras=True,will_save_settings=False)
    # A fresh scene/60fps import: glTF seconds0..4.333 map to Blender0..260.
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.scene.render.fps=60
    bpy.ops.import_scene.gltf(filepath=str(target),import_pack_images=True)
    imported=next(o for o in bpy.context.scene.objects if o.type=='MESH');imported_rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
    check(len(imported_rig.data.bones)==len(next(o for o in record['objects'] if o['type']=='ARMATURE')['bones']),fit+' GLB retains full joint set')
    check(imported_rig.animation_data and imported_rig.animation_data.action is not None,fit+' GLB Action reimports')
    imported_rig.data.pose_position='REST';neutral=points(imported)
    check(cloud_error(rest,neutral)<1e-4,fit+' GLB bind/rest geometry round-trip')
    imported_rig.data.pose_position='POSE';samples=sample(imported,[f-1 for f in FRAMES])
    max_error=0
    for frame in FRAMES:
        error=cloud_error(master_samples[str(frame)],samples[str(frame-1)]);max_error=max(max_error,error)
        check(error<.012,fit+' GLB motion round-trip at '+str(frame)+' error '+str(round(error,6)))
    return {'fit_id':record['fit_id'],'export':target.relative_to(OUT).as_posix(),'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'rest_bbox':points_bbox(rest),'source_motion_frames':FRAMES,'glb_max_cloud_error_units':max_error,'imported_action':action_report(imported_rig.animation_data.action)}
def main():
    manifest=json.loads((OUT/'kit-manifest.json').read_text(encoding='utf-8'));reports=[]
    for entry in manifest['sources']:
        check(hashlib.sha256((OUT/entry['file']).read_bytes()).hexdigest()==entry['sha256'],'Copied source unchanged '+entry['file'])
    for record in manifest['fits']:reports.append(run_fit(record))
    result={'checks':len(checks),'failures':failures,'reports':reports,'blender':bpy.app.version_string,'samples_include_between_keys':True}
    (OUT/'blender-validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print('KIT_BLENDER_CHECK',len(checks),'checks,',len(failures),'failures',flush=True)
    if failures:raise RuntimeError('Blender kit checks failed; see local validation JSON')
if __name__=='__main__':main()
