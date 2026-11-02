from pathlib import Path
import json,struct,shutil
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/local-blender-kit-v1/garments-v1';TARGET=OUT/'godot-smoke';TARGET.mkdir(exist_ok=True)
summary={}
for fit in ['female','male']:
    source=OUT/'exports'/(fit+'_kit.glb');data=source.read_bytes();length=struct.unpack_from('<I',data,12)[0];gltf=json.loads(data[20:20+length]);shutil.copy2(source,TARGET/source.name)
    triangles=sum(gltf['accessors'][p['indices']]['count']//3 for m in gltf['meshes'] for p in m['primitives'])
    summary[fit]={'bones':65 if fit=='female' else 49,'triangles':triangles,'meshes':len(gltf['meshes'])}
shutil.copy2(Path(__file__).with_name('garment_godot_check.gd'),TARGET/'check.gd')
(TARGET/'project.godot').write_text('[application]\nconfig/name="Depths local garment smoke"\n[rendering]\nrenderer/rendering_method="mobile"\nrenderer/rendering_method.mobile="mobile"\nrendering_device/driver.windows="d3d12"\n',encoding='utf-8')
(TARGET/'summary.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
print('GARMENT_GODOT_PROJECT',summary)
