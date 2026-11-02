"""Self-contained candidates and independent rest/motion/material round trips."""
import bpy,sys,json,hashlib,math
sys.dont_write_bytecode=True
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
from check_and_export import cloud_error
from wardrobe_visibility import set_pieces,PIECES
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/local-blender-kit-v1/garments-v1'
checks=0;fails=[]
def points(obj):
    ev=obj.evaluated_get(bpy.context.evaluated_depsgraph_get());mesh=ev.to_mesh()
    # A Mask may leave unreferenced vertices. glTF correctly omits those;
    # compare the actual face surface on both sides, including every face.
    used={i for face in mesh.polygons for i in face.vertices}
    result=[ev.matrix_world@mesh.vertices[i].co for i in sorted(used)]
    ev.to_mesh_clear();return result
def check(ok,label):
    global checks
    checks+=1
    if not ok:fails.append(label);print('FAIL',label,flush=True)
def select(rig,action,frame):
    rig.animation_data.action=action;rig.animation_data.action_slot=action.slots[0];rig.data.pose_position='POSE';bpy.context.scene.frame_set(math.floor(frame),subframe=frame%1);bpy.context.view_layer.update()
def run_fit(fit):
    record=json.loads((OUT/(fit+'-manifest.json')).read_text());bpy.ops.wm.open_mainfile(filepath=str(OUT/record['master']),load_ui=False,use_scripts=False)
    rig=bpy.data.objects['rig.'+fit+'.v1'];original=rig.animation_data.action;body=bpy.data.objects['body.'+fit+'.v1'];set_pieces(fit,PIECES)
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];actions=[{'id':'dying','action':original.name,'frames':[1,261]}]+record['motions']
    keep={a['action'] for a in actions}
    for action in list(bpy.data.actions):
        if action.name not in keep:bpy.data.actions.remove(action,do_unlink=True)
    rig.data.pose_position='REST';bpy.context.view_layer.update();rest={o.name:points(o) for o in meshes};samples={}
    for clip in actions:
        first,last=clip['frames'];frames=[first,first+(last-first)*.25+.25,(first+last)/2+.5,last]
        samples[clip['action']]={}
        for frame in frames:
            select(rig,bpy.data.actions[clip['action']],frame)
            samples[clip['action']][str(frame)]={o.name:points(o) for o in meshes}
    select(rig,original,1)
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
    for o in meshes:o.select_set(True)
    bpy.context.view_layer.objects.active=rig;target=OUT/'exports'/(fit+'_kit.glb');target.parent.mkdir(exist_ok=True)
    # Bake editable non-armature modifiers for engine output, not into masters.
    bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,export_yup=True,export_apply=True,export_animations=True,export_animation_mode='ACTIONS',export_frame_range=False,export_anim_slide_to_zero=True,export_force_sampling=True,export_frame_step=1,export_optimize_animation_size=False,export_rest_position_armature=True,export_current_frame=False,export_skins=True,export_all_influences=True,export_influence_nb=8,export_cameras=False,export_lights=False,export_extras=True,will_save_settings=False)
    parts=[]
    for name,pieces in [('tunic-belt',{'tunic','belt'}),('trousers',{'trousers'}),('boots',{'boot.left','boot.right'})]:
        bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
        selected=[o for o in meshes if o.get('piece') in pieces]
        for o in selected:o.select_set(True)
        bpy.context.view_layer.objects.active=rig;part=target.with_name(fit+'-'+name+'.glb')
        bpy.ops.export_scene.gltf(filepath=str(part),export_format='GLB',use_selection=True,export_yup=True,export_apply=True,export_animations=True,export_animation_mode='ACTIONS',export_frame_range=False,export_anim_slide_to_zero=True,export_force_sampling=True,export_frame_step=1,export_rest_position_armature=True,export_current_frame=False,export_skins=True,export_all_influences=True,export_influence_nb=8,export_cameras=False,export_lights=False,export_extras=True,will_save_settings=False)
        parts.append({'name':name,'file':part.relative_to(OUT).as_posix(),'meshes':len(selected),'body_included':False,'sha256':hashlib.sha256(part.read_bytes()).hexdigest()})
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.scene.render.fps=60;bpy.ops.import_scene.gltf(filepath=str(target),import_pack_images=True)
    # Blender can create an Icosphere bone-widget helper on multi-Action import;
    # it is not a glTF mesh node. Compare all actual skinned model meshes.
    imported={o.name:o for o in bpy.context.scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers)};rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
    check(set(imported)==set(rest),fit+' all independent garment/body objects round trip')
    check(len(rig.data.bones)==(65 if fit=='female' else 49),fit+' full source rig retained')
    action_map={a.name:a for a in bpy.data.actions};check(set(action_map)==keep,fit+' exactly five intended source/retargeted Actions')
    rig.data.pose_position='REST';bpy.context.view_layer.update();max_rest=0
    for name,o in imported.items():
        error=cloud_error(rest[name],points(o));max_rest=max(max_rest,error);check(error<.001,fit+' '+name+' exact masked/thick rest export '+str(round(error,6)))
        check(all(m is not None for m in o.data.materials),fit+' '+name+' material survives')
    maximum=0
    for action,frames in samples.items():
        if action not in action_map:continue
        for frame,objects in frames.items():
            select(rig,action_map[action],float(frame)-1)
            for name,expected in objects.items():
                error=cloud_error(expected,points(imported[name]));maximum=max(maximum,error);check(error<.015,fit+' '+name+' '+action+' frame '+frame+' error '+str(round(error,6)))
    check(hashlib.sha256((OUT/record['master']).read_bytes()).hexdigest()==record['sha256'],fit+' export never saves/bakes the editable master')
    report={'fit':fit,'export':target.relative_to(OUT).as_posix(),'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'mesh_count':len(imported),'actions':sorted(keep),'max_rest_error':max_rest,'max_motion_error':maximum,'all_art_local':True,'parts':parts}
    print('GARMENT_EXPORT',fit,max_rest,maximum,flush=True);return report
def main():
    reports=[run_fit(f) for f in ['female','male']];(OUT/'export-validation.json').write_text(json.dumps({'checks':checks,'failures':fails,'reports':reports},indent=2)+'\n',encoding='utf-8');print('GARMENT_EXPORT_CHECK',checks,'checks',len(fails),'failures',flush=True)
    if fails:raise RuntimeError('Export round trip needs correction')
if __name__=='__main__':main()
