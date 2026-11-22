"""Independent reopen/lineage checks and garment-only portable exports (#220).

Blender --background --factory-startup --disable-autoexec --python-exit-code 1
--python validate_jacket.py -- --workspace E:/GitHub/Depths
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy

sys.dont_write_bytecode=True
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/blender_kit'))
from prepare_masters import digest_geometry,digest_rig
from build_garments import skin_digest


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def action_digest(action):
    data={'name':action.name,'slots':[(s.identifier,s.handle,s.target_id_type) for s in action.slots],'layers':[]}
    for layer in action.layers:
        strips=[]
        for strip in layer.strips:
            strips.append([(bag.slot_handle,[(c.data_path,c.array_index,c.extrapolation,
                [(list(k.co),list(k.handle_left),list(k.handle_right),k.interpolation,k.handle_left_type,k.handle_right_type) for k in c.keyframe_points])
                for c in bag.fcurves]) for bag in getattr(strip,'channelbags',[])])
        data['layers'].append(strips)
    return hashlib.sha256(json.dumps(data,sort_keys=True).encode()).hexdigest()


def snapshot(fit):
    rig=bpy.data.objects['rig.'+fit+'.v1'];body=bpy.data.objects['body.'+fit+'.v1']
    return {'rig':digest_rig(rig),'skin':skin_digest(body,rig),'body':digest_geometry(body),
            'actions':{a.name:action_digest(a) for a in bpy.data.actions},
            'garments':{o.name:digest_geometry(o) for o in bpy.context.scene.objects if o.get('piece') and o.get('outfit','tunic')!='jacket'}}


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--workspace',type=Path,required=True)
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
    out=args.workspace/'build/local-padded-jacket-v2';data=json.loads((out/'construction.json').read_text())
    results={};checks=0
    for fit,r in data['fits'].items():
        source=Path(r['source_master']);master=Path(r['master'])
        assert sha(source)==r['source_master_sha256'] and sha(master)==r['master_sha256'];checks+=2
        bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False,use_scripts=False);before=snapshot(fit)
        bpy.ops.wm.open_mainfile(filepath=str(master),load_ui=False,use_scripts=False);after=snapshot(fit)
        assert before==after,'Original rig/body/UV/weights/garments/Action keys changed';checks+=5+len(before['actions'])+len(before['garments'])
        rig=bpy.data.objects['rig.'+fit+'.v1'];rig.data.pose_position='REST'
        garments=[o for o in bpy.context.scene.objects if o.get('outfit')=='jacket']
        assert len(garments)==4,'Shell, construction and jacket-specific belt/buckle';checks+=1
        for o in garments:
            for v in o.data.vertices:
                assert all(math.isfinite(x) for x in v.co);checks+=1
                weights=[g.weight for g in v.groups if o.vertex_groups[g.group].name in rig.data.bones]
                assert weights and len(weights)<=8 and abs(sum(weights)-1)<.0001;checks+=1
            assert sum(m.type=='ARMATURE' for m in o.modifiers)==1;checks+=1
        shell=next(o for o in garments if o.name.startswith('garment.padded-jacket'))
        assert shell.data.uv_layers and all(0<=x<=1 for loop in shell.data.uv_layers.active.data for x in loop.uv);checks+=1
        # Jacket-only GLB: no body, face, old tunic or animation data; original
        # skeleton retained so the caller can bind it to this exact fit family.
        bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
        for o in garments:o.hide_set(False);o.select_set(True)
        bpy.context.view_layer.objects.active=rig
        target=out/'assets'/(fit+'-jacket-only.glb')
        bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,export_yup=True,
            export_apply=True,export_animations=False,export_skins=True,export_all_influences=True,
            export_influence_nb=8,export_extras=True,export_cameras=False,export_lights=False,will_save_settings=False)
        names={o.name for o in garments}
        bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(target),import_pack_images=True)
        # Blender may create an unskinned Icosphere for bone-display widgets;
        # it is not a glTF model surface. Check actual skin meshes.
        imported={o.name for o in bpy.context.scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers)}
        assert imported==names,(imported,names);checks+=1
        assert len(next(o for o in bpy.context.scene.objects if o.type=='ARMATURE').data.bones)==(65 if fit=='female' else 49);checks+=1
        assert not bpy.data.actions;checks+=1
        assert sha(source)==r['source_master_sha256'] and sha(master)==r['master_sha256'];checks+=2
        results[fit]={'source_snapshot':before,'jacket_only_export':str(target),'sha256':sha(target)}
    (out/'lineage-validation.json').write_text(json.dumps({'checks':checks,'failures':[],'fits':results},indent=2)+'\n')
    print('JACKET_LINEAGE',checks,'checks, 0 failures',flush=True)


if __name__=='__main__':main()
