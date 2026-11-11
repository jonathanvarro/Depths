"""Record evaluated Blender bone positions and bounds for native export checks."""
import argparse,bpy,json,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser();parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
OUT=args.workspace/'build/local-spiders-goblin-v1';ART=ROOT/'art/enemies/field-creatures-3d-v1'
catalog=json.loads((ART/'catalog.json').read_text(encoding='utf-8'));report={}
def game(v):return [v.x,v.z,-v.y]
for entry in catalog['assets']:
    name=entry['id'];bpy.ops.wm.open_mainfile(filepath=str(OUT/'masters'/(name+'.blend')),load_ui=False,use_scripts=False)
    rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
    meshes=[o for o in bpy.data.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers)]
    bones=['head','hand_R','hand_L','foot_R','foot_L','spine3'] if name=='goblin' else ['thorax','abdomen','leg1_R.002','leg1_L.002','leg4_R.003','leg4_L.003']
    clips={}
    for action in bpy.data.actions:
        rig.animation_data.action=action;rig.animation_data.action_slot=action.slots[0]
        samples=[]
        for ratio in [0,.25,.5,.75,1]:
            t=action.frame_range[0]+(action.frame_range[1]-action.frame_range[0])*ratio
            bpy.context.scene.frame_set(int(t),subframe=t-int(t));bpy.context.view_layer.update()
            points=[]
            for obj in meshes:
                ev=obj.evaluated_get(bpy.context.evaluated_depsgraph_get());points.extend(obj.matrix_world@v.co for v in ev.data.vertices)
            low=[min(game(p)[i] for p in points) for i in range(3)];high=[max(game(p)[i] for p in points) for i in range(3)]
            samples.append({'ratio':ratio,'seconds':t/24,'bones':{b:game(rig.matrix_world@rig.pose.bones[b].matrix.translation) for b in bones},'low':low,'high':high})
        clips[action.name]=samples
    report[name]=clips
(ART/'reference-poses.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('REFERENCE_POSES',len(report),sum(len(v) for v in report.values()))
