"""Export a saved working kit without saving/overwriting its .blend file.

Blender -b <working.blend> -P export_current.py -- --name my-kit
Only local ignored output; garment fits/weights must already be authored.
"""
import bpy,sys,argparse
sys.dont_write_bytecode=True
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/local-blender-kit-v1'
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
p=argparse.ArgumentParser();p.add_argument('--name',required=True);p.add_argument('--replace',action='store_true');opt=p.parse_args(args)
if not opt.name or any(c not in 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_' for c in opt.name):raise ValueError('Use a simple output name, not a path.')
if opt.name in ['female_base','male_base']:raise ValueError('Keep the verified base exports separate; choose a working-kit name.')
fit=bpy.context.scene.get('fit_id','');rigs=[o for o in bpy.context.scene.objects if o.type=='ARMATURE' and o.get('fit_id')==fit]
if len(rigs)!=1:raise ValueError('Expected the one authoritative fit rig.')
rig=rigs[0];meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.visible_get() and not o.hide_render and o.get('fit_id')==fit]
garment_profile=bpy.context.scene.get('garment_contract')=='depths-expedition-garments-v1'
if garment_profile:
    sys.path.insert(0,str(Path(__file__).parent))
    from wardrobe_visibility import set_pieces
    set_pieces(fit.split('-')[0],{o['piece'] for o in meshes if o.get('piece')})
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.visible_get() and not o.hide_render and o.get('fit_id')==fit]
if not meshes:raise ValueError('No visible meshes with the scene fit_id.')
for o in meshes:
    if not any(m.type=='ARMATURE' and m.object==rig for m in o.modifiers):raise ValueError('Visible kit mesh needs this fit rig: '+o.name)
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
for o in meshes:o.select_set(True)
bpy.context.view_layer.objects.active=rig;rig.data.pose_position='POSE'
target=(OUT/'garments-v1' if garment_profile else OUT)/'exports'/(opt.name+'.glb');target.parent.mkdir(exist_ok=True)
if target.exists() and not opt.replace:raise ValueError('Output exists; choose another name or explicitly add --replace.')
bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,export_yup=True,export_apply=garment_profile,export_animations=bool(rig.animation_data and rig.animation_data.action),export_animation_mode='ACTIVE_ACTIONS',export_frame_range=False,export_anim_slide_to_zero=True,export_force_sampling=True,export_frame_step=1,export_rest_position_armature=True,export_current_frame=False,export_skins=True,export_all_influences=True,export_influence_nb=8,export_cameras=False,export_lights=False,export_extras=True,will_save_settings=False)
print('KIT_CURRENT_EXPORT',target,'(source .blend not saved)',flush=True)
