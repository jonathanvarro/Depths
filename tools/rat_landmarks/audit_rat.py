import bpy, json, argparse, sys
from pathlib import Path
parser=argparse.ArgumentParser();parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
p=args.workspace/'build/local-rat-landmarks-v1'
bpy.ops.wm.open_mainfile(filepath=str(p/'source/rat.blend'),load_ui=False,use_scripts=False)
report={'objects':[],'actions':[],'markers':[]}
for o in bpy.data.objects:
    e={'name':o.name,'type':o.type,'loc':list(o.location),'rotation':list(o.rotation_euler),'scale':list(o.scale)}
    if o.type=='MESH':
        e.update(vertices=len(o.data.vertices),dims=list(o.dimensions),materials=[m.name for m in o.data.materials])
    if o.type=='ARMATURE': e['bones']=[{'name':b.name,'head':list(b.head_local),'tail':list(b.tail_local),'rotation_mode':o.pose.bones[b.name].rotation_mode} for b in o.data.bones]
    report['objects'].append(e)
for a in bpy.data.actions:
    report['actions'].append({'name':a.name,'range':list(a.frame_range),'slots':[s.identifier for s in a.slots]})
report['markers']=[{'name':m.name,'frame':m.frame} for m in bpy.context.scene.timeline_markers]
report['fps']=bpy.context.scene.render.fps
(p/'source-audit.json').write_text(json.dumps(report,indent=2))
print('RAT_AUDIT',json.dumps(report))
