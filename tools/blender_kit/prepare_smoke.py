"""Copy local exports into a tiny isolated Godot import-check project."""
from pathlib import Path
import json,shutil
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/local-blender-kit-v1';TARGET=OUT/'godot-smoke'
TARGET.mkdir(exist_ok=True)
for fit in ['female','male']:shutil.copy2(OUT/'exports'/(fit+'_base.glb'),TARGET/(fit+'_base.glb'))
shutil.copy2(Path(__file__).with_name('godot_smoke.gd'),TARGET/'check.gd')
(TARGET/'project.godot').write_text('[application]\nconfig/name="Depths local Blender kit smoke"\n[rendering]\nrenderer/rendering_method="mobile"\nrenderer/rendering_method.mobile="mobile"\nrendering_device/driver.windows="d3d12"\n',encoding='utf-8')
manifest=json.loads((OUT/'kit-manifest.json').read_text());summary={}
for record in manifest['fits']:
    fit=record['fit_id'].split('-')[0];summary[fit]={'bones':len(next(o for o in record['objects'] if o['type']=='ARMATURE')['bones']),'triangles':sum(o.get('triangles',0) for o in record['objects'])}
(TARGET/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
print('Local Godot smoke project ready')
