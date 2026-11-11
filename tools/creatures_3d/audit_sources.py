import argparse,bpy,json,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser();parser.add_argument('--workspace',type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
OUT=args.workspace/'build/local-spiders-goblin-v1';OUT.mkdir(parents=True,exist_ok=True)
files={'spider':ROOT/'art/third-party/oga-creatures-v1/spider.blend',
       'goblin':ROOT/'art/third-party/oga-creatures-v1/goblin.blend',
       'goblin-rigged':OUT/'source/rigged-candidate/Goblin.blend'}
for name,path in files.items():
    if not path.exists():
        print('OPTIONAL_CANDIDATE_NOT_PRESENT',name);continue
    bpy.ops.wm.open_mainfile(filepath=str(path),load_ui=False,use_scripts=False)
    report={'fps':bpy.context.scene.render.fps,'objects':[],'actions':[],'images':[]}
    for o in bpy.data.objects:
        entry={'name':o.name,'type':o.type,'parent':o.parent.name if o.parent else None,'location':list(o.location),'scale':list(o.scale),'rotation':list(o.rotation_euler)}
        if o.type=='MESH':
            o.data.calc_loop_triangles()
            entry.update(vertices=len(o.data.vertices),triangles=len(o.data.loop_triangles),size=list(o.dimensions),
                materials=[m.name for m in o.data.materials],modifiers=[{'type':m.type,'name':m.name} for m in o.modifiers],
                groups=[g.name for g in o.vertex_groups])
        if o.type=='ARMATURE':
            entry['bones']=[{'name':b.name,'head':list(b.head_local),'tail':list(b.tail_local),'parent':b.parent.name if b.parent else None,'rotation_mode':o.pose.bones[b.name].rotation_mode,'deform':b.use_deform,'constraints':[{'type':c.type,'name':c.name} for c in o.pose.bones[b.name].constraints]} for b in o.data.bones]
        report['objects'].append(entry)
    for a in bpy.data.actions:
        report['actions'].append({'name':a.name,'range':list(a.frame_range),'slots':[s.identifier for s in a.slots]})
    for i in bpy.data.images:report['images'].append({'name':i.name,'file':i.filepath,'size':list(i.size),'packed':bool(i.packed_file)})
    (OUT/(name+'-audit.json')).write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('SOURCE_AUDIT',name,{'fps':report['fps'],'meshes':[{k:o[k] for k in ['name','vertices','triangles','size','modifiers']} for o in report['objects'] if o['type']=='MESH'],
        'rigs':[(o['name'],len(o['bones'])) for o in report['objects'] if o['type']=='ARMATURE'],'actions':report['actions'],'images':report['images']})
