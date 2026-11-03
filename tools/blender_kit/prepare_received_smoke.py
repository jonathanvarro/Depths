"""Isolated Godot import/skin checks for the uploaded-motion candidates."""
from pathlib import Path
import json,struct,shutil
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/local-blender-kit-v1/animation-requests-v1/received-v1/candidates-v1';TARGET=OUT/'godot-smoke'
def main(fits=('female','male'),motions=5,capture_clip_contains='idle'):
    TARGET.mkdir(exist_ok=True);summary={}
    for fit in fits:
        source=OUT/'exports'/(fit+'_kit.glb');raw=source.read_bytes();length=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+length]);shutil.copy2(source,TARGET/source.name)
        summary[fit]={'bones':65 if fit=='female' else 49,'triangles':sum(doc['accessors'][p['indices']]['count']//3 for m in doc['meshes'] for p in m['primitives']),'meshes':len(doc['meshes']),'motions':motions,'capture_clip_contains':capture_clip_contains}
    shutil.copy2(Path(__file__).with_name('garment_godot_check.gd'),TARGET/'check.gd')
    (TARGET/'summary.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
    (TARGET/'project.godot').write_text('[application]\nconfig/name="Depths uploaded-motion smoke"\n[rendering]\nrenderer/rendering_method="mobile"\nrenderer/rendering_method.mobile="mobile"\nrendering_device/driver.windows="d3d12"\n',encoding='utf-8')
    print('RECEIVED_GODOT_PROJECT',summary)
if __name__=='__main__':main()
